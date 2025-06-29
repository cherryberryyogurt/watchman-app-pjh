/// 앱 전역 설정값들을 관리하는 클래스
class AppConfig {
  static const int RECENT_ORDERS_LIMIT = 3;

  // 📍 위치 인증 관련 설정
  static const double maxDistance = 10.0; // 10km

  // 🚚 배송 관련 설정
  static const int deliveryFee = 3000; // 배송비 (원)
  static const int pickupFee = 0; // 픽업비 (원)

  // 📦 주문 관련 설정
  static const int minimumOrderAmount = 10000; // 최소 주문 금액 (원)
  static const int maxOrderMemoLength = 200; // 주문 메모 최대 길이

  // 💳 결제 관련 설정
  static const String paymentProvider = 'TOSS_PAYMENTS';

  // 📱 UI 관련 설정
  static const int maxProductImages = 10; // 상품 이미지 최대 개수
  static const int productListPageSize = 20; // 상품 목록 페이지 크기
}
