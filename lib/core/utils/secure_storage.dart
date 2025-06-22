import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io' show Platform;
// 웹 호환성을 위한 조건부 import
import 'package:flutter/foundation.dart' show kIsWeb;

class SecureStorage {
  // Private constructor to prevent instantiation
  SecureStorage._();

  // Create storage with platform-specific options
  static final FlutterSecureStorage _storage = _createStorage();

  static FlutterSecureStorage _createStorage() {
    // 웹에서는 기본 옵션 사용
    if (kIsWeb) {
      return const FlutterSecureStorage();
    }

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

      // 테스트 환경에서의 호환성을 위해 fallback storage에도 저장
      await _saveFallback(_accessTokenKey, token);
    } catch (e) {
      _saveFallback(_accessTokenKey, token);
    }
  }

  // Read access token
  static Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      return token ?? await _readFallback(_accessTokenKey);
    } catch (e) {
      return await _readFallback(_accessTokenKey);
    }
  }

  // Save refresh token
  static Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      _saveFallback(_refreshTokenKey, token);
    }
  }

  // Read refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      return token ?? await _readFallback(_refreshTokenKey);
    } catch (e) {
      return await _readFallback(_refreshTokenKey);
    }
  }

  // Save user ID
  static Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
    } catch (e) {
      _saveFallback(_userIdKey, userId);
    }
  }

  // Read user ID
  static Future<String?> getUserId() async {
    try {
      final userId = await _storage.read(key: _userIdKey);
      return userId ?? await _readFallback(_userIdKey);
    } catch (e) {
      return await _readFallback(_userIdKey);
    }
  }

  // Save token expiry time
  static Future<void> saveTokenExpiryTime(DateTime expiryTime) async {
    try {
      final expiryTimeString = expiryTime.toIso8601String();
      await _storage.write(key: _tokenExpiryKey, value: expiryTimeString);
    } catch (e) {
      _saveFallback(_tokenExpiryKey, expiryTime.toIso8601String());
    }
  }

  // Read token expiry time
  static Future<DateTime?> getTokenExpiryTime() async {
    try {
      final expiryTimeString = await _storage.read(key: _tokenExpiryKey);
      if (expiryTimeString == null) {
        return null;
      }

      final expiryTime = DateTime.parse(expiryTimeString);
      return expiryTime;
    } catch (e) {
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
        return false; // No expiry time means token is invalid
      }

      final now = DateTime.now();
      final isValid = expiryTime.isAfter(now);
      return isValid;
    } catch (e) {
      return false; // Any error means token is invalid
    }
  }

  // Save "remember me" setting
  static Future<void> saveRememberMe(bool value) async {
    try {
      await _storage.write(key: _rememberMeKey, value: value.toString());

      // 테스트 환경에서의 호환성을 위해 fallback storage에도 저장
      await _saveFallback(_rememberMeKey, value.toString());
    } catch (e) {
      _saveFallback(_rememberMeKey, value.toString());
    }
  }

  // Get "remember me" setting (defaults to false if not set)
  static Future<bool> getRememberMe() async {
    try {
      final value = await _storage.read(key: _rememberMeKey);
      if (value == null) {
        return false; // Default to false
      }

      final rememberMe = value.toLowerCase() == 'true';
      return rememberMe;
    } catch (e) {
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

      // 테스트 환경에서의 호환성을 위해 fallback storage에도 저장
      await _saveFallback(_isPhoneAuthKey, isPhoneAuth.toString());
    } catch (e) {
      _saveFallback(_isPhoneAuthKey, isPhoneAuth.toString());
    }
  }

  /// Phone Auth 사용자 여부 조회
  static Future<bool> isPhoneAuthUser() async {
    try {
      final value = await _storage.read(key: _isPhoneAuthKey);
      if (value == null) {
        return false;
      }

      final isPhoneAuth = value.toLowerCase() == 'true';
      return isPhoneAuth;
    } catch (e) {
      final fallbackValue = await _readFallback(_isPhoneAuthKey);
      if (fallbackValue != null) {
        return fallbackValue.toLowerCase() == 'true';
      }
      return false;
    }
  }

  /// Phone Auth 세션 정보 저장
  static Future<void> savePhoneAuthSession() async {
    final currentTime = DateTime.now().toIso8601String();
    final sessionData = {
      'timestamp': currentTime,
      'sessionId': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    try {
      await _storage.write(
          key: _phoneAuthSessionKey, value: jsonEncode(sessionData));

      await _storage.write(key: _phoneAuthTimestampKey, value: currentTime);

      // 테스트 환경에서의 호환성을 위해 fallback storage에도 저장
      await _saveFallback(_phoneAuthSessionKey, currentTime);
      await _saveFallback(_phoneAuthTimestampKey, currentTime);
    } catch (e) {
      // fallback storage에 저장할 때도 await 사용

      await _saveFallback(_phoneAuthSessionKey, currentTime);
      await _saveFallback(_phoneAuthTimestampKey, currentTime);
    }
  }

  /// Phone Auth 세션 유효성 검사 (24시간 유효)
  static Future<bool> isPhoneAuthSessionValid() async {
    try {
      final timestampString = await _storage.read(key: _phoneAuthTimestampKey);

      if (timestampString == null) {
        // Fallback storage에서 확인

        final fallbackTimestampString =
            await _readFallback(_phoneAuthTimestampKey);
        if (fallbackTimestampString == null) {
          return false;
        }

        final fallbackTimestamp = DateTime.parse(fallbackTimestampString);
        final now = DateTime.now();
        final difference = now.difference(fallbackTimestamp);

        // Phone Auth 세션은 24시간 유효
        final isValid = difference.inHours < 24;

        return isValid;
      }

      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      // Phone Auth 세션은 24시간 유효
      final isValid = difference.inHours < 24;

      return isValid;
    } catch (e) {
      // 에러 발생 시 fallback storage 시도
      try {
        final fallbackTimestampString =
            await _readFallback(_phoneAuthTimestampKey);
        if (fallbackTimestampString != null) {
          final fallbackTimestamp = DateTime.parse(fallbackTimestampString);
          final now = DateTime.now();
          final difference = now.difference(fallbackTimestamp);
          final isValid = difference.inHours < 24;

          return isValid;
        }
      } catch (fallbackError) {
        // 폴백 스토리지에서도 실패한 경우 로그만 출력
        if (kDebugMode) {
          print('Fallback storage 읽기 실패: $fallbackError');
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

      // rememberMe가 false면 무조건 false
      if (!rememberMe) {
        return false;
      }

      if (isPhoneAuth) {
        // Phone Auth 사용자인 경우 세션 유효성만 검사
        final isSessionValid = await isPhoneAuthSessionValid();
        return isSessionValid;
      } else {
        // 기존 email+password 사용자인 경우 토큰 유효성 검사
        final isTokenValid = await SecureStorage.isTokenValid();
        return isTokenValid;
      }
    } catch (e) {
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
    } catch (e) {
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
      return hasValidTokens;
    } catch (e) {
      return false;
    }
  }

  // Fallback storage methods using non-secure storage for testing/development
  // Note: In a production app, you should implement a more secure fallback
  static final Map<String, String> _fallbackStorage = {};

  static Future<void> _saveFallback(String key, String value) async {
    _fallbackStorage[key] = value;
  }

  static Future<String?> _readFallback(String key) async {
    final value = _fallbackStorage[key];
    return value;
  }

  static Future<void> _deleteFallback(String key) async {
    _fallbackStorage.remove(key);
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
      } catch (e) {
        _saveFallback(
            _phoneAuthTimestampKey,
            DateTime.now()
                .subtract(const Duration(hours: 25))
                .toIso8601String());
      }
    }
  }
}
