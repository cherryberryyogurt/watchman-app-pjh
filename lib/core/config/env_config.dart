import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 환경 설정 값을 관리하는 클래스
class EnvConfig {
  // .env 파일 로드
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");

      // 로드된 환경 변수 확인
      _printLoadedEnvVars();
    } catch (e) {
      debugPrint('Warning: .env file not found or cannot be loaded: $e');
    }
  }

  // 로드된 환경 변수 상태 출력 (디버깅용)
  static void _printLoadedEnvVars() {
    // 로드된 환경 변수 확인
    // 카카오 키 존재 여부만 확인 (로깅 제거)
    
    // 디버그 모드에서만 환경 변수 로드 상태 확인
    if (kDebugMode) {
      debugPrint('🔍 Environment Variables Status:');
      debugPrint('  - TOSS_CLIENT_KEY (compile-time): ${const String.fromEnvironment('TOSS_CLIENT_KEY').isNotEmpty ? 'LOADED' : 'NOT_FOUND'}');
      debugPrint('  - TOSS_CLIENT_KEY (dotenv): ${dotenv.env['TOSS_CLIENT_KEY']?.isNotEmpty == true ? 'LOADED' : 'NOT_FOUND'}');
      debugPrint('  - Final TOSS_CLIENT_KEY: ${tossClientKey.isNotEmpty ? 'AVAILABLE' : 'MISSING'}');
    }
  }

  // 카카오맵 API 키
  static String get kakaoMapApiKey {
    try {
      // First try compile-time environment variables (for web deployment)
      const compileTimeKey = String.fromEnvironment('KAKAO_MAP_API_KEY');
      if (compileTimeKey.isNotEmpty) {
        return compileTimeKey;
      }
      
      // Fallback to dotenv (for local development)
      final key = dotenv.env['KAKAO_MAP_API_KEY'] ?? '';
      return key;
    } catch (e) {
      return '';
    }
  }

  // 환경 설정 상태 확인 (디버깅용)
  static void printEnvStatus() {
    // 환경 설정 상태 확인 (디버깅용)
    // 프로덕션에서는 로깅하지 않음
  }

  // ✅ Toss Payments 클라이언트 키 (공개키이므로 안전)
  // 시크릿 키는 Firebase Cloud Functions에서만 사용
  static String get tossClientKey {
    // First try compile-time environment variables (for web deployment)
    const compileTimeKey = String.fromEnvironment('TOSS_CLIENT_KEY');
    if (compileTimeKey.isNotEmpty) {
      debugPrint('🔑 TOSS_CLIENT_KEY loaded from compile-time environment');
      return compileTimeKey;
    }
    
    // Fallback to dotenv (for local development)
    final dotenvKey = dotenv.env['TOSS_CLIENT_KEY'] ?? '';
    if (dotenvKey.isNotEmpty) {
      debugPrint('🔑 TOSS_CLIENT_KEY loaded from .env file');
      return dotenvKey;
    }
    
    debugPrint('❌ TOSS_CLIENT_KEY not found in environment variables or .env file');
    return '';
  }

  // Firebase 관련 설정
  static String get firebaseWebApiKey {
    // First try compile-time environment variables (for web deployment)
    const compileTimeKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
    if (compileTimeKey.isNotEmpty) {
      return compileTimeKey;
    }
    
    // Fallback to dotenv (for local development)
    return dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';
  }

  // 개발/프로덕션 환경 확인
  static bool get isProduction {
    // First try compile-time environment variables (for web deployment)
    const compileTimeEnv = String.fromEnvironment('ENV');
    if (compileTimeEnv.isNotEmpty) {
      return compileTimeEnv == 'production';
    }
    
    // Fallback to dotenv (for local development)
    return dotenv.env['ENV'] == 'production';
  }

  // 디버그 모드 확인
  static bool get isDebug {
    return kDebugMode;
  }
}
