import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:gonggoo_app/features/auth/repositories/auth_repository.dart';
import 'package:gonggoo_app/core/utils/secure_storage.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

void main() {
  group('Phone Auth Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late AuthRepository authRepository;

    setUpAll(() async {
      // Flutter 테스트 환경 초기화
      TestWidgetsFlutterBinding.ensureInitialized();

      // Flutter 테스트 환경에서 디버그 모드 설정
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      // FlutterSecureStorage Mock 채널 설정
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        // Mock implementation - 실제 구현은 fallback storage가 처리
        return null;
      });
    });

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();

      authRepository = AuthRepository(
        firebaseAuth: mockAuth,
        firestore: mockFirestore,
      );
    });

    tearDown(() {
      // SecureStorage 초기화
      SecureStorage.deleteAllTokens();
    });

    testWidgets('1. 회원가입 후 사용자 정보 표시 테스트', (WidgetTester tester) async {
      // Given: Mock 설정
      const String testUid = 'test_uid_123';
      const String testName = '테스트 사용자';
      const String testPhone = '+821012345678';

      when(mockUser.uid).thenReturn(testUid);
      when(mockUser.displayName).thenReturn(testName);
      when(mockUser.phoneNumber).thenReturn(testPhone);
      when(mockAuth.currentUser).thenReturn(mockUser);

      // Mock Firestore 설정
      final mockDocRef = MockDocumentReference();
      final mockDocSnapshot = MockDocumentSnapshot();
      final mockCollection = MockCollectionReference();

      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc(testUid)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.data()).thenReturn({
        'uid': testUid,
        'name': testName,
        'phoneNumber': testPhone,
        'roadNameAddress': '서울시 강남구',
        'locationAddress': '테헤란로',
        'locationTag': '강남역',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // When: Phone Auth 사용자로 설정
      await SecureStorage.setPhoneAuthUser(true);
      await SecureStorage.savePhoneAuthSession();
      await SecureStorage.saveRememberMe(true);

      // Then: 인증 상태 확인
      final isPhoneAuth = await SecureStorage.isPhoneAuthUser();
      final isSessionValid = await SecureStorage.isPhoneAuthSessionValid();
      final isAuthValid = await SecureStorage.isAuthValid();

      expect(isPhoneAuth, true, reason: 'Phone Auth 사용자로 설정되어야 함');
      expect(isSessionValid, true, reason: 'Phone Auth 세션이 유효해야 함');
      expect(isAuthValid, true, reason: '전체 인증이 유효해야 함');

      // 사용자 정보 조회 테스트
      final userModel = await authRepository.getUserModelFromFirestore(testUid);
      expect(userModel, isNotNull, reason: 'Firestore에서 사용자 정보를 조회할 수 있어야 함');
      expect(userModel!.name, testName, reason: '사용자 이름이 일치해야 함');
      expect(userModel.phoneNumber, testPhone, reason: '전화번호가 일치해야 함');
    });

    testWidgets('2. 앱 재시작 후 자동 로그인 테스트', (WidgetTester tester) async {
      // Given: Phone Auth 사용자 설정
      await SecureStorage.setPhoneAuthUser(true);
      await SecureStorage.savePhoneAuthSession();
      await SecureStorage.saveRememberMe(true);

      // 앱 재시작 시뮬레이션 (새로운 인스턴스 생성)
      final newAuthRepository = AuthRepository(
        firebaseAuth: mockAuth,
        firestore: mockFirestore,
      );

      // When: 인증 상태 확인
      final isAuthValid = await SecureStorage.isAuthValid();
      final rememberMe = await SecureStorage.getRememberMe();

      // Then: 자동 로그인 가능 상태 확인
      expect(rememberMe, true, reason: 'Remember Me가 활성화되어 있어야 함');
      expect(isAuthValid, true, reason: '인증이 유효해야 함');
    });

    testWidgets('3. 로그아웃 후 재로그인 테스트', (WidgetTester tester) async {
      // Given: 로그인 상태
      await SecureStorage.setPhoneAuthUser(true);
      await SecureStorage.savePhoneAuthSession();
      await SecureStorage.saveRememberMe(true);

      // When: 로그아웃
      await authRepository.signOut();

      // Then: 로그아웃 상태 확인
      final isAuthValidAfterLogout = await SecureStorage.isAuthValid();
      expect(isAuthValidAfterLogout, false, reason: '로그아웃 후 인증이 무효해야 함');

      // When: 재로그인
      await SecureStorage.setPhoneAuthUser(true);
      await SecureStorage.savePhoneAuthSession();
      await SecureStorage.saveRememberMe(true);

      // Then: 재로그인 상태 확인
      final isAuthValidAfterRelogin = await SecureStorage.isAuthValid();
      expect(isAuthValidAfterRelogin, true, reason: '재로그인 후 인증이 유효해야 함');
    });

    test('4. Phone Auth 세션 만료 테스트', () async {
      // Given: Phone Auth 사용자 설정
      await SecureStorage.setPhoneAuthUser(true);
      await SecureStorage.saveRememberMe(true);

      // 만료된 세션 시뮬레이션
      await SecureStorage.setExpiredPhoneAuthSession();

      // When: 세션 유효성 확인
      final isSessionValid = await SecureStorage.isPhoneAuthSessionValid();
      final isAuthValid = await SecureStorage.isAuthValid();

      // Then: 만료된 세션으로 인해 인증 무효
      expect(isSessionValid, false, reason: '25시간 경과한 세션은 무효해야 함');
      expect(isAuthValid, false, reason: '만료된 세션으로 인해 전체 인증이 무효해야 함');
    });

    test('5. 회원가입 직후 5분 예외 처리 테스트', () async {
      // Given: 신규 사용자 (생성 시간이 3분 전)
      const String testUid = 'new_user_123';
      final recentCreatedAt =
          DateTime.now().subtract(const Duration(minutes: 3));

      final mockDocRef = MockDocumentReference();
      final mockDocSnapshot = MockDocumentSnapshot();
      final mockCollection = MockCollectionReference();

      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc(testUid)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.data()).thenReturn({
        'uid': testUid,
        'name': '신규 사용자',
        'phoneNumber': '+821087654321',
        'roadNameAddress': null,
        'locationAddress': null,
        'locationTag': null,
        'createdAt': Timestamp.fromDate(recentCreatedAt),
        'updatedAt': Timestamp.fromDate(recentCreatedAt),
      });

      // Mock User 설정
      when(mockUser.uid).thenReturn(testUid);
      when(mockAuth.currentUser).thenReturn(mockUser);

      // Phone Auth 설정하되 세션은 만료시킴
      await SecureStorage.setPhoneAuthUser(true);
      await SecureStorage.saveRememberMe(true);
      await SecureStorage.setExpiredPhoneAuthSession();

      // When: 사용자 정보 조회 (auth_state.dart의 build() 메서드 로직 시뮬레이션)
      final userModel = await authRepository.getUserModelFromFirestore(testUid);
      bool shouldAllowAccess = false;

      if (userModel != null) {
        final now = DateTime.now();
        final timeDiff = now.difference(userModel.createdAt);
        if (timeDiff.inMinutes <= 5) {
          shouldAllowAccess = true;
          // 새로운 세션 생성
          await SecureStorage.savePhoneAuthSession();
        }
      }

      // Then: 회원가입 직후 5분 이내이므로 접근 허용
      expect(shouldAllowAccess, true,
          reason: '회원가입 직후 5분 이내는 세션 만료되어도 접근 허용해야 함');

      // 새로운 세션이 생성되었는지 확인
      final newSessionValid = await SecureStorage.isPhoneAuthSessionValid();
      expect(newSessionValid, true, reason: '새로운 세션이 생성되어야 함');
    });
  });
}
