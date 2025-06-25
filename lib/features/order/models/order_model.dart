/// Order 주문 모델 정의
///
/// OrderModel, DeliveryAddress, OrderedProduct 등
/// 주문의 핵심 모델들을 포함합니다.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'order_enums.dart';
import 'payment_info_model.dart';
import '../../../core/utils/tax_calculator.dart';
import '../../cart/models/cart_item_model.dart';

part 'order_model.g.dart';

/// 배송 주소 정보
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

  // 🆕 세금 정보
  /// 공급가액 (과세 상품의 VAT 제외 금액)
  final int suppliedAmount;

  /// 부가세
  final int vat;

  /// 면세 금액
  final int taxFreeAmount;

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
    this.suppliedAmount = 0,
    this.vat = 0,
    this.taxFreeAmount = 0,
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

  /// 세금 계산이 포함된 주문 생성
  factory OrderModel.withTaxCalculation({
    required String userId,
    required List<CartItemModel> items,
    required int deliveryFee,
    DeliveryAddress? deliveryAddress,
    String? orderNote,
  }) {
    print('💸 세금 계산 시작 - 상품 ${items.length}개, 배송비 ${deliveryFee}원');

    // 세금 계산 수행
    final taxBreakdown = TaxCalculator.calculateOrderTax(
      items: items,
      deliveryFee: deliveryFee,
    );

    print('💸 세금 계산 결과:');
    print('  - 공급가액: ${taxBreakdown.suppliedAmount}원');
    print('  - 부가세: ${taxBreakdown.vat}원');
    print('  - 면세금액: ${taxBreakdown.taxFreeAmount}원');
    print('  - 총금액: ${taxBreakdown.totalAmount}원');

    // 상품 총액 계산
    int totalProductAmount = 0;
    for (final item in items) {
      totalProductAmount += item.priceSum.round();
      print(
          '  - 상품: ${item.productName}, 면세여부: ${item.isTaxFree}, 금액: ${item.priceSum.round()}원');
    }

    final orderId = generateOrderId(userId);
    final now = DateTime.now();

    print('💸 주문 생성 완료 - OrderID: $orderId');

    return OrderModel(
      orderId: orderId,
      userId: userId,
      status: OrderStatus.pending,
      totalProductAmount: totalProductAmount,
      totalDeliveryFee: deliveryFee,
      totalAmount: taxBreakdown.totalAmount,
      suppliedAmount: taxBreakdown.suppliedAmount,
      vat: taxBreakdown.vat,
      taxFreeAmount: taxBreakdown.taxFreeAmount,
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
        suppliedAmount,
        vat,
        taxFreeAmount,
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
    int? suppliedAmount,
    int? vat,
    int? taxFreeAmount,
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
      suppliedAmount: suppliedAmount ?? this.suppliedAmount,
      vat: vat ?? this.vat,
      taxFreeAmount: taxFreeAmount ?? this.taxFreeAmount,
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
