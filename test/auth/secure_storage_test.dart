import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gonggoo_app/core/utils/secure_storage.dart';

void main() {
  group('SecureStorage Tests', () {
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

    tearDown(() async {
      // 각 테스트 후 SecureStorage 초기화
      await SecureStorage.deleteAllTokens();
    });

    group('Phone Auth 세션 유효성 검사', () {
      test('새로운 Phone Auth 세션은 유효해야 함', () async {
        // Given: Phone Auth 사용자 설정
        await SecureStorage.setPhoneAuthUser(true);
        await SecureStorage.savePhoneAuthSession();

        // When: 세션 유효성 확인
        final isSessionValid = await SecureStorage.isPhoneAuthSessionValid();

        // Then: 유효해야 함
        expect(isSessionValid, true, reason: '새로 생성된 세션은 유효해야 함');
      });

      test('만료된 Phone Auth 세션은 무효해야 함', () async {
        // Given: Phone Auth 사용자 설정 후 세션 만료
        await SecureStorage.setPhoneAuthUser(true);
        await SecureStorage.setExpiredPhoneAuthSession();

        // When: 세션 유효성 확인
        final isSessionValid = await SecureStorage.isPhoneAuthSessionValid();

        // Then: 무효해야 함
        expect(isSessionValid, false, reason: '만료된 세션은 무효해야 함');
      });

      test('Phone Auth 세션이 없으면 무효해야 함', () async {
        // Given: Phone Auth 사용자 설정했지만 세션 저장 안함
        await SecureStorage.setPhoneAuthUser(true);

        // When: 세션 유효성 확인
        final isSessionValid = await SecureStorage.isPhoneAuthSessionValid();

        // Then: 무효해야 함
        expect(isSessionValid, false, reason: '세션이 없으면 무효해야 함');
      });
    });

    group('RememberMe 플래그 동작 확인', () {
      test('RememberMe가 false이면 인증이 무효해야 함', () async {
        // Given: Phone Auth 사용자, 유효한 세션, 하지만 RememberMe false
        await SecureStorage.setPhoneAuthUser(true);
        await SecureStorage.savePhoneAuthSession();
        await SecureStorage.saveRememberMe(false);

        // When: 전체 인증 상태 확인
        final isAuthValid = await SecureStorage.isAuthValid();

        // Then: 무효해야 함
        expect(isAuthValid, false, reason: 'RememberMe가 false이면 인증 무효해야 함');
      });

      test('RememberMe가 true이고 세션이 유효하면 인증 유효해야 함', () async {
        // Given: Phone Auth 사용자, 유효한 세션, RememberMe true
        await SecureStorage.setPhoneAuthUser(true);
        await SecureStorage.savePhoneAuthSession();
        await SecureStorage.saveRememberMe(true);

        // When: 전체 인증 상태 확인
        final isAuthValid = await SecureStorage.isAuthValid();

        // Then: 유효해야 함
        expect(isAuthValid, true,
            reason: 'RememberMe true + 유효한 세션 = 인증 유효해야 함');
      });

      test('RememberMe가 true이지만 세션이 만료되면 인증 무효해야 함', () async {
        // Given: Phone Auth 사용자, 만료된 세션, RememberMe true
        await SecureStorage.setPhoneAuthUser(true);
        await SecureStorage.setExpiredPhoneAuthSession();
        await SecureStorage.saveRememberMe(true);

        // When: 전체 인증 상태 확인
        final isAuthValid = await SecureStorage.isAuthValid();

        // Then: 무효해야 함
        expect(isAuthValid, false,
            reason: '세션이 만료되면 RememberMe true여도 인증 무효해야 함');
      });
    });

    group('Phone Auth vs Email 사용자 구분', () {
      test('Phone Auth 사용자는 세션 기반 검증을 사용해야 함', () async {
        // Given: Phone Auth 사용자
        await SecureStorage.setPhoneAuthUser(true);
        await SecureStorage.savePhoneAuthSession();
        await SecureStorage.saveRememberMe(true);

        // When: 인증 유형 확인
        final isPhoneAuth = await SecureStorage.isPhoneAuthUser();
        final isAuthValid = await SecureStorage.isAuthValid();

        // Then
        expect(isPhoneAuth, true, reason: 'Phone Auth 사용자로 설정되어야 함');
        expect(isAuthValid, true, reason: 'Phone Auth 세션 기반 검증이 유효해야 함');
      });

      test('Email 사용자는 토큰 기반 검증을 사용해야 함', () async {
        // Given: Email 사용자 (Phone Auth false)
        await SecureStorage.setPhoneAuthUser(false);
        await SecureStorage.saveRememberMe(true);
        // 토큰 설정 안함 (만료된 상태)

        // When: 인증 유형 확인
        final isPhoneAuth = await SecureStorage.isPhoneAuthUser();
        final isAuthValid = await SecureStorage.isAuthValid();

        // Then
        expect(isPhoneAuth, false, reason: 'Email 사용자로 설정되어야 함');
        expect(isAuthValid, false, reason: '토큰이 없으므로 인증 무효해야 함');
      });

      test('사용자 유형이 설정되지 않으면 Email 사용자로 간주해야 함', () async {
        // Given: 사용자 유형 설정 안함
        await SecureStorage.saveRememberMe(true);

        // When: 인증 유형 확인
        final isPhoneAuth = await SecureStorage.isPhoneAuthUser();

        // Then
        expect(isPhoneAuth, false,
            reason: '설정되지 않으면 기본값으로 Email 사용자 (false)여야 함');
      });
    });

    group('로그아웃 시 데이터 정리', () {
      test('로그아웃 시 모든 Phone Auth 관련 데이터가 삭제되어야 함', () async {
        // Given: Phone Auth 사용자 완전 설정
        await SecureStorage.setPhoneAuthUser(true);
        await SecureStorage.savePhoneAuthSession();
        await SecureStorage.saveRememberMe(true);
        await SecureStorage.saveAccessToken('test_token');
        await SecureStorage.saveUserId('test_user_id');

        // 설정 전 상태 확인
        expect(await SecureStorage.isPhoneAuthUser(), true);
        expect(await SecureStorage.isPhoneAuthSessionValid(), true);
        expect(await SecureStorage.getAccessToken(), 'test_token');
        expect(await SecureStorage.getUserId(), 'test_user_id');

        // When: 로그아웃
        await SecureStorage.deleteAllTokens();

        // Then: 모든 데이터 삭제 확인
        expect(await SecureStorage.isPhoneAuthUser(), false,
            reason: 'Phone Auth 플래그가 삭제되어야 함');
        expect(await SecureStorage.isPhoneAuthSessionValid(), false,
            reason: 'Phone Auth 세션이 삭제되어야 함');
        expect(await SecureStorage.getAccessToken(), null,
            reason: 'Access Token이 삭제되어야 함');
        expect(await SecureStorage.getUserId(), null,
            reason: 'User ID가 삭제되어야 함');

        // Remember Me는 유지되어야 함 (명시적으로 삭제하지 않는 한)
        expect(await SecureStorage.getRememberMe(), true,
            reason: 'Remember Me는 로그아웃 시에도 유지되어야 함');
      });
    });

    group('hasValidTokens 통합 테스트', () {
      test('Phone Auth 사용자의 유효한 토큰 확인', () async {
        // Given: Phone Auth 사용자 완전 설정
        await SecureStorage.setPhoneAuthUser(true);
        await SecureStorage.savePhoneAuthSession();
        await SecureStorage.saveRememberMe(true);
        await SecureStorage.saveAccessToken('valid_token');

        // When: 토큰 유효성 확인
        final hasValidTokens = await SecureStorage.hasValidTokens();

        // Then: 유효해야 함
        expect(hasValidTokens, true,
            reason: 'Phone Auth 사용자의 유효한 설정은 true여야 함');
      });

      test('토큰은 있지만 RememberMe가 false인 경우', () async {
        // Given: 토큰은 있지만 RememberMe false
        await SecureStorage.setPhoneAuthUser(true);
        await SecureStorage.savePhoneAuthSession();
        await SecureStorage.saveRememberMe(false);
        await SecureStorage.saveAccessToken('valid_token');

        // When: 토큰 유효성 확인
        final hasValidTokens = await SecureStorage.hasValidTokens();

        // Then: 무효해야 함
        expect(hasValidTokens, false, reason: 'RememberMe가 false이면 무효해야 함');
      });

      test('토큰이 없는 경우', () async {
        // Given: 토큰 없음
        await SecureStorage.setPhoneAuthUser(true);
        await SecureStorage.savePhoneAuthSession();
        await SecureStorage.saveRememberMe(true);
        // 토큰 설정 안함

        // When: 토큰 유효성 확인
        final hasValidTokens = await SecureStorage.hasValidTokens();

        // Then: 무효해야 함
        expect(hasValidTokens, false, reason: '토큰이 없으면 무효해야 함');
      });
    });
  });
}
