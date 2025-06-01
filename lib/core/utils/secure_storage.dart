import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:convert';

class SecureStorage {
  // Private constructor to prevent instantiation
  SecureStorage._();

  // Create storage with platform-specific options
  static final FlutterSecureStorage _storage = _createStorage();

  static FlutterSecureStorage _createStorage() {
    // Platform-specific storage options
    if (Platform.isAndroid) {
      return const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          sharedPreferencesName: 'gonggoo_secure_prefs',
          preferencesKeyPrefix: 'gonggoo_',
        ),
      );
    } else if (Platform.isIOS) {
      return const FlutterSecureStorage(
        iOptions: IOSOptions(
          accountName: 'gonggoo_app_secure_storage',
        ),
      );
    } else {
      // Default options for other platforms
      return const FlutterSecureStorage();
    }
  }

  // Keys
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _rememberMeKey = 'remember_me';
  static const _tokenExpiryKey = 'token_expiry';

  // 🔐 Phone Auth 전용 키들 추가
  static const String _isPhoneAuthKey = 'is_phone_auth';
  static const String _phoneAuthSessionKey = 'phone_auth_session';
  static const String _phoneAuthTimestampKey = 'phone_auth_timestamp';

  // Save access token
  static Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      if (kDebugMode) {
        print('🔐 SecureStorage: saveAccessToken - 성공');
      }

      // 테스트 환경에서의 호환성을 위해 fallback storage에도 저장
      await _saveFallback(_accessTokenKey, token);
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: saveAccessToken - 실패: $e');
      }
      _saveFallback(_accessTokenKey, token);
    }
  }

  // Read access token
  static Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (kDebugMode) {
        print(
            '🔐 SecureStorage: getAccessToken - ${token != null ? "존재함" : "없음"}');
      }
      return token ?? await _readFallback(_accessTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: getAccessToken - 에러: $e');
      }
      return await _readFallback(_accessTokenKey);
    }
  }

  // Save refresh token
  static Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      if (kDebugMode) {
        print('🔐 SecureStorage: saveRefreshToken - 성공');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: saveRefreshToken - 실패: $e');
      }
      _saveFallback(_refreshTokenKey, token);
    }
  }

  // Read refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      if (kDebugMode) {
        print(
            '🔐 SecureStorage: getRefreshToken - ${token != null ? "존재함" : "없음"}');
      }
      return token ?? await _readFallback(_refreshTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: getRefreshToken - 에러: $e');
      }
      return await _readFallback(_refreshTokenKey);
    }
  }

  // Save user ID
  static Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
      if (kDebugMode) {
        print('🔐 SecureStorage: saveUserId - 성공: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: saveUserId - 실패: $e');
      }
      _saveFallback(_userIdKey, userId);
    }
  }

  // Read user ID
  static Future<String?> getUserId() async {
    try {
      final userId = await _storage.read(key: _userIdKey);
      if (kDebugMode) {
        print(
            '🔐 SecureStorage: getUserId - ${userId != null ? "존재함: $userId" : "없음"}');
      }
      return userId ?? await _readFallback(_userIdKey);
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: getUserId - 에러: $e');
      }
      return await _readFallback(_userIdKey);
    }
  }

  // Save token expiry time
  static Future<void> saveTokenExpiryTime(DateTime expiryTime) async {
    try {
      final expiryTimeString = expiryTime.toIso8601String();
      await _storage.write(key: _tokenExpiryKey, value: expiryTimeString);
      if (kDebugMode) {
        print('🔐 SecureStorage: saveTokenExpiryTime - 성공: $expiryTimeString');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: saveTokenExpiryTime - 실패: $e');
      }
      _saveFallback(_tokenExpiryKey, expiryTime.toIso8601String());
    }
  }

  // Read token expiry time
  static Future<DateTime?> getTokenExpiryTime() async {
    try {
      final expiryTimeString = await _storage.read(key: _tokenExpiryKey);
      if (expiryTimeString == null) {
        if (kDebugMode) {
          print('🔐 SecureStorage: getTokenExpiryTime - 없음');
        }
        return null;
      }

      final expiryTime = DateTime.parse(expiryTimeString);
      if (kDebugMode) {
        print('🔐 SecureStorage: getTokenExpiryTime - 존재함: $expiryTimeString');
      }
      return expiryTime;
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: getTokenExpiryTime - 에러: $e');
      }

      final fallbackValue = await _readFallback(_tokenExpiryKey);
      if (fallbackValue != null) {
        try {
          return DateTime.parse(fallbackValue);
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  // Check if token is valid (not expired)
  static Future<bool> isTokenValid() async {
    try {
      final expiryTime = await getTokenExpiryTime();
      if (expiryTime == null) {
        if (kDebugMode) {
          print('🔐 SecureStorage: isTokenValid - false (만료시간 없음)');
        }
        return false; // No expiry time means token is invalid
      }

      final now = DateTime.now();
      final isValid = expiryTime.isAfter(now);
      if (kDebugMode) {
        print(
            '🔐 SecureStorage: isTokenValid - $isValid (만료시간: ${expiryTime.toIso8601String()})');
      }
      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: isTokenValid - 에러: $e');
      }
      return false; // Any error means token is invalid
    }
  }

  // Save "remember me" setting
  static Future<void> saveRememberMe(bool value) async {
    try {
      await _storage.write(key: _rememberMeKey, value: value.toString());
      if (kDebugMode) {
        print('🔐 SecureStorage: saveRememberMe - 성공: $value');
      }

      // 테스트 환경에서의 호환성을 위해 fallback storage에도 저장
      await _saveFallback(_rememberMeKey, value.toString());
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: saveRememberMe - 실패: $e');
      }
      _saveFallback(_rememberMeKey, value.toString());
    }
  }

  // Get "remember me" setting (defaults to false if not set)
  static Future<bool> getRememberMe() async {
    try {
      final value = await _storage.read(key: _rememberMeKey);
      if (value == null) {
        if (kDebugMode) {
          print('🔐 SecureStorage: getRememberMe - false (기본값)');
        }
        return false; // Default to false
      }

      final rememberMe = value.toLowerCase() == 'true';
      if (kDebugMode) {
        print('🔐 SecureStorage: getRememberMe - $rememberMe');
      }
      return rememberMe;
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: getRememberMe - 에러: $e');
      }

      final fallbackValue = await _readFallback(_rememberMeKey);
      if (fallbackValue != null) {
        return fallbackValue.toLowerCase() == 'true';
      }
      return false; // Default to false
    }
  }

  // 🔐 Phone Auth 전용 메서드들 추가

  /// Phone Auth 사용자 여부 저장
  static Future<void> setPhoneAuthUser(bool isPhoneAuth) async {
    try {
      await _storage.write(key: _isPhoneAuthKey, value: isPhoneAuth.toString());
      if (kDebugMode) {
        print('🔐 SecureStorage: setPhoneAuthUser - 성공: $isPhoneAuth');
      }

      // 테스트 환경에서의 호환성을 위해 fallback storage에도 저장
      await _saveFallback(_isPhoneAuthKey, isPhoneAuth.toString());
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: setPhoneAuthUser - 실패: $e');
      }
      _saveFallback(_isPhoneAuthKey, isPhoneAuth.toString());
    }
  }

  /// Phone Auth 사용자 여부 조회
  static Future<bool> isPhoneAuthUser() async {
    try {
      final value = await _storage.read(key: _isPhoneAuthKey);
      if (value == null) {
        if (kDebugMode) {
          print('🔐 SecureStorage: isPhoneAuthUser - false (값 없음)');
        }
        return false;
      }

      final isPhoneAuth = value.toLowerCase() == 'true';
      if (kDebugMode) {
        print('🔐 SecureStorage: isPhoneAuthUser - $isPhoneAuth');
      }
      return isPhoneAuth;
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: isPhoneAuthUser - 에러: $e');
      }

      final fallbackValue = await _readFallback(_isPhoneAuthKey);
      if (fallbackValue != null) {
        return fallbackValue.toLowerCase() == 'true';
      }
      return false;
    }
  }

  /// Phone Auth 세션 정보 저장
  static Future<void> savePhoneAuthSession() async {
    if (kDebugMode) {
      print('🔐 SecureStorage: savePhoneAuthSession - 시작');
    }

    final currentTime = DateTime.now().toIso8601String();
    final sessionData = {
      'timestamp': currentTime,
      'sessionId': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    try {
      if (kDebugMode) {
        print('🔐 SecureStorage: savePhoneAuthSession - sessionData 생성됨');
      }

      await _storage.write(
          key: _phoneAuthSessionKey, value: jsonEncode(sessionData));

      if (kDebugMode) {
        print('🔐 SecureStorage: savePhoneAuthSession - session data 저장됨');
      }

      await _storage.write(key: _phoneAuthTimestampKey, value: currentTime);

      if (kDebugMode) {
        print('🔐 SecureStorage: savePhoneAuthSession - timestamp 저장됨');
      }

      // 테스트 환경에서의 호환성을 위해 fallback storage에도 저장
      await _saveFallback(_phoneAuthSessionKey, currentTime);
      await _saveFallback(_phoneAuthTimestampKey, currentTime);

      if (kDebugMode) {
        print(
            '🔐 SecureStorage: savePhoneAuthSession - fallback storage 동기화 완료');
      }

      if (kDebugMode) {
        print('🔐 SecureStorage: savePhoneAuthSession - 성공');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: savePhoneAuthSession - 실패: $e');
      }
      // fallback storage에 저장할 때도 await 사용

      if (kDebugMode) {
        print('🔐 SecureStorage: savePhoneAuthSession - fallback 저장 시작');
      }

      await _saveFallback(_phoneAuthSessionKey, currentTime);
      await _saveFallback(_phoneAuthTimestampKey, currentTime);

      if (kDebugMode) {
        print('🔐 SecureStorage: savePhoneAuthSession - fallback 저장 완료');
      }
    }
  }

  /// Phone Auth 세션 유효성 검사 (24시간 유효)
  static Future<bool> isPhoneAuthSessionValid() async {
    try {
      if (kDebugMode) {
        print(
            '🔐 SecureStorage: isPhoneAuthSessionValid - FlutterSecureStorage read 시도');
      }

      final timestampString = await _storage.read(key: _phoneAuthTimestampKey);

      if (kDebugMode) {
        print(
            '🔐 SecureStorage: isPhoneAuthSessionValid - FlutterSecureStorage read 결과: ${timestampString != null ? "성공" : "null"}');
      }

      if (timestampString == null) {
        // Fallback storage에서 확인
        if (kDebugMode) {
          print(
              '🔐 SecureStorage: isPhoneAuthSessionValid - fallback storage 확인 시작');
        }

        final fallbackTimestampString =
            await _readFallback(_phoneAuthTimestampKey);
        if (fallbackTimestampString == null) {
          if (kDebugMode) {
            print(
                '🔐 SecureStorage: isPhoneAuthSessionValid - false (타임스탬프 없음)');
          }
          return false;
        }

        final fallbackTimestamp = DateTime.parse(fallbackTimestampString);
        final now = DateTime.now();
        final difference = now.difference(fallbackTimestamp);

        // Phone Auth 세션은 24시간 유효
        final isValid = difference.inHours < 24;

        if (kDebugMode) {
          print(
              '🔐 SecureStorage: isPhoneAuthSessionValid - $isValid (${difference.inHours}시간 경과, fallback 사용)');
        }

        return isValid;
      }

      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      // Phone Auth 세션은 24시간 유효
      final isValid = difference.inHours < 24;

      if (kDebugMode) {
        print(
            '🔐 SecureStorage: isPhoneAuthSessionValid - $isValid (${difference.inHours}시간 경과)');
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: isPhoneAuthSessionValid - 에러: $e');
      }

      // 에러 발생 시 fallback storage 시도
      try {
        if (kDebugMode) {
          print(
              '🔐 SecureStorage: isPhoneAuthSessionValid - 에러 후 fallback storage 시도');
        }

        final fallbackTimestampString =
            await _readFallback(_phoneAuthTimestampKey);
        if (fallbackTimestampString != null) {
          final fallbackTimestamp = DateTime.parse(fallbackTimestampString);
          final now = DateTime.now();
          final difference = now.difference(fallbackTimestamp);
          final isValid = difference.inHours < 24;

          if (kDebugMode) {
            print(
                '🔐 SecureStorage: isPhoneAuthSessionValid - $isValid (${difference.inHours}시간 경과, 에러 후 fallback 사용)');
          }

          return isValid;
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print(
              '🔐 SecureStorage: isPhoneAuthSessionValid - fallback 에러: $fallbackError');
        }
      }

      return false;
    }
  }

  /// Phone Auth용 토큰 유효성 검사 (기존 토큰 검사 + Phone Auth 세션 검사)
  static Future<bool> isAuthValid() async {
    try {
      final isPhoneAuth = await isPhoneAuthUser();
      final rememberMe = await getRememberMe();

      if (kDebugMode) {
        print(
            '🔐 SecureStorage: isAuthValid - Phone Auth: $isPhoneAuth, Remember Me: $rememberMe');
      }

      // rememberMe가 false면 무조건 false
      if (!rememberMe) {
        if (kDebugMode) {
          print('🔐 SecureStorage: isAuthValid - false (Remember Me 비활성화)');
        }
        return false;
      }

      if (isPhoneAuth) {
        // Phone Auth 사용자인 경우 세션 유효성만 검사
        final isSessionValid = await isPhoneAuthSessionValid();
        if (kDebugMode) {
          print(
              '🔐 SecureStorage: isAuthValid - Phone Auth 세션 유효성: $isSessionValid');
        }
        return isSessionValid;
      } else {
        // 기존 email+password 사용자인 경우 토큰 유효성 검사
        final isTokenValid = await SecureStorage.isTokenValid();
        if (kDebugMode) {
          print('🔐 SecureStorage: isAuthValid - 토큰 유효성: $isTokenValid');
        }
        return isTokenValid;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: isAuthValid - 에러: $e');
      }
      return false;
    }
  }

  // Delete all tokens (for logout)
  static Future<void> deleteAllTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _tokenExpiryKey);

      // 🔐 Phone Auth 관련 데이터도 삭제
      await _storage.delete(key: _isPhoneAuthKey);
      await _storage.delete(key: _phoneAuthSessionKey);
      await _storage.delete(key: _phoneAuthTimestampKey);
      // Keep remember me setting unless explicitly cleared

      // Also delete fallback storage
      await _deleteFallback(_accessTokenKey);
      await _deleteFallback(_refreshTokenKey);
      await _deleteFallback(_userIdKey);
      await _deleteFallback(_tokenExpiryKey);
      await _deleteFallback(_isPhoneAuthKey);
      await _deleteFallback(_phoneAuthSessionKey);
      await _deleteFallback(_phoneAuthTimestampKey);

      if (kDebugMode) {
        print('🔐 SecureStorage: deleteAllTokens - 성공 (Phone Auth 데이터 포함)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: deleteAllTokens - 에러: $e');
      }
      // Try to delete from fallback storage
      await _deleteFallback(_accessTokenKey);
      await _deleteFallback(_refreshTokenKey);
      await _deleteFallback(_userIdKey);
      await _deleteFallback(_tokenExpiryKey);
      await _deleteFallback(_isPhoneAuthKey);
      await _deleteFallback(_phoneAuthSessionKey);
      await _deleteFallback(_phoneAuthTimestampKey);
    }
  }

  // Check if tokens exist and are valid
  static Future<bool> hasValidTokens() async {
    try {
      final accessToken = await getAccessToken();
      final rememberMe = await getRememberMe();

      // 🔐 Phone Auth 사용자인지 확인하고 적절한 유효성 검사 수행
      final isValid = await isAuthValid();

      // 토큰이 있고, "로그인 상태 유지"가 true이고, 인증이 유효한 경우에만 true 반환
      final hasValidTokens = accessToken != null && rememberMe && isValid;
      if (kDebugMode) {
        print(
            '🔐 SecureStorage: hasValidTokens - $hasValidTokens (rememberMe: $rememberMe, isValid: $isValid)');
      }
      return hasValidTokens;
    } catch (e) {
      if (kDebugMode) {
        print('🔐 SecureStorage: hasValidTokens - 에러: $e');
      }
      return false;
    }
  }

  // Fallback storage methods using non-secure storage for testing/development
  // Note: In a production app, you should implement a more secure fallback
  static final Map<String, String> _fallbackStorage = {};

  static Future<void> _saveFallback(String key, String value) async {
    _fallbackStorage[key] = value;
    if (kDebugMode) {
      print('🔐 SecureStorage: _saveFallback - $key 저장됨');
    }
  }

  static Future<String?> _readFallback(String key) async {
    final value = _fallbackStorage[key];
    if (kDebugMode) {
      print(
          '🔐 SecureStorage: _readFallback - $key: ${value != null ? "존재함" : "없음"}');
    }
    return value;
  }

  static Future<void> _deleteFallback(String key) async {
    _fallbackStorage.remove(key);
    if (kDebugMode) {
      print('🔐 SecureStorage: _deleteFallback - $key 삭제됨');
    }
  }

  // 🧪 테스트 전용 헬퍼 메서드들
  /// 테스트를 위한 만료된 Phone Auth 세션 설정
  static Future<void> setExpiredPhoneAuthSession() async {
    if (kDebugMode) {
      try {
        final expiredTimestamp =
            DateTime.now().subtract(const Duration(hours: 25));
        await _storage.write(
            key: _phoneAuthTimestampKey,
            value: expiredTimestamp.toIso8601String());
        if (kDebugMode) {
          print('🔐 SecureStorage: setExpiredPhoneAuthSession - 완료');
        }
      } catch (e) {
        if (kDebugMode) {
          print('🔐 SecureStorage: setExpiredPhoneAuthSession - 에러: $e');
        }
        _saveFallback(
            _phoneAuthTimestampKey,
            DateTime.now()
                .subtract(const Duration(hours: 25))
                .toIso8601String());
      }
    }
  }
}
