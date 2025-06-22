import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// 🔥 Firebase 서비스 의존성 주입 관리
///
/// 모든 Firebase 인스턴스를 중앙에서 관리하고 의존성 주입을 지원합니다.
/// 테스트 환경에서 모킹하기 쉽도록 설계되었습니다.
class FirebaseService {
  static FirebaseService? _instance;

  // Firebase 인스턴스들
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  FirebaseService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// 싱글톤 인스턴스 접근
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  /// 테스트용 인스턴스 설정 (모킹 지원)
  static void setTestInstance({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) {
    _instance = FirebaseService._(
      firestore: firestore,
      auth: auth,
      storage: storage,
    );
  }

  /// 인스턴스 초기화 (테스트 후 정리용)
  static void resetInstance() {
    _instance = null;
  }

  // =============================================================================
  // Firestore 관련
  // =============================================================================

  /// Firestore 인스턴스 접근
  FirebaseFirestore get firestore => _firestore;

  /// 컬렉션 참조 가져오기
  CollectionReference collection(String path) => _firestore.collection(path);

  /// 문서 참조 가져오기
  DocumentReference doc(String path) => _firestore.doc(path);

  /// 배치 쓰기 생성
  WriteBatch batch() => _firestore.batch();

  /// 트랜잭션 실행
  Future<T> runTransaction<T>(
    TransactionHandler<T> updateFunction, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    return _firestore.runTransaction(updateFunction, timeout: timeout);
  }

  /// Firestore 설정 (앱 초기화 시 호출)
  void configureFirestore({
    bool persistenceEnabled = true,
    bool sslEnabled = true,
    Settings? customSettings,
  }) {
    if (customSettings != null) {
      _firestore.settings = customSettings;
    } else {
      _firestore.settings = Settings(
        persistenceEnabled: persistenceEnabled,
        sslEnabled: sslEnabled,
      );
    }

    if (kDebugMode) {
      debugPrint('🔥 FirebaseService: Firestore 설정 완료');
    }
  }

  // =============================================================================
  // Authentication 관련
  // =============================================================================

  /// Firebase Auth 인스턴스 접근
  FirebaseAuth get auth => _auth;

  /// 현재 사용자
  User? get currentUser => _auth.currentUser;

  /// 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 사용자 변경 스트림 (더 상세한 정보 포함)
  Stream<User?> get userChanges => _auth.userChanges();

  // =============================================================================
  // Storage 관련
  // =============================================================================

  /// Firebase Storage 인스턴스 접근
  FirebaseStorage get storage => _storage;

  /// Storage 참조 가져오기
  Reference storageRef([String? path]) {
    return path != null ? _storage.ref(path) : _storage.ref();
  }

  // =============================================================================
  // 유틸리티 메서드들
  // =============================================================================

  /// 서버 타임스탬프 생성
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// 배열 요소 추가
  FieldValue arrayUnion(List<Object?> elements) =>
      FieldValue.arrayUnion(elements);

  /// 배열 요소 제거
  FieldValue arrayRemove(List<Object?> elements) =>
      FieldValue.arrayRemove(elements);

  /// 숫자 증가
  FieldValue increment(num value) => FieldValue.increment(value);

  /// 필드 삭제
  FieldValue get delete => FieldValue.delete();

  /// GeoPoint 생성
  GeoPoint geoPoint(double latitude, double longitude) {
    return GeoPoint(latitude, longitude);
  }

  /// Timestamp 생성
  Timestamp timestamp(DateTime dateTime) => Timestamp.fromDate(dateTime);

  /// 현재 시간 Timestamp
  Timestamp get now => Timestamp.now();

  // =============================================================================
  // 헬스 체크 및 디버깅
  // =============================================================================

  /// Firebase 연결 상태 확인
  Future<bool> checkFirestoreConnection() async {
    try {
      await _firestore.doc('health_check/test').get();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔥 FirebaseService: Firestore 연결 실패: $e');
      }
      return false;
    }
  }

  /// 인증 상태 확인
  bool get isAuthenticated => _auth.currentUser != null;

  /// 현재 사용자 UID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Firebase 서비스 상태 로깅
  void logServiceStatus() {
    if (kDebugMode) {
      debugPrint('🔥 FirebaseService Status:');
      debugPrint('  - Firestore: ${_firestore.app.name}');
      debugPrint('  - Auth: ${_auth.app.name}');
      debugPrint('  - Storage: ${_storage.app.name}');
      debugPrint('  - Current User: ${currentUser?.uid ?? 'None'}');
    }
  }

  // =============================================================================
  // 에러 핸들링 헬퍼
  // =============================================================================

  /// Firebase 에러를 사용자 친화적 메시지로 변환
  String getErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return '접근 권한이 없습니다.';
        case 'not-found':
          return '요청한 데이터를 찾을 수 없습니다.';
        case 'already-exists':
          return '이미 존재하는 데이터입니다.';
        case 'resource-exhausted':
          return '요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요.';
        case 'unauthenticated':
          return '로그인이 필요합니다.';
        case 'unavailable':
          return '서비스를 일시적으로 사용할 수 없습니다.';
        case 'deadline-exceeded':
          return '요청 시간이 초과되었습니다.';
        default:
          return '오류가 발생했습니다: ${error.message}';
      }
    }
    return '알 수 없는 오류가 발생했습니다.';
  }

  /// Firebase 에러인지 확인
  bool isFirebaseError(dynamic error) {
    return error is FirebaseException;
  }

  /// 네트워크 에러인지 확인
  bool isNetworkError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
          error.code == 'deadline-exceeded' ||
          error.message?.contains('network') == true;
    }
    return false;
  }
}
