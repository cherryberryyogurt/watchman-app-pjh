import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 환경 설정 값을 관리하는 클래스
class EnvConfig {
  // .env 파일 로드
  static Future<void> load() async {
    try {
      print('🔧 EnvConfig.load() 시작');
      await dotenv.load(fileName: ".env");
      print('🔧 ✅ .env 파일 로드 성공');

      // 로드된 환경 변수 확인
      _printLoadedEnvVars();
    } catch (e) {
      print('🔧 ❌ .env 파일 로드 실패: $e');
      debugPrint('Warning: .env file not found or cannot be loaded: $e');
    }
  }

  // 로드된 환경 변수 상태 출력 (디버깅용)
  static void _printLoadedEnvVars() {
    print('🔧 === .env 파일 로드 상태 ===');
    print('🔧 dotenv.isInitialized: ${dotenv.isInitialized}');
    print('🔧 dotenv.env.keys: ${dotenv.env.keys.toList()}');

    // KAKAO_MAP_API_KEY 확인
    final kakaoKey = dotenv.env['KAKAO_MAP_API_KEY'];
    print('🔧 KAKAO_MAP_API_KEY 존재: ${kakaoKey != null}');
    if (kakaoKey != null) {
      print('🔧 KAKAO_MAP_API_KEY 길이: ${kakaoKey.length}');
      print(
          '🔧 KAKAO_MAP_API_KEY 앞 10자: ${kakaoKey.length > 10 ? kakaoKey.substring(0, 10) : kakaoKey}...');
    }
    print('🔧 ========================');
  }

  // 카카오맵 API 키
  static String get kakaoMapApiKey {
    print('🔧 kakaoMapApiKey getter 호출');
    try {
      final key = dotenv.env['KAKAO_MAP_API_KEY'] ?? '';
      print('🔧 환경변수에서 로드한 키: ${key.isEmpty ? "없음" : "있음(${key.length}자)"}');
      return key;
    } catch (e) {
      print('🔧 ❌ 환경변수 로드 실패: $e');
      return '';
    }

    // 첫 번째 우선순위: 환경 변수에서 가져오기
    // final envKey = Platform.environment['KAKAO_MAP_API_KEY'];
    // if (envKey != null && envKey.isNotEmpty) {
    //   print('🔧 ✅ 환경 변수에서 API 키 찾음');
    //   return envKey;
    // }

    // // 두 번째 우선순위: .env 파일에서 가져오기
    // final dotenvKey = dotenv.env['KAKAO_MAP_API_KEY'];
    // print('🔧 dotenv에서 가져온 키: ${dotenvKey != null ? "있음(${dotenvKey.length}자)" : "없음"}');

    // if (dotenvKey != null && dotenvKey.isNotEmpty) {
    //   print('🔧 ✅ .env 파일에서 API 키 찾음');
    //   return dotenvKey;
    // }

    // // 세 번째 우선순위: 하드코딩된 키 (개발용, 실제 배포시 교체 필요)
    // print('🔧 ❌ API 키를 찾을 수 없어 fallback 사용');
    // debugPrint('Warning: Using fallback KAKAO_MAP_API_KEY. Configure API key in .env file or environment variables.');
    // return 'YOUR_KAKAO_MAP_API_KEY';
  }

  // 환경 설정 상태 확인 (디버깅용)
  static void printEnvStatus() {
    print('🔧 === 환경 설정 상태 ===');
    print('🔧 dotenv.isInitialized: ${dotenv.isInitialized}');
    print(
        '🔧 kakaoMapApiKey: ${kakaoMapApiKey.length > 10 ? "${kakaoMapApiKey.substring(0, 10)}..." : kakaoMapApiKey}');
    print('🔧 isProduction: $isProduction');
    print('🔧 isDebug: $isDebug');
    print('🔧 ===================');
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
