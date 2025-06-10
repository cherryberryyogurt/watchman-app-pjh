/// Order 시스템 모델 정의
///
/// OrderModel, PaymentInfo, DeliveryAddress, OrderedProduct 등
/// 모든 주문 관련 모델을 포함합니다.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'order_enums.dart';

part 'order_model.g.dart';

/// 📍 배송 주소 정보
///
/// 주문별로 설정되는 배송 주소입니다.
@JsonSerializable()
class DeliveryAddress extends Equatable {
  /// 수령인 이름
  final String recipientName;

  /// 수령인 전화번호
  final String recipientPhone;

  /// 우편번호
  final String postalCode;

  /// 기본 주소
  final String address;

  /// 상세 주소
  final String detailAddress;

  /// 배송 요청사항
  final String? deliveryNote;

  const DeliveryAddress({
    required this.recipientName,
    required this.recipientPhone,
    required this.postalCode,
    required this.address,
    required this.detailAddress,
    this.deliveryNote,
  });

  /// JSON으로부터 생성
  factory DeliveryAddress.fromJson(Map<String, dynamic> json) =>
      _$DeliveryAddressFromJson(json);

  /// JSON으로 변환
  Map<String, dynamic> toJson() => _$DeliveryAddressToJson(this);

  /// Firestore Map으로부터 생성 (호환성)
  factory DeliveryAddress.fromMap(Map<String, dynamic> map) =>
      DeliveryAddress.fromJson(map);

  /// Firestore Map으로 변환 (호환성)
  Map<String, dynamic> toMap() => toJson();

  /// 전체 주소 문자열
  String get fullAddress => '$address $detailAddress';

  @override
  List<Object?> get props => [
        recipientName,
        recipientPhone,
        postalCode,
        address,
        detailAddress,
        deliveryNote,
      ];

  DeliveryAddress copyWith({
    String? recipientName,
    String? recipientPhone,
    String? postalCode,
    String? address,
    String? detailAddress,
    String? deliveryNote,
  }) {
    return DeliveryAddress(
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      postalCode: postalCode ?? this.postalCode,
      address: address ?? this.address,
      detailAddress: detailAddress ?? this.detailAddress,
      deliveryNote: deliveryNote ?? this.deliveryNote,
    );
  }
}

/// 💳 Toss Payments 결제 정보 (100% API 매핑)
///
/// Toss Payments API의 Payment 객체를 완전히 매핑한 클래스입니다.
/// 50개 이상의 모든 필드를 지원합니다.
@JsonSerializable()
class PaymentInfo extends Equatable {
  // 🏷️ 기본 정보
  /// 결제 키 (Toss Payments 고유)
  final String? paymentKey;

  /// 주문 ID (우리 시스템)
  final String orderId;

  /// 결제 상태
  @JsonKey(fromJson: _paymentStatusFromJson, toJson: _paymentStatusToJson)
  final PaymentStatus status;

  /// 결제 금액
  final int totalAmount;

  /// 취소 가능 금액
  final int? balanceAmount;

  /// 공급가액
  final int? suppliedAmount;

  /// 부가세
  final int? vat;

  /// 비과세 금액
  final int? taxFreeAmount;

  // 🛒 주문 정보
  /// 주문명
  final String? orderName;

  /// 상점ID
  final String? mId;

  /// API 버전
  final String? version;

  /// 결제 수단
  @JsonKey(fromJson: _paymentMethodFromJson, toJson: _paymentMethodToJson)
  final PaymentMethod? method;

  // ⏰ 시간 정보
  /// 결제 요청 시각
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? requestedAt;

  /// 결제 승인 시각
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? approvedAt;

  // 🏪 가맹점 정보
  /// 문화비 소득공제 적용 금액
  final int? cultureExpense;

  /// 에스크로 사용 여부
  final bool? useEscrow;

  /// 현금영수증 정보
  final Map<String, dynamic>? cashReceipt;

  /// 에스크로 정보
  final Map<String, dynamic>? escrow;

  // 💳 결제 수단별 상세 정보
  /// 카드 결제 정보
  final Map<String, dynamic>? card;

  /// 가상계좌 정보
  final Map<String, dynamic>? virtualAccount;

  /// 계좌이체 정보
  final Map<String, dynamic>? transfer;

  /// 휴대폰 결제 정보
  final Map<String, dynamic>? mobilePhone;

  /// 상품권 결제 정보
  final Map<String, dynamic>? giftCertificate;

  /// 간편결제 정보
  final Map<String, dynamic>? easyPay;

  // 🎯 추가 정보
  /// 할인 정보
  final Map<String, dynamic>? discount;

  /// 카드 할부 정보
  final Map<String, dynamic>? cardInstallment;

  /// 국가 코드
  final String? country;

  /// 실패 정보
  final Map<String, dynamic>? failure;

  /// 취소 내역
  final List<Map<String, dynamic>>? cancels;

  /// 현금영수증 내역
  final List<Map<String, dynamic>>? cashReceipts;

  // 🔄 거래 정보
  /// 영수증 URL
  final String? receiptUrl;

  /// 결제 영수증 URL
  final String? checkoutUrl;

  /// 거래 식별자
  final String? transactionKey;

  /// 마지막 거래 키
  final String? lastTransactionKey;

  const PaymentInfo({
    this.paymentKey,
    required this.orderId,
    required this.status,
    required this.totalAmount,
    this.balanceAmount,
    this.suppliedAmount,
    this.vat,
    this.taxFreeAmount,
    this.orderName,
    this.mId,
    this.version,
    this.method,
    this.requestedAt,
    this.approvedAt,
    this.cultureExpense,
    this.useEscrow,
    this.cashReceipt,
    this.escrow,
    this.card,
    this.virtualAccount,
    this.transfer,
    this.mobilePhone,
    this.giftCertificate,
    this.easyPay,
    this.discount,
    this.cardInstallment,
    this.country,
    this.failure,
    this.cancels,
    this.cashReceipts,
    this.receiptUrl,
    this.checkoutUrl,
    this.transactionKey,
    this.lastTransactionKey,
  });

  /// JSON으로부터 생성
  factory PaymentInfo.fromJson(Map<String, dynamic> json) =>
      _$PaymentInfoFromJson(json);

  /// JSON으로 변환
  Map<String, dynamic> toJson() => _$PaymentInfoToJson(this);

  /// Toss Payments API 응답으로부터 생성 (호환성)
  factory PaymentInfo.fromTossResponse(Map<String, dynamic> json) =>
      PaymentInfo.fromJson(json);

  /// Firestore Map으로부터 생성 (호환성)
  factory PaymentInfo.fromMap(Map<String, dynamic> map) =>
      PaymentInfo.fromJson(map);

  /// Firestore Map으로 변환 (호환성)
  Map<String, dynamic> toMap() => toJson();

  /// 결제 성공 여부
  bool get isSuccessful => status.isSuccessful;

  /// 결제 실패 여부
  bool get isFailed => status.isFailed;

  /// 취소 가능 여부
  bool get isCancellable => status.isSuccessful && (balanceAmount ?? 0) > 0;

  @override
  List<Object?> get props => [
        paymentKey,
        orderId,
        status,
        totalAmount,
        balanceAmount,
        suppliedAmount,
        vat,
        taxFreeAmount,
        orderName,
        mId,
        version,
        method,
        requestedAt,
        approvedAt,
        cultureExpense,
        useEscrow,
        cashReceipt,
        escrow,
        card,
        virtualAccount,
        transfer,
        mobilePhone,
        giftCertificate,
        easyPay,
        discount,
        cardInstallment,
        country,
        failure,
        cancels,
        cashReceipts,
        receiptUrl,
        checkoutUrl,
        transactionKey,
        lastTransactionKey,
      ];

  PaymentInfo copyWith({
    String? paymentKey,
    String? orderId,
    PaymentStatus? status,
    int? totalAmount,
    int? balanceAmount,
    int? suppliedAmount,
    int? vat,
    int? taxFreeAmount,
    String? orderName,
    String? mId,
    String? version,
    PaymentMethod? method,
    DateTime? requestedAt,
    DateTime? approvedAt,
    int? cultureExpense,
    bool? useEscrow,
    Map<String, dynamic>? cashReceipt,
    Map<String, dynamic>? escrow,
    Map<String, dynamic>? card,
    Map<String, dynamic>? virtualAccount,
    Map<String, dynamic>? transfer,
    Map<String, dynamic>? mobilePhone,
    Map<String, dynamic>? giftCertificate,
    Map<String, dynamic>? easyPay,
    Map<String, dynamic>? discount,
    Map<String, dynamic>? cardInstallment,
    String? country,
    Map<String, dynamic>? failure,
    List<Map<String, dynamic>>? cancels,
    List<Map<String, dynamic>>? cashReceipts,
    String? receiptUrl,
    String? checkoutUrl,
    String? transactionKey,
    String? lastTransactionKey,
  }) {
    return PaymentInfo(
      paymentKey: paymentKey ?? this.paymentKey,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      suppliedAmount: suppliedAmount ?? this.suppliedAmount,
      vat: vat ?? this.vat,
      taxFreeAmount: taxFreeAmount ?? this.taxFreeAmount,
      orderName: orderName ?? this.orderName,
      mId: mId ?? this.mId,
      version: version ?? this.version,
      method: method ?? this.method,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      cultureExpense: cultureExpense ?? this.cultureExpense,
      useEscrow: useEscrow ?? this.useEscrow,
      cashReceipt: cashReceipt ?? this.cashReceipt,
      escrow: escrow ?? this.escrow,
      card: card ?? this.card,
      virtualAccount: virtualAccount ?? this.virtualAccount,
      transfer: transfer ?? this.transfer,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      giftCertificate: giftCertificate ?? this.giftCertificate,
      easyPay: easyPay ?? this.easyPay,
      discount: discount ?? this.discount,
      cardInstallment: cardInstallment ?? this.cardInstallment,
      country: country ?? this.country,
      failure: failure ?? this.failure,
      cancels: cancels ?? this.cancels,
      cashReceipts: cashReceipts ?? this.cashReceipts,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      transactionKey: transactionKey ?? this.transactionKey,
      lastTransactionKey: lastTransactionKey ?? this.lastTransactionKey,
    );
  }

  // JSON 변환 헬퍼 메서드들
  static PaymentStatus _paymentStatusFromJson(String? value) =>
      value != null ? PaymentStatus.fromString(value) : PaymentStatus.ready;

  static String? _paymentStatusToJson(PaymentStatus status) => status.value;

  static PaymentMethod? _paymentMethodFromJson(String? value) =>
      value != null ? PaymentMethod.fromString(value) : null;

  static String? _paymentMethodToJson(PaymentMethod? method) =>
      method?.apiValue;

  static DateTime? _dateTimeFromJson(String? value) =>
      value != null ? DateTime.parse(value) : null;

  static String? _dateTimeToJson(DateTime? dateTime) =>
      dateTime?.toIso8601String();
}

/// 📦 주문 상품 정보 (서브컬렉션)
///
/// orders/{orderId}/ordered_products/{id} 경로에 저장됩니다.
@JsonSerializable()
class OrderedProduct extends Equatable {
  /// 상품 ID (참조용)
  final String productId;

  /// 주문 당시 상품명 (보존)
  final String productName;

  /// 주문 당시 상품 설명 (보존)
  final String productDescription;

  /// 주문 당시 상품 이미지 URL (보존)
  final String productImageUrl;

  /// 주문 당시 단가 (보존)
  final int unitPrice;

  /// 주문 수량
  final int quantity;

  /// 총 금액 (unitPrice * quantity)
  final int totalPrice;

  /// 배송 타입
  @JsonKey(fromJson: _deliveryTypeFromJson, toJson: _deliveryTypeToJson)
  final DeliveryType deliveryType;

  /// 개별 상품 상태
  @JsonKey(fromJson: _orderItemStatusFromJson, toJson: _orderItemStatusToJson)
  final OrderItemStatus itemStatus;

  /// 픽업 인증 이미지 URL (픽업 상품만)
  final String? pickupImageUrl;

  /// 픽업 인증 완료 여부
  final bool isPickupVerified;

  /// 픽업 인증 완료 시각
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? pickupVerifiedAt;

  const OrderedProduct({
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.deliveryType,
    this.itemStatus = OrderItemStatus.preparing,
    this.pickupImageUrl,
    this.isPickupVerified = false,
    this.pickupVerifiedAt,
  });

  /// JSON으로부터 생성
  factory OrderedProduct.fromJson(Map<String, dynamic> json) =>
      _$OrderedProductFromJson(json);

  /// JSON으로 변환
  Map<String, dynamic> toJson() => _$OrderedProductToJson(this);

  /// Firestore Map으로부터 생성 (호환성)
  factory OrderedProduct.fromMap(Map<String, dynamic> map) =>
      OrderedProduct.fromJson(map);

  /// Firestore Map으로 변환 (호환성)
  Map<String, dynamic> toMap() => toJson();

  /// 픽업 가능 여부
  bool get canPickup =>
      deliveryType == DeliveryType.pickup &&
      itemStatus == OrderItemStatus.ready;

  /// 배송 완료 여부
  bool get isDelivered =>
      deliveryType == DeliveryType.delivery &&
      itemStatus == OrderItemStatus.completed;

  @override
  List<Object?> get props => [
        productId,
        productName,
        productDescription,
        productImageUrl,
        unitPrice,
        quantity,
        totalPrice,
        deliveryType,
        itemStatus,
        pickupImageUrl,
        isPickupVerified,
        pickupVerifiedAt,
      ];

  OrderedProduct copyWith({
    String? productId,
    String? productName,
    String? productDescription,
    String? productImageUrl,
    int? unitPrice,
    int? quantity,
    int? totalPrice,
    DeliveryType? deliveryType,
    OrderItemStatus? itemStatus,
    String? pickupImageUrl,
    bool? isPickupVerified,
    DateTime? pickupVerifiedAt,
  }) {
    return OrderedProduct(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      deliveryType: deliveryType ?? this.deliveryType,
      itemStatus: itemStatus ?? this.itemStatus,
      pickupImageUrl: pickupImageUrl ?? this.pickupImageUrl,
      isPickupVerified: isPickupVerified ?? this.isPickupVerified,
      pickupVerifiedAt: pickupVerifiedAt ?? this.pickupVerifiedAt,
    );
  }

  // JSON 변환 헬퍼 메서드들
  static DeliveryType _deliveryTypeFromJson(String value) =>
      DeliveryType.fromString(value);

  static String _deliveryTypeToJson(DeliveryType type) => type.value;

  static OrderItemStatus _orderItemStatusFromJson(String value) =>
      OrderItemStatus.fromString(value);

  static String _orderItemStatusToJson(OrderItemStatus status) => status.value;

  static DateTime? _timestampFromJson(Timestamp? timestamp) =>
      timestamp?.toDate();

  static Timestamp? _timestampToJson(DateTime? dateTime) =>
      dateTime != null ? Timestamp.fromDate(dateTime) : null;
}

/// 🛒 주문 모델 (메인)
///
/// userId_timestamp 형태의 orderId를 가지며, 전체 주문 정보를 관리합니다.
@JsonSerializable()
class OrderModel extends Equatable {
  /// 주문 ID (userId_timestamp 형태)
  final String orderId;

  /// 주문자 ID
  final String userId;

  /// 주문 상태
  @JsonKey(fromJson: _orderStatusFromJson, toJson: _orderStatusToJson)
  final OrderStatus status;

  // 💰 금액 정보
  /// 상품 총 금액
  final int totalProductAmount;

  /// 배송비 총액
  final int totalDeliveryFee;

  /// 최종 결제 금액
  final int totalAmount;

  // 📍 배송 정보
  /// 배송 주소 (배송 상품이 있을 때만)
  final DeliveryAddress? deliveryAddress;

  // 💳 결제 정보
  /// Toss Payments 결제 정보
  final PaymentInfo? paymentInfo;

  // 📦 픽업 인증 정보
  /// 픽업 인증 이미지 URL (전체 주문용)
  final String? pickupImageUrl;

  /// 픽업 인증 완료 여부
  final bool isPickupVerified;

  /// 픽업 인증 완료 시각
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? pickupVerifiedAt;

  // ⏰ 시간 정보
  /// 주문 생성 시각
  @JsonKey(
      fromJson: _timestampRequiredFromJson, toJson: _timestampRequiredToJson)
  final DateTime createdAt;

  /// 주문 수정 시각
  @JsonKey(
      fromJson: _timestampRequiredFromJson, toJson: _timestampRequiredToJson)
  final DateTime updatedAt;

  // 📝 추가 정보
  /// 주문 메모
  final String? orderNote;

  /// 취소 사유
  final String? cancelReason;

  /// 취소 시각
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? canceledAt;

  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.status,
    required this.totalProductAmount,
    required this.totalDeliveryFee,
    required this.totalAmount,
    this.deliveryAddress,
    this.paymentInfo,
    this.pickupImageUrl,
    this.isPickupVerified = false,
    this.pickupVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.orderNote,
    this.cancelReason,
    this.canceledAt,
  });

  /// JSON으로부터 생성
  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  /// JSON으로 변환
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  /// Firestore Map으로부터 생성 (호환성)
  factory OrderModel.fromMap(Map<String, dynamic> map) =>
      OrderModel.fromJson(map);

  /// Firestore Map으로 변환 (호환성)
  Map<String, dynamic> toMap() => toJson();

  /// userId_timestamp 형태의 orderId 생성
  static String generateOrderId(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${userId}_$timestamp';
  }

  /// 새 주문 생성
  factory OrderModel.create({
    required String userId,
    required int totalProductAmount,
    required int totalDeliveryFee,
    DeliveryAddress? deliveryAddress,
    String? orderNote,
  }) {
    final orderId = generateOrderId(userId);
    final now = DateTime.now();

    return OrderModel(
      orderId: orderId,
      userId: userId,
      status: OrderStatus.pending,
      totalProductAmount: totalProductAmount,
      totalDeliveryFee: totalDeliveryFee,
      totalAmount: totalProductAmount + totalDeliveryFee,
      deliveryAddress: deliveryAddress,
      createdAt: now,
      updatedAt: now,
      orderNote: orderNote,
    );
  }

  /// 다음 상태로 변경 가능한지 확인
  bool canTransitionTo(OrderStatus newStatus) {
    return status.nextStatuses.contains(newStatus);
  }

  /// 취소 가능한지 확인
  bool get isCancellable => status.isCancellable;

  /// 픽업 인증 가능한지 확인
  bool get canVerifyPickup =>
      status == OrderStatus.preparing && !isPickupVerified;

  /// 결제 완료 여부
  bool get isPaymentCompleted => paymentInfo?.isSuccessful == true;

  /// 배송 주문 포함 여부
  bool get hasDeliveryItems => deliveryAddress != null;

  @override
  List<Object?> get props => [
        orderId,
        userId,
        status,
        totalProductAmount,
        totalDeliveryFee,
        totalAmount,
        deliveryAddress,
        paymentInfo,
        pickupImageUrl,
        isPickupVerified,
        pickupVerifiedAt,
        createdAt,
        updatedAt,
        orderNote,
        cancelReason,
        canceledAt,
      ];

  OrderModel copyWith({
    String? orderId,
    String? userId,
    OrderStatus? status,
    int? totalProductAmount,
    int? totalDeliveryFee,
    int? totalAmount,
    DeliveryAddress? deliveryAddress,
    PaymentInfo? paymentInfo,
    String? pickupImageUrl,
    bool? isPickupVerified,
    DateTime? pickupVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? orderNote,
    String? cancelReason,
    DateTime? canceledAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      totalProductAmount: totalProductAmount ?? this.totalProductAmount,
      totalDeliveryFee: totalDeliveryFee ?? this.totalDeliveryFee,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      pickupImageUrl: pickupImageUrl ?? this.pickupImageUrl,
      isPickupVerified: isPickupVerified ?? this.isPickupVerified,
      pickupVerifiedAt: pickupVerifiedAt ?? this.pickupVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      orderNote: orderNote ?? this.orderNote,
      cancelReason: cancelReason ?? this.cancelReason,
      canceledAt: canceledAt ?? this.canceledAt,
    );
  }

  // JSON 변환 헬퍼 메서드들
  static OrderStatus _orderStatusFromJson(String value) =>
      OrderStatus.fromString(value);

  static String _orderStatusToJson(OrderStatus status) => status.value;

  // Nullable DateTime용
  static DateTime? _timestampFromJson(Timestamp? timestamp) =>
      timestamp?.toDate();

  static Timestamp? _timestampToJson(DateTime? dateTime) =>
      dateTime != null ? Timestamp.fromDate(dateTime) : null;

  // Non-nullable DateTime용 (createdAt, updatedAt)
  static DateTime _timestampRequiredFromJson(Timestamp timestamp) =>
      timestamp.toDate();

  static Timestamp _timestampRequiredToJson(DateTime dateTime) =>
      Timestamp.fromDate(dateTime);
}

/// 🎣 웹훅 로그 모델
///
/// Toss Payments에서 오는 모든 웹훅을 로깅합니다.
@JsonSerializable()
class OrderWebhookLog extends Equatable {
  /// 로그 ID
  final String logId;

  /// 관련 주문 ID
  final String orderId;

  /// 웹훅 이벤트 타입
  @JsonKey(fromJson: _webhookEventTypeFromJson, toJson: _webhookEventTypeToJson)
  final WebhookEventType eventType;

  /// 웹훅 원본 데이터
  final Map<String, dynamic> rawPayload;

  /// 처리 상태
  final bool isProcessed;

  /// 처리 결과 메시지
  final String? processResult;

  /// 에러 메시지 (처리 실패 시)
  final String? errorMessage;

  /// 재시도 횟수
  final int retryCount;

  /// 웹훅 수신 시각
  @JsonKey(
      fromJson: _timestampRequiredFromJson, toJson: _timestampRequiredToJson)
  final DateTime receivedAt;

  /// 처리 완료 시각
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? processedAt;

  const OrderWebhookLog({
    required this.logId,
    required this.orderId,
    required this.eventType,
    required this.rawPayload,
    this.isProcessed = false,
    this.processResult,
    this.errorMessage,
    this.retryCount = 0,
    required this.receivedAt,
    this.processedAt,
  });

  /// JSON으로부터 생성
  factory OrderWebhookLog.fromJson(Map<String, dynamic> json) =>
      _$OrderWebhookLogFromJson(json);

  /// JSON으로 변환
  Map<String, dynamic> toJson() => _$OrderWebhookLogToJson(this);

  /// Firestore Map으로부터 생성 (호환성)
  factory OrderWebhookLog.fromMap(Map<String, dynamic> map) =>
      OrderWebhookLog.fromJson(map);

  /// Firestore Map으로 변환 (호환성)
  Map<String, dynamic> toMap() => toJson();

  /// 새 웹훅 로그 생성
  factory OrderWebhookLog.create({
    required String orderId,
    required WebhookEventType eventType,
    required Map<String, dynamic> rawPayload,
  }) {
    final logId = '${orderId}_${DateTime.now().millisecondsSinceEpoch}';

    return OrderWebhookLog(
      logId: logId,
      orderId: orderId,
      eventType: eventType,
      rawPayload: rawPayload,
      receivedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        logId,
        orderId,
        eventType,
        rawPayload,
        isProcessed,
        processResult,
        errorMessage,
        retryCount,
        receivedAt,
        processedAt,
      ];

  OrderWebhookLog copyWith({
    String? logId,
    String? orderId,
    WebhookEventType? eventType,
    Map<String, dynamic>? rawPayload,
    bool? isProcessed,
    String? processResult,
    String? errorMessage,
    int? retryCount,
    DateTime? receivedAt,
    DateTime? processedAt,
  }) {
    return OrderWebhookLog(
      logId: logId ?? this.logId,
      orderId: orderId ?? this.orderId,
      eventType: eventType ?? this.eventType,
      rawPayload: rawPayload ?? this.rawPayload,
      isProcessed: isProcessed ?? this.isProcessed,
      processResult: processResult ?? this.processResult,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      receivedAt: receivedAt ?? this.receivedAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  // JSON 변환 헬퍼 메서드들
  static WebhookEventType _webhookEventTypeFromJson(String value) =>
      WebhookEventType.fromString(value);

  static String _webhookEventTypeToJson(WebhookEventType type) => type.value;

  // Nullable DateTime용
  static DateTime? _timestampFromJson(Timestamp? timestamp) =>
      timestamp?.toDate();

  static Timestamp? _timestampToJson(DateTime? dateTime) =>
      dateTime != null ? Timestamp.fromDate(dateTime) : null;

  // Non-nullable DateTime용 (receivedAt)
  static DateTime _timestampRequiredFromJson(Timestamp timestamp) =>
      timestamp.toDate();

  static Timestamp _timestampRequiredToJson(DateTime dateTime) =>
      Timestamp.fromDate(dateTime);
}
