/// 주문 관련 Enum 정의
///
/// 주문 상태, 배송 타입, 결제 상태 등을 정의합니다.

/// 🏷️ 주문 상태 (8단계)
///
/// 주문부터 완료까지의 전체 플로우를 관리합니다.
enum OrderStatus {
  /// 주문 생성됨 (결제 대기)
  pending('pending', '결제 대기'),

  /// 결제 완료됨 (상품 준비 대기)
  confirmed('confirmed', '주문 확인'),

  /// 상품 준비 중
  preparing('preparing', '상품 준비중'),

  /// 배송 시작됨 (배송 상품만)
  shipped('shipped', '배송중'),

  /// 픽업 준비 완료됨 (픽업 상품만)
  readyForPickup('ready_for_pickup', '픽업 준비 완료'),

  /// 픽업됨
  pickedUp('picked_up', '픽업됨'),

  /// 배송 완료됨 (배송 상품만)
  delivered('delivered', '배송 완료'),

  /// 주문 취소됨
  cancelled('cancelled', '주문 취소'),

  /// 주문 완전 완료됨 (인증까지 완료됨)
  finished('finished', '주문 완료');

  const OrderStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  /// String 값으로부터 OrderStatus 생성
  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Invalid OrderStatus: $value'),
    );
  }

  /// 상태별 다음 가능한 상태들
  List<OrderStatus> get nextStatuses {
    switch (this) {
      case OrderStatus.pending:
        return [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return [OrderStatus.preparing, OrderStatus.cancelled];
      case OrderStatus.preparing:
        return [
          OrderStatus.shipped,
          OrderStatus.readyForPickup,
          // OrderStatus.cancelled // 준비중 단계에서는 취소 불가
        ];
      case OrderStatus.shipped:
        return [OrderStatus.delivered];
      case OrderStatus.readyForPickup:
        return [OrderStatus.pickedUp];
      case OrderStatus.delivered:
        return [OrderStatus.finished];
      case OrderStatus.pickedUp:
        return [OrderStatus.finished];
      case OrderStatus.cancelled:
      case OrderStatus.finished:
        return [];
    }
  }

  /// 취소 가능한 상태인지 확인
  bool get isCancellable {
    return [
      OrderStatus.pending,
      OrderStatus.confirmed,
      // OrderStatus.preparing, // 준비중 단계에서는 취소 불가
    ].contains(this);
  }

  /// 픽업 인증 가능한 상태인지 확인
  bool get canVerifyPickup => [delivered, readyForPickup].contains(this);

  /// 완료된 상태인지 확인
  bool get isCompleted => [pickedUp, finished].contains(this);

  /// 진행 중인 상태인지 확인
  bool get isInProgress =>
      [confirmed, preparing, shipped, readyForPickup].contains(this);
}

/// 🚚 배송 타입
///
/// 상품별로 픽업 또는 배송을 선택할 수 있습니다.
enum DeliveryType {
  /// 매장 픽업
  pickup('pickup', '픽업'),

  /// 배송
  delivery('delivery', '배송');

  const DeliveryType(this.value, this.displayName);

  final String value;
  final String displayName;

  /// String 값으로부터 DeliveryType 생성
  static DeliveryType fromString(String value) {
    return DeliveryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid DeliveryType: $value'),
    );
  }
}

/// 💰 결제 상태 (Toss Payments 기준)
///
/// Toss Payments API의 결제 상태를 정의합니다.
enum PaymentStatus {
  /// 결제 준비됨
  ready('READY', '결제 준비'),

  /// 결제 진행중 (인증 중)
  inProgress('IN_PROGRESS', '결제 진행중'),

  /// 결제 대기 (가상계좌 입금 대기)
  waitingForDeposit('WAITING_FOR_DEPOSIT', '입금 대기'),

  /// 결제 완료
  done('DONE', '결제 완료'),

  /// 결제 취소됨
  canceled('CANCELED', '결제 취소'),

  /// 부분 취소됨
  partialCanceled('PARTIAL_CANCELED', '부분 취소'),

  /// 결제 실패
  aborted('ABORTED', '결제 실패'),

  /// 결제 만료
  expired('EXPIRED', '결제 만료');

  const PaymentStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  /// String 값으로부터 PaymentStatus 생성
  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Invalid PaymentStatus: $value'),
    );
  }

  /// 결제 성공 상태인지 확인
  bool get isSuccessful => this == PaymentStatus.done;

  /// 결제 실패 상태인지 확인
  bool get isFailed => [aborted, expired].contains(this);

  /// 결제 취소 상태인지 확인
  bool get isCanceled => [canceled, partialCanceled].contains(this);

  /// 진행 중인 결제 상태인지 확인
  bool get isPending => [
        PaymentStatus.ready,
        PaymentStatus.inProgress,
        PaymentStatus.waitingForDeposit,
      ].contains(this);
}

/// 💳 결제 수단 (Toss Payments 기준)
///
/// Toss Payments에서 지원하는 결제 수단을 정의합니다.
enum PaymentMethod {
  /// 카드 결제
  card('카드', '카드'),

  /// 가상계좌
  virtualAccount('가상계좌', '가상계좌'),

  /// 계좌이체
  transfer('계좌이체', '계좌이체'),

  /// 휴대폰 결제
  mobilePhone('휴대폰', '휴대폰'),

  /// 간편결제
  easyPay('간편결제', '간편결제'),

  /// 상품권
  giftCertificate('상품권', '상품권'),

  /// 도서문화상품권
  cultureLand('도서문화상품권', '도서문화상품권'),

  /// 스마트문상
  smartCulture('스마트문상', '스마트문상'),

  /// 해피머니
  happyMoney('해피머니', '해피머니'),

  /// 베네피아
  booknlife('베네피아', '베네피아'),

  /// 기타
  unknown('기타', '기타');

  const PaymentMethod(this.value, this.displayName);

  final String value;
  final String displayName;

  /// String 값으로부터 PaymentMethod 생성
  static PaymentMethod fromString(String? value) {
    if (value == null) return PaymentMethod.unknown;

    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.unknown,
    );
  }

  /// API 전송용 값 (Toss Payments API 규격)
  String get apiValue => value;
}

/// 📦 주문 아이템 상태
///
/// 주문 내 개별 상품의 상태를 관리합니다.
enum OrderItemStatus {
  /// 준비중
  preparing('preparing', '준비중'),

  /// 준비완료
  ready('ready', '준비완료'),

  /// 배송중
  shipping('shipping', '배송중'),

  /// 배송완료/픽업가능
  completed('completed', '완료'),

  /// 취소됨
  cancelled('cancelled', '취소');

  const OrderItemStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static OrderItemStatus fromString(String value) {
    return OrderItemStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Invalid OrderItemStatus: $value'),
    );
  }
}

/// 📋 웹훅 이벤트 타입
///
/// Toss Payments에서 전송하는 웹훅 이벤트 타입을 정의합니다.
enum WebhookEventType {
  /// 결제 승인 완료
  paymentDone('Payment.Done', '결제 승인 완료'),

  /// 결제 취소 완료
  paymentCanceled('Payment.Canceled', '결제 취소 완료'),

  /// 가상계좌 입금 완료
  virtualAccountDeposit('VirtualAccount.Deposit', '가상계좌 입금 완료'),

  /// 정기결제 빌링키 발급 완료
  billingKeyIssued('BillingKey.Issued', '빌링키 발급 완료'),

  /// 정기결제 빌링키 삭제 완료
  billingKeyDeleted('BillingKey.Deleted', '빌링키 삭제 완료'),

  /// 기타 이벤트
  unknown('Unknown', '기타 이벤트');

  const WebhookEventType(this.value, this.displayName);

  final String value;
  final String displayName;

  /// String 값으로부터 WebhookEventType 생성
  static WebhookEventType fromString(String? value) {
    if (value == null) return WebhookEventType.unknown;

    return WebhookEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => WebhookEventType.unknown,
    );
  }
}
