// 필요한 import들
import 'env_config.dart';

/// Toss Payments 결제 설정
///
/// ✅ 보안 개선됨: 시크릿 키는 Firebase Cloud Functions에서만 관리
/// 클라이언트에서는 공개키(클라이언트 키)만 사용하여 보안 강화
///
/// 키 변경 방법:
/// 1. Toss Payments 개발자센터(https://developers.tosspayments.com/)에서
///    실제 클라이언트 키를 발급받으세요
/// 2. .env 파일의 TOSS_CLIENT_KEY를 실제 키로 교체하세요
/// 3. 시크릿 키는 Firebase Cloud Functions 환경 변수로 설정하세요
class PaymentConfig {
  // 🔑 Toss Payments 클라이언트 키 (공개키 - 클라이언트 노출 안전)
  static String get tossClientKey {
    final key = EnvConfig.tossClientKey;
    return key;
  }

  // 🌐 Toss Payments API 엔드포인트
  static const String tossApiUrl = 'https://api.tosspayments.com';

  // 💰 결제 관련 설정
  static const String currency = 'KRW'; // 통화
  static const String paymentMethod = 'CARD'; // 기본 결제 수단
  static const String orderName = '공구앱 주문'; // 주문명

  // 🔄 결제 콜백 URL - 앱 스킴 사용 (Android/iOS 설정과 일치)
  static String get successUrl => '$appSchemeUrl://payment/success';
  static String get failUrl => '$appSchemeUrl://payment/fail';

  // 📱 모바일 결제 설정
  static const bool useMobileWebPayment = true; // 모바일 웹 결제 사용 여부

  /// 환경별 앱 URL 스킴 (AndroidManifest.xml, Info.plist와 일치)
  static String get appSchemeUrl => 'gonggoo';


  /// 개발/운영 환경 구분
  static bool get isProduction => tossClientKey.startsWith('live_');
  static bool get isTest => tossClientKey.startsWith('test_');

  /// 환경별 Base API URL
  static String get baseApiUrl => isProduction
      ? 'https://api.tosspayments.com'
      : 'https://api.tosspayments.com'; // 토스는 같은 URL 사용

  /// 환경별 앱 URL 스킴
  static String get appScheme => isProduction ? 'gonggoo' : 'gonggoo-dev';

  /// 환경별 딥링크 도메인
  static String get deepLinkDomain =>
      isProduction ? 'gonggoo.app' : 'dev.gonggoo.app';

  /// 파라미터가 포함된 성공 URL 생성
  static String getSuccessUrlWithParams({
    required String orderId,
    required String amount,
    String? paymentKey,
  }) {
    final params = <String>[];
    params.add('orderId=$orderId');
    params.add('amount=$amount');
    if (paymentKey != null) {
      params.add('paymentKey=$paymentKey');
    }
    return '$successUrl?${params.join('&')}';
  }

  /// 파라미터가 포함된 실패 URL 생성
  static String getFailUrlWithParams({
    required String orderId,
    String? code,
    String? message,
  }) {
    final params = <String>[];
    params.add('orderId=$orderId');
    if (code != null) {
      params.add('code=$code');
    }
    if (message != null) {
      params.add('message=${Uri.encodeComponent(message)}');
    }
    return '$failUrl?${params.join('&')}';
  }

  /// 환경별 결제 설정
  static Map<String, dynamic> get environmentConfig => {
        'environment': isProduction ? 'production' : 'test',
        'clientKey': tossClientKey,
        'apiUrl': baseApiUrl,
        'appScheme': appScheme,
        'deepLinkDomain': deepLinkDomain,
        'successUrl': successUrl,
        'failUrl': failUrl,
        'debugMode': !isProduction,
        'timeouts': {
          'payment': isProduction ? 180000 : 60000, // ms
          'confirmation': isProduction ? 30000 : 15000, // ms
          'webview': isProduction ? 120000 : 60000, // ms
        },
        'retryConfig': {
          'maxRetries': isProduction ? 3 : 5,
          'retryDelay': isProduction ? 2000 : 1000, // ms
        },
      };

  /// 환경별 설정 검증
  static void validateConfiguration() {
    if (isProduction) {
      assert(
          tossClientKey.startsWith('live_'), '운영 환경에서는 실제 클라이언트 키를 사용해야 합니다');

      // 운영 환경에서는 추가 검증
      assert(deepLinkDomain == 'gonggoo.app', '운영 환경에서는 실제 도메인을 사용해야 합니다');
    }

    // URL 스킴 검증
    assert(successUrl.startsWith('gonggoo://'),
        'successUrl은 gonggoo:// 스킴을 사용해야 합니다');
    assert(
        failUrl.startsWith('gonggoo://'), 'failUrl은 gonggoo:// 스킴을 사용해야 합니다');

    // Toss Payments 설정 검증 완료
    // 프로덕션에서는 로깅하지 않음
  }

  /// 디버그 로깅 제어
  static void debugLog(String message) {
    if (!isProduction) {
      // 디버그 로깅 (프로덕션에서는 비활성화)
    }
  }

  /// 서버 사이드 유효성 검증 강제
  static bool get requireServerValidation => isProduction;

  /// 로깅 레벨 설정
  static bool get enableDebugLogging => !isProduction;
  static bool get enableErrorLogging => true;
  static bool get enablePerformanceLogging => !isProduction;

  /// 🔒 결제 승인을 위한 Cloud Function 엔드포인트
  static const String paymentConfirmFunction = 'confirmPayment';
  static const String webhookFunction = 'handlePaymentWebhook';
}
