import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 환경 설정 값을 관리하는 클래스
class EnvConfig {
  // .env 파일 로드
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('Warning: .env file not found or cannot be loaded: $e');
    }
  }

  // 카카오맵 API 키
  static String get kakaoMapApiKey {
    // 첫 번째 우선순위: 환경 변수에서 가져오기
    final envKey = Platform.environment['KAKAO_MAP_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    // 두 번째 우선순위: .env 파일에서 가져오기
    final dotenvKey = dotenv.env['KAKAO_MAP_API_KEY'];
    if (dotenvKey != null && dotenvKey.isNotEmpty) {
      return dotenvKey;
    }
    
    // 세 번째 우선순위: 하드코딩된 키 (개발용, 실제 배포시 교체 필요)
    debugPrint('Warning: Using fallback KAKAO_MAP_API_KEY. Configure API key in .env file or environment variables.');
    return 'YOUR_KAKAO_MAP_API_KEY';
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