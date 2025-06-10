// 필요한 import들
import 'dart:convert';

/// Toss Payments 결제 설정
///
/// ⚠️ 중요: 이 키들은 테스트용입니다.
/// 실제 운영 환경에서는 반드시 실제 키로 변경해주세요!
///
/// 키 변경 방법:
/// 1. Toss Payments 개발자센터(https://developers.tosspayments.com/)에서
///    실제 클라이언트 키와 시크릿 키를 발급받으세요
/// 2. 아래 값들을 실제 키로 교체하세요
/// 3. 보안을 위해 실제 운영 시에는 환경변수나 별도 설정 파일로 관리하세요
class PaymentConfig {
  // 🔑 Toss Payments 클라이언트 키 (공개키)
  // ⚠️ 현재 값: 테스트용 키입니다. 실제 키로 변경하세요!
  static const String tossClientKey = 'test_ck_DnyRpQWGrNZyNlAOB8l2yaKAnO5A';

  // 🔐 Toss Payments 시크릿 키 (비밀키)
  // ⚠️ 현재 값: 테스트용 키입니다. 실제 키로 변경하세요!
  // ⚠️ 주의: 시크릿 키는 절대 클라이언트에 노출되어서는 안됩니다!
  // 실제 운영 시에는 서버에서만 사용하도록 구성하세요.
  static const String tossSecretKey = 'test_sk_9OLNqbzXKBEVynyMO3A67YmpXyZA';

  // 🌐 Toss Payments API 엔드포인트
  static const String tossApiUrl = 'https://api.tosspayments.com';

  // 💰 결제 관련 설정
  static const String currency = 'KRW'; // 통화
  static const String paymentMethod = 'CARD'; // 기본 결제 수단
  static const String orderName = '공구앱 주문'; // 주문명

  // 🔄 결제 콜백 URL (실제 앱에서는 딥링크 설정 필요)
  static const String successUrl = 'https://your-app.com/payment/success';
  static const String failUrl = 'https://your-app.com/payment/fail';

  // 📱 모바일 결제 설정
  static const bool useMobileWebPayment = true; // 모바일 웹 결제 사용 여부
  static const String appScheme = 'gonggooapp'; // 앱 스킴 (딥링크)

  /// 결제 요청 시 사용할 기본 헤더
  static Map<String, String> get defaultHeaders => {
        'Authorization': 'Basic ${_encodeBase64("$tossSecretKey:")}',
        'Content-Type': 'application/json',
      };

  /// Base64 인코딩 헬퍼 메서드
  static String _encodeBase64(String text) {
    return base64Encode(utf8.encode(text));
  }

  /// 개발/운영 환경 구분
  static bool get isProduction => tossClientKey.startsWith('live_');
  static bool get isTest => tossClientKey.startsWith('test_');

  /// 환경별 설정 검증
  static void validateConfiguration() {
    if (isProduction) {
      assert(
          tossClientKey.startsWith('live_'), '운영 환경에서는 실제 클라이언트 키를 사용해야 합니다');
      assert(tossSecretKey.startsWith('live_'), '운영 환경에서는 실제 시크릿 키를 사용해야 합니다');
    }

    print('💳 Toss Payments 설정:');
    print('   - 환경: ${isProduction ? "운영" : "테스트"}');
    print('   - 클라이언트 키: ${tossClientKey.substring(0, 20)}...');
    print('   - 통화: $currency');
  }
}
