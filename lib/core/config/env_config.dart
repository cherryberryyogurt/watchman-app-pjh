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
  }

  // 카카오맵 API 키
  static String get kakaoMapApiKey {
    try {
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
    final key = dotenv.env['TOSS_CLIENT_KEY'] ?? '';
    return key;
  }

  // Firebase 관련 설정
  static String get firebaseWebApiKey {
    return dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';
  }

  // 개발/프로덕션 환경 확인
  static bool get isProduction {
    return dotenv.env['ENV'] == 'production';
  }

  // 디버그 모드 확인
  static bool get isDebug {
    return kDebugMode;
  }
}
