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
  
  // Save access token
  static Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      debugPrint('SecureStorage: Access token saved successfully');
    } catch (e) {
      debugPrint('SecureStorage: Error saving access token - $e');
      // Handle error but don't rethrow to prevent app crashes
      // Instead, we'll resort to fallback storage if needed
      _saveFallback(_accessTokenKey, token);
    }
  }
  
  // Read access token
  static Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      debugPrint('SecureStorage: Access token retrieved: ${token != null ? 'Yes' : 'No'}');
      return token ?? await _readFallback(_accessTokenKey);
    } catch (e) {
      debugPrint('SecureStorage: Error getting access token - $e');
      return await _readFallback(_accessTokenKey);
    }
  }
  
  // Save refresh token
  static Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      debugPrint('SecureStorage: Refresh token saved successfully');
    } catch (e) {
      debugPrint('SecureStorage: Error saving refresh token - $e');
      _saveFallback(_refreshTokenKey, token);
    }
  }
  
  // Read refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      debugPrint('SecureStorage: Refresh token retrieved: ${token != null ? 'Yes' : 'No'}');
      return token ?? await _readFallback(_refreshTokenKey);
    } catch (e) {
      debugPrint('SecureStorage: Error getting refresh token - $e');
      return await _readFallback(_refreshTokenKey);
    }
  }
  
  // Save user ID
  static Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
      debugPrint('SecureStorage: User ID saved successfully');
    } catch (e) {
      debugPrint('SecureStorage: Error saving user ID - $e');
      _saveFallback(_userIdKey, userId);
    }
  }
  
  // Read user ID
  static Future<String?> getUserId() async {
    try {
      final userId = await _storage.read(key: _userIdKey);
      debugPrint('SecureStorage: User ID retrieved: ${userId != null ? 'Yes' : 'No'}');
      return userId ?? await _readFallback(_userIdKey);
    } catch (e) {
      debugPrint('SecureStorage: Error getting user ID - $e');
      return await _readFallback(_userIdKey);
    }
  }
  
  // Save token expiry time
  static Future<void> saveTokenExpiryTime(DateTime expiryTime) async {
    try {
      final expiryTimeString = expiryTime.toIso8601String();
      await _storage.write(key: _tokenExpiryKey, value: expiryTimeString);
      debugPrint('SecureStorage: Token expiry time saved successfully: $expiryTimeString');
    } catch (e) {
      debugPrint('SecureStorage: Error saving token expiry time - $e');
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
      debugPrint('SecureStorage: Token expiry time retrieved: $expiryTimeString');
      return expiryTime;
    } catch (e) {
      debugPrint('SecureStorage: Error getting token expiry time - $e');
      
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
        return false;  // No expiry time means token is invalid
      }
      
      final now = DateTime.now();
      final isValid = expiryTime.isAfter(now);
      debugPrint('SecureStorage: Token validity check - Valid: $isValid (expires: ${expiryTime.toIso8601String()})');
      return isValid;
    } catch (e) {
      debugPrint('SecureStorage: Error checking token validity - $e');
      return false;  // Any error means token is invalid
    }
  }
  
  // Save "remember me" setting
  static Future<void> saveRememberMe(bool value) async {
    try {
      await _storage.write(key: _rememberMeKey, value: value.toString());
      debugPrint('SecureStorage: Remember me setting saved: $value');
    } catch (e) {
      debugPrint('SecureStorage: Error saving remember me setting - $e');
      _saveFallback(_rememberMeKey, value.toString());
    }
  }
  
  // Get "remember me" setting (defaults to false if not set)
  static Future<bool> getRememberMe() async {
    try {
      final value = await _storage.read(key: _rememberMeKey);
      if (value == null) {
        return false;  // Default to false
      }
      
      final rememberMe = value.toLowerCase() == 'true';
      debugPrint('SecureStorage: Remember me setting retrieved: $rememberMe');
      return rememberMe;
    } catch (e) {
      debugPrint('SecureStorage: Error getting remember me setting - $e');
      
      final fallbackValue = await _readFallback(_rememberMeKey);
      if (fallbackValue != null) {
        return fallbackValue.toLowerCase() == 'true';
      }
      return false;  // Default to false
    }
  }
  
  // Delete all tokens (for logout)
  static Future<void> deleteAllTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _tokenExpiryKey);
      // Keep remember me setting unless explicitly cleared
      
      // Also delete fallback storage
      await _deleteFallback(_accessTokenKey);
      await _deleteFallback(_refreshTokenKey);
      await _deleteFallback(_userIdKey);
      await _deleteFallback(_tokenExpiryKey);
      
      debugPrint('SecureStorage: All tokens deleted successfully');
    } catch (e) {
      debugPrint('SecureStorage: Error deleting tokens - $e');
      // Try to delete from fallback storage
      await _deleteFallback(_accessTokenKey);
      await _deleteFallback(_refreshTokenKey);
      await _deleteFallback(_userIdKey);
      await _deleteFallback(_tokenExpiryKey);
    }
  }
  
  // Check if tokens exist and are valid
  static Future<bool> hasValidTokens() async {
    try {
      final accessToken = await getAccessToken();
      final rememberMe = await getRememberMe();
      final isTokenValid = await SecureStorage.isTokenValid();
      
      // 토큰이 있고, "로그인 상태 유지"가 true이고, 토큰이 유효한 경우에만 true 반환
      final hasValidTokens = accessToken != null && rememberMe && isTokenValid;
      debugPrint('SecureStorage: Has valid tokens: $hasValidTokens (rememberMe: $rememberMe, isTokenValid: $isTokenValid)');
      return hasValidTokens;
    } catch (e) {
      debugPrint('SecureStorage: Error checking tokens - $e');
      return false;
    }
  }
  
  // Fallback storage methods using non-secure storage for testing/development
  // Note: In a production app, you should implement a more secure fallback
  static final Map<String, String> _fallbackStorage = {};
  
  static Future<void> _saveFallback(String key, String value) async {
    _fallbackStorage[key] = value;
    debugPrint('SecureStorage: Fallback storage used for saving $key');
  }
  
  static Future<String?> _readFallback(String key) async {
    final value = _fallbackStorage[key];
    debugPrint('SecureStorage: Fallback storage used for reading $key: ${value != null ? 'Yes' : 'No'}');
    return value;
  }
  
  static Future<void> _deleteFallback(String key) async {
    _fallbackStorage.remove(key);
    debugPrint('SecureStorage: Fallback storage deleted for $key');
  }
} 