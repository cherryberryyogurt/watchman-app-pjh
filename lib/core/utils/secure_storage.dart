import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

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
  
  // Delete all tokens (for logout)
  static Future<void> deleteAllTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userIdKey);
      // Also delete fallback storage
      await _deleteFallback(_accessTokenKey);
      await _deleteFallback(_refreshTokenKey);
      await _deleteFallback(_userIdKey);
      
      debugPrint('SecureStorage: All tokens deleted successfully');
    } catch (e) {
      debugPrint('SecureStorage: Error deleting tokens - $e');
      // Try to delete from fallback storage
      await _deleteFallback(_accessTokenKey);
      await _deleteFallback(_refreshTokenKey);
      await _deleteFallback(_userIdKey);
    }
  }
  
  // Check if tokens exist
  static Future<bool> hasTokens() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      
      final hasTokens = accessToken != null && refreshToken != null;
      debugPrint('SecureStorage: Has tokens: $hasTokens');
      return hasTokens;
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