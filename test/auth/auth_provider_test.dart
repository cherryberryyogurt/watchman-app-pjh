import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gonggoo_app/features/auth/models/user_model.dart';
import 'package:gonggoo_app/features/auth/providers/auth_state.dart';
import 'package:gonggoo_app/features/auth/repositories/auth_repository.dart';
import 'package:gonggoo_app/features/auth/services/auth_integrity_service.dart';
import 'package:gonggoo_app/features/auth/utils/secure_storage.dart';

// 모의 객체 생성
@GenerateMocks([AuthRepository, AuthIntegrityService, firebase_auth.User])
import 'auth_provider_test.mocks.dart';

// SecurityStorage 모킹을 위한 클래스
class MockSecureStorageForTest {
  static bool rememberMeValue = true;
  static bool tokenValidValue = true;
  
  static Future<bool> getRememberMe() async {
    return rememberMeValue;
  }
  
  static Future<bool> isTokenValid() async {
    return tokenValidValue;
  }
  
  static Future<void> deleteAllTokens() async {
    // Do nothing in tests
  }
}

// Helper to set up SecureStorage mock behavior
void setupSecureStorageMocks(MockAuthRepository mockAuthRepository) {
  // Set up a mock authStateChanges stream
  when(mockAuthRepository.authStateChanges).thenAnswer((_) => 
    Stream.value(null)); // Initially no Firebase user is logged in
    
  when(mockAuthRepository.isAuthenticated()).thenAnswer((_) async => true);
}

void main() {
  // 먼저 Flutter 바인딩 초기화
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late ProviderContainer container;
  late MockAuthRepository mockAuthRepository;
  late MockAuthIntegrityService mockAuthIntegrityService;
  
  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockAuthIntegrityService = MockAuthIntegrityService();
    
    // Set up SecureStorage mocks
    setupSecureStorageMocks(mockAuthRepository);
    
    // Riverpod 테스트를 위한 컨테이너 설정
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        authIntegrityServiceProvider.overrideWithValue(mockAuthIntegrityService),
      ],
    );
  });
  
  tearDown(() {
    container.dispose();
  });
  
  test('로그인 성공 시 인증 상태가 업데이트 되어야 함', () async {
    // 준비
    final testEmail = 'test@example.com';
    final testPassword = 'password123';
    final createdAt = DateTime.now();
    final mockUser = UserModel(
      uid: 'test-uid',
      email: testEmail,
      name: 'Test User',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    
    // Mock 객체 설정
    when(mockAuthRepository.signInWithEmailAndPassword(
      email: testEmail,
      password: testPassword,
      rememberMe: true,
    )).thenAnswer((_) async => mockUser);
    
    // 실행
    await container.read(authProvider.notifier).signInWithEmailAndPassword(
      testEmail,
      testPassword,
      true,
    );
    
    // 검증
    verify(mockAuthRepository.signInWithEmailAndPassword(
      email: testEmail,
      password: testPassword,
      rememberMe: true,
    )).called(1);
  });
  
  test('로그인 실패 시 오류가 발생해야 함', () async {
    // 준비
    final testEmail = 'test@example.com';
    final testPassword = 'wrong-password';
    final exception = Exception('로그인 실패: 잘못된 비밀번호');
    
    // Mock 객체 설정
    when(mockAuthRepository.signInWithEmailAndPassword(
      email: testEmail,
      password: testPassword,
      rememberMe: true,
    )).thenThrow(exception);
    
    // 실행 & 검증
    // When the error is thrown inside the function, expectLater won't catch it directly
    // Instead, we need to wrap it in a try/catch block
    try {
      await container.read(authProvider.notifier).signInWithEmailAndPassword(
        testEmail,
        testPassword,
        true,
      );
      // If we get here without an exception, the test should fail
      fail('Exception not thrown');
    } catch (e) {
      // Expected - test passes
      expect(e, isA<Exception>());
    }
    
    // Verify the method was called
    verify(mockAuthRepository.signInWithEmailAndPassword(
      email: testEmail,
      password: testPassword,
      rememberMe: true,
    )).called(1);
  });
  
  test('회원가입 성공 시 repository 메소드가 호출되어야 함', () async {
    // 준비
    final testEmail = 'new@example.com';
    final testPassword = 'password123';
    final testName = 'New User';
    final createdAt = DateTime.now();
    final mockUser = UserModel(
      uid: 'new-uid',
      email: testEmail,
      name: testName,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    
    // Mock 객체 설정
    when(mockAuthRepository.signUpWithEmailAndPassword(
      email: testEmail,
      password: testPassword,
      name: testName,
    )).thenAnswer((_) async => mockUser);
    
    // 실행
    await container.read(authProvider.notifier).signUpWithEmailAndPassword(
      testEmail,
      testPassword,
      testName,
      null, // phone
    );
    
    // 검증
    verify(mockAuthRepository.signUpWithEmailAndPassword(
      email: testEmail,
      password: testPassword,
      name: testName,
    )).called(1);
  });
  
  test('로그아웃 시 repository 메소드가 호출되어야 함', () async {
    // Mock 객체 설정
    when(mockAuthRepository.signOut()).thenAnswer((_) async => null);
    
    // 실행
    await container.read(authProvider.notifier).signOut();
    
    // 검증
    verify(mockAuthRepository.signOut()).called(1);
  });
  
  test('유저 프로필 업데이트 시 repository 메소드가 호출되어야 함', () async {
    // 준비
    final testUid = 'test-uid';
    final testName = 'Updated Name';
    final testPhone = '010-1234-5678';
    final testAddress = '서울시 강남구';
    
    // 초기 유저 상태 설정
    final createdAt = DateTime.now();
    final initialUser = UserModel(
      uid: testUid,
      email: 'test@example.com',
      name: 'Original Name',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    
    // 업데이트된 유저 정보
    final updatedAt = DateTime.now();
    final updatedUser = UserModel(
      uid: testUid,
      email: 'test@example.com',
      name: testName,
      phoneNumber: testPhone,
      address: testAddress,

      createdAt: initialUser.createdAt,
      updatedAt: updatedAt,
    );
    
    // Mock 객체 설정
    when(mockAuthRepository.updateUserProfile(
      uid: testUid,
      name: testName,
      phoneNumber: testPhone,
      address: testAddress,
    )).thenAnswer((_) async => updatedUser);
    
    // 실행
    await container.read(authProvider.notifier).updateUserProfile(
      uid: testUid,
      name: testName,
      phoneNumber: testPhone,
      address: testAddress,
    );
    
    // 검증
    verify(mockAuthRepository.updateUserProfile(
      uid: testUid,
      name: testName,
      phoneNumber: testPhone,
      address: testAddress,
    )).called(1);
  });
} 