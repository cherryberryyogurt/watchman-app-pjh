import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firebase_service.dart';

// =============================================================================
// Firebase Service Provider
// =============================================================================

/// Firebase Service Provider
///
/// 모든 Firebase 인스턴스를 중앙에서 관리하는 서비스
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});

// =============================================================================
// 개별 Firebase 인스턴스 Provider들
// =============================================================================

/// Firestore Provider
///
/// FirebaseFirestore 인스턴스를 제공합니다.
/// Repository들에서 직접 주입받아 사용할 수 있습니다.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.firestore;
});

/// Firebase Auth Provider
///
/// FirebaseAuth 인스턴스를 제공합니다.
/// 인증 관련 서비스에서 사용합니다.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.auth;
});

/// Firebase Storage Provider
///
/// FirebaseStorage 인스턴스를 제공합니다.
/// 파일 업로드/다운로드 서비스에서 사용합니다.
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.storage;
});

// =============================================================================
// 인증 상태 Provider들
// =============================================================================

/// 현재 사용자 Provider
///
/// 현재 로그인된 사용자 정보를 제공합니다.
final currentUserProvider = StreamProvider<User?>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.authStateChanges;
});

/// 인증 상태 Provider
///
/// 사용자의 로그인 상태를 boolean으로 제공합니다.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.isAuthenticated;
});

/// 현재 사용자 UID Provider
///
/// 현재 로그인된 사용자의 UID를 제공합니다.
final currentUserIdProvider = Provider<String?>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.currentUserId;
});

// =============================================================================
// 유틸리티 Provider들
// =============================================================================

/// 서버 타임스탬프 Provider
///
/// Firestore 서버 타임스탬프를 제공합니다.
final serverTimestampProvider = Provider<FieldValue>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.serverTimestamp;
});

/// 현재 시간 Timestamp Provider
///
/// 현재 시간을 Firestore Timestamp로 제공합니다.
final currentTimestampProvider = Provider<Timestamp>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.now;
});

// =============================================================================
// Firebase 연결 상태 Provider
// =============================================================================

/// Firebase 연결 상태 Provider
///
/// Firestore 연결 상태를 확인합니다.
final firebaseConnectionProvider = FutureProvider<bool>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.checkFirestoreConnection();
});

// =============================================================================
// 헬퍼 Provider들
// =============================================================================

/// Firebase 에러 메시지 변환 Provider
///
/// Firebase 에러를 사용자 친화적 메시지로 변환하는 함수를 제공합니다.
final firebaseErrorHandlerProvider = Provider<String Function(dynamic)>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getErrorMessage;
});

/// Firebase 배치 쓰기 Provider
///
/// Firestore 배치 쓰기 인스턴스를 제공합니다.
final firestoreBatchProvider = Provider<WriteBatch>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.batch();
});

// =============================================================================
// 컬렉션 참조 Provider들 (자주 사용되는 컬렉션들)
// =============================================================================

/// Users 컬렉션 Provider
final usersCollectionProvider = Provider<CollectionReference>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('users');
});

/// Products 컬렉션 Provider
final productsCollectionProvider = Provider<CollectionReference>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('products');
});

/// Orders 컬렉션 Provider
final ordersCollectionProvider = Provider<CollectionReference>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('orders');
});

/// Location Tags 컬렉션 Provider
final locationTagsCollectionProvider = Provider<CollectionReference>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('location_tags');
});

/// Cart Items 컬렉션 Provider
final cartItemsCollectionProvider = Provider<CollectionReference>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('cart_items');
});

// =============================================================================
// 개발/디버깅용 Provider들
// =============================================================================

/// Firebase 서비스 상태 로깅 Provider
///
/// 개발 환경에서 Firebase 서비스 상태를 로깅합니다.
final firebaseStatusLoggerProvider = Provider<void>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  firebaseService.logServiceStatus();
});

/// Firebase 초기화 Provider
///
/// Firebase 서비스를 초기화하고 설정합니다.
final firebaseInitializerProvider = Provider<void>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);

  // Firestore 설정
  firebaseService.configureFirestore(
    persistenceEnabled: true,
    sslEnabled: true,
  );

  // 상태 로깅 (개발 환경에서만)
  firebaseService.logServiceStatus();
});
