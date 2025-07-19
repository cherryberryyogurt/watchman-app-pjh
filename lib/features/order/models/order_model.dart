/// Order 주문 모델 정의
///
/// OrderModel, DeliveryAddress, OrderedProduct 등
/// 주문의 핵심 모델들을 포함합니다.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

import 'order_enums.dart';
import 'payment_info_model.dart';
import '../../../core/utils/tax_calculator.dart';
import '../../cart/models/cart_item_model.dart';
import 'package:gonggoo_app/features/location/models/pickup_point_model.dart';

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
  /// 장바구니 아이템 ID (참조용)
  final String cartItemId;

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

  /// 면세 여부
  final bool isTaxFree;

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
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.deliveryType,
    this.isTaxFree = false,
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
        cartItemId,
        productId,
        productName,
        productDescription,
        productImageUrl,
        unitPrice,
        quantity,
        totalPrice,
        deliveryType,
        isTaxFree,
        itemStatus,
        pickupImageUrl,
        isPickupVerified,
        pickupVerifiedAt,
      ];

  OrderedProduct copyWith({
    String? cartItemId,
    String? productId,
    String? productName,
    String? productDescription,
    String? productImageUrl,
    int? unitPrice,
    int? quantity,
    int? totalPrice,
    DeliveryType? deliveryType,
    bool? isTaxFree,
    OrderItemStatus? itemStatus,
    String? pickupImageUrl,
    bool? isPickupVerified,
    DateTime? pickupVerifiedAt,
  }) {
    return OrderedProduct(
      cartItemId: cartItemId ?? this.cartItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      deliveryType: deliveryType ?? this.deliveryType,
      isTaxFree: isTaxFree ?? this.isTaxFree,
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

  // --📝 주문자 정보--
  /// 주문자 ID
  final String userId;

  /// 주문자 이름
  final String userName;

  /// 주문자 연락처
  final String? userContact;

  // --📦 주문 상태--
  @JsonKey(fromJson: _orderStatusFromJson, toJson: _orderStatusToJson)
  final OrderStatus status;

  // --🚚 주문 배송 타입--
  @JsonKey(fromJson: _deliveryTypeFromJson, toJson: _deliveryTypeToJson)
  final DeliveryType deliveryType; // 배송 타입 (택배, 픽업)

  // --💰 금액 정보--
  /// 상품 총 금액 (상품 가격 * 수량)
  final int totalProductAmount;

  /// 배송비 총액 (도서산간 지역에만 배송비 발생)
  final int totalDeliveryFee;

  /// 최종 결제 금액 (상품 총 금액 + 배송비)
  final int totalAmount;

  // --📦 상품 요약 정보--
  /// 대표 상품명 (첫 번째 상품명)
  final String? representativeProductName;

  /// 전체 상품 개수 (수량 합계)
  final int totalProductCount;

  // --🆕 세금 정보--
  /// 공급가액 (과세 상품의 VAT 제외 금액)
  final int suppliedAmount;

  /// 부가세
  final int vat;

  /// 면세 금액
  final int taxFreeAmount;

  // --📍 배송 정보--
  /// 배송 주소 (배송 상품이 있을 때만)
  final DeliveryAddress? deliveryAddress;

  /// 🆕 선택된 픽업 지점 정보
  final Map<String, dynamic>? selectedPickupPointInfo;

  // --💳 결제 정보--
  /// Toss Payments 결제 정보
  final PaymentInfo? paymentInfo;

  // --📦 픽업 인증 정보--
  /// 픽업 인증 이미지 URL (전체 주문용)
  final String? pickupImageUrl;

  /// 픽업 인증 완료 여부
  final bool isPickupVerified;

  /// 픽업 인증 완료 시각
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? pickupVerifiedAt;

  // --⏰ 시간 정보--
  /// 주문 생성 시각
  @JsonKey(
      fromJson: _timestampRequiredFromJson, toJson: _timestampRequiredToJson)
  final DateTime createdAt;

  /// 주문 수정 시각
  @JsonKey(
      fromJson: _timestampRequiredFromJson, toJson: _timestampRequiredToJson)
  final DateTime updatedAt;

  // --📝 추가 정보--
  /// 주문 메모
  final String? orderNote;

  /// 취소 사유
  final String? cancelReason;

  /// 취소 시각
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? canceledAt;

  // --🚚 택배사 정보--
  /// 택배사 이름
  final String? deliveryCompanyName;

  /// 운송장 번호
  final String? trackingNumber;

  /// 🆕 위치 태그
  final String? locationTagName;
  final String? locationTagId;

  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.userName,
    this.userContact,
    required this.status,
    required this.deliveryType,
    required this.totalProductAmount,
    required this.totalDeliveryFee,
    required this.totalAmount,
    this.suppliedAmount = 0,
    this.vat = 0,
    this.taxFreeAmount = 0,
    this.deliveryAddress,
    this.selectedPickupPointInfo,
    this.paymentInfo,
    this.pickupImageUrl,
    this.isPickupVerified = false,
    this.pickupVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.orderNote,
    this.cancelReason,
    this.canceledAt,
    this.representativeProductName,
    this.totalProductCount = 0,
    this.deliveryCompanyName,
    this.trackingNumber,
    this.locationTagName,
    this.locationTagId,
  });

  /// JSON으로부터 생성
  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  /// JSON으로 변환
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  /// Firestore Map으로부터 생성 (호환성)
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    try {
      // 🛡️ 필수 필드 검증 및 기본값 설정
      final String orderId = map['orderId'] ?? '';
      final String userId = map['userId'] ?? '';
      final String statusValue = map['status'] ?? 'pending';

      // 필수 필드가 비어있으면 예외 발생
      if (orderId.isEmpty) {
        throw Exception('orderId is required but empty or null');
      }
      if (userId.isEmpty) {
        throw Exception('userId is required but empty or null');
      }

      // 🚚 DeliveryAddress 변환 처리 (데이터 불일치 보정)
      DeliveryAddress? deliveryAddress;
      if (map['deliveryAddress'] != null &&
          map['deliveryAddress'] is Map<String, dynamic>) {
        try {
          final deliveryMap = Map<String, dynamic>.from(map['deliveryAddress']);

          // ❗️ 데이터 불일치 해결: 최상위 필드에서 수령인 정보를 가져와 주입
          deliveryMap['recipientName'] =
              map['recipientName'] ?? deliveryMap['recipientName'] ?? '이름 없음';
          deliveryMap['recipientPhone'] =
              map['recipientPhone'] ?? deliveryMap['recipientPhone'] ?? '번호 없음';

          deliveryAddress = DeliveryAddress.fromMap(deliveryMap);
        } catch (e) {
          debugPrint(
              '❌ DeliveryAddress 변환 실패: $e, 데이터: ${map['deliveryAddress']}');
          deliveryAddress = null;
        }
      }

      // 🔄 PaymentInfo 변환 처리
      PaymentInfo? paymentInfo;
      if (map['paymentInfo'] != null) {
        try {
          if (map['paymentInfo'] is Map<String, dynamic>) {
            // PaymentInfo에 필요한 orderId와 totalAmount 주입
            final paymentInfoMap = Map<String, dynamic>.from(
                map['paymentInfo'] as Map<String, dynamic>);

            // orderId가 없으면 주문의 orderId 사용
            if (!paymentInfoMap.containsKey('orderId') ||
                paymentInfoMap['orderId'] == null) {
              paymentInfoMap['orderId'] = orderId;
            }

            // totalAmount가 없으면 주문의 totalAmount 사용
            if (!paymentInfoMap.containsKey('totalAmount') ||
                paymentInfoMap['totalAmount'] == null) {
              paymentInfoMap['totalAmount'] = map['totalAmount'] ?? 0;
            }

            // status가 없으면 기본값 설정 (confirmed 주문이므로 DONE)
            if (!paymentInfoMap.containsKey('status') ||
                paymentInfoMap['status'] == null) {
              paymentInfoMap['status'] = 'DONE';
            }

            paymentInfo = PaymentInfo.fromMap(paymentInfoMap);
          } else {
            debugPrint(
                '⚠️ paymentInfo가 Map이 아닙니다: ${map['paymentInfo'].runtimeType}');
          }
        } catch (e) {
          debugPrint('❌ PaymentInfo 변환 실패: $e, 데이터: ${map['paymentInfo']}');
          // PaymentInfo 변환 실패해도 주문 전체가 실패하지 않도록 null로 설정
          paymentInfo = null;
        }
      }

      // 🆕 selectedPickupPointInfo 처리
      final selectedPickupPointInfo =
          map['selectedPickupPointInfo'] as Map<String, dynamic>?;

      // 기본값이 있는 필드들 안전하게 처리
      final Map<String, dynamic> safeMap = {
        'orderId': orderId,
        'userId': userId,
        'userName': map['userName'] ?? '이름 없음', // 🆕 사용자 이름 추가
        'userContact': map['userContact'], // 🆕 사용자 연락처 추가 (nullable)
        'status': statusValue,
        'deliveryType':
            map['deliveryType'] ?? 'pickup', // 🆕 배송 타입 추가 (기본값: pickup)
        'totalProductAmount': map['totalProductAmount'] ?? 0,
        'totalDeliveryFee': map['totalDeliveryFee'] ?? 0,
        'totalAmount': map['totalAmount'] ?? 0,
        // 🆕 새로 추가된 필드들에 기본값 제공
        'suppliedAmount': map['suppliedAmount'] ?? 0,
        'vat': map['vat'] ?? 0,
        'taxFreeAmount': map['taxFreeAmount'] ?? 0,
        'totalProductCount': map['totalProductCount'] ?? 0,
        'isPickupVerified': map['isPickupVerified'] ?? false,
        // Nullable 필드들
        'deliveryAddress': deliveryAddress?.toMap(), // ★ 수정된 deliveryAddress 사용
        'selectedPickupPointInfo': selectedPickupPointInfo,
        'pickupImageUrl': map['pickupImageUrl'],
        'pickupVerifiedAt': map['pickupVerifiedAt'],
        'createdAt': map['createdAt'],
        'updatedAt': map['updatedAt'],
        'orderNote': map['orderNote'],
        'cancelReason': map['cancelReason'],
        'canceledAt': map['canceledAt'],
        'representativeProductName': map['representativeProductName'],
        // 🚚 택배사 정보 추가
        'deliveryCompanyName': map['deliveryCompanyName'],
        'trackingNumber': map['trackingNumber'],
        // 🆕 위치 태그 추가
        'locationTag': map['locationTag'],
        // 'paymentInfo'는 최종적으로 copyWith를 통해 설정하므로 여기서 제외
      };

      // PaymentInfo는 별도로 처리했으므로 제외하고 fromJson 호출
      final order = OrderModel.fromJson(safeMap);

      // 최종적으로 paymentInfo, deliveryAddress, selectedPickupPointInfo를 설정하여 반환
      return order.copyWith(
        paymentInfo: paymentInfo,
        deliveryAddress: deliveryAddress,
        selectedPickupPointInfo: selectedPickupPointInfo,
      );
    } catch (e) {
      debugPrint('❌ OrderModel.fromMap 에러: $e');
      debugPrint('❌ 입력 데이터: $map');
      rethrow;
    }
  }

  /// Firestore Map으로 변환 (호환성)
  Map<String, dynamic> toMap() => toJson();

  /// 🆕 선택된 픽업 지점 정보를 모델 객체로 변환
  PickupPointModel? get selectedPickupPoint {
    if (selectedPickupPointInfo == null) return null;
    try {
      // PickupPointModel.fromMap은 ID를 별도로 받으므로, 맵에서 ID를 추출하여 전달
      return PickupPointModel.fromMap(selectedPickupPointInfo!,
          selectedPickupPointInfo!['id'] as String? ?? '');
    } catch (e) {
      debugPrint(
          'Error converting selectedPickupPointInfo to PickupPointModel: $e');
      return null;
    }
  }

  /// userId_timestamp 형태의 orderId 생성
  static String generateOrderId(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${userId}_$timestamp';
  }

  /// 새 주문 생성
  factory OrderModel.create({
    required String userId,
    required String userName,
    String? userContact,
    required int totalProductAmount,
    required int totalDeliveryFee,
    DeliveryType deliveryType = DeliveryType.pickup,
    DeliveryAddress? deliveryAddress,
    String? orderNote,
    String? representativeProductName,
    int totalProductCount = 0,
    Map<String, dynamic>? selectedPickupPointInfo,
    String? locationTagName,
    String? locationTagId,
  }) {
    final orderId = generateOrderId(userId);
    final now = DateTime.now();

    return OrderModel(
      orderId: orderId,
      userId: userId,
      userName: userName,
      userContact: userContact,
      status: OrderStatus.pending,
      deliveryType: deliveryType,
      totalProductAmount: totalProductAmount,
      totalDeliveryFee: totalDeliveryFee,
      totalAmount: totalProductAmount + totalDeliveryFee,
      deliveryAddress: deliveryAddress,
      selectedPickupPointInfo: selectedPickupPointInfo,
      createdAt: now,
      updatedAt: now,
      orderNote: orderNote,
      representativeProductName: representativeProductName,
      totalProductCount: totalProductCount,
      locationTagName: locationTagName,
      locationTagId: locationTagId,
    );
  }

  /// 세금 계산이 포함된 주문 생성
  factory OrderModel.withTaxCalculation({
    required String userId,
    required String userName,
    String? userContact,
    required List<CartItemModel> items,
    required int deliveryFee,
    required String deliveryType, // 사용자가 선택한 배송 유형
    DeliveryAddress? deliveryAddress,
    String? orderNote,
    String? representativeProductName,
    int totalProductCount = 0,
    Map<String, dynamic>? selectedPickupPointInfo,
    String? locationTagName,
    String? locationTagId,
  }) {
    print('💸 세금 계산 시작 - 상품 ${items.length}개, 배송비 ${deliveryFee}원');

    // 🚚 주문 배송 타입 결정 로직 (사용자 선택 기준)
    // 사용자가 선택한 배송 유형을 우선적으로 사용
    DeliveryType orderDeliveryType;
    switch (deliveryType) {
      case '배송':
      case '택배':
        orderDeliveryType = DeliveryType.delivery;
        break;
      case '픽업':
        orderDeliveryType = DeliveryType.pickup;
        break;
      default:
        // 기본값으로 첫 번째 상품의 배송 유형 사용
        orderDeliveryType = items.first.productDeliveryType == 'delivery'
            ? DeliveryType.delivery
            : DeliveryType.pickup;
    }

    print(
        '🚚 주문 배송 타입 결정: ${orderDeliveryType.displayName} (사용자 선택: $deliveryType)');

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
          '  - 상품: ${item.productName}, 면세여부: ${item.isTaxFree}, 배송타입: ${item.productDeliveryType}, 금액: ${item.priceSum.round()}원');
    }

    final orderId = generateOrderId(userId);
    final now = DateTime.now();

    print(
        '💸 주문 생성 완료 - OrderID: $orderId, 배송타입: ${orderDeliveryType.displayName}');

    return OrderModel(
      orderId: orderId,
      userId: userId,
      userName: userName,
      userContact: userContact,
      status: OrderStatus.pending,
      deliveryType: orderDeliveryType,
      totalProductAmount: totalProductAmount,
      totalDeliveryFee: deliveryFee,
      totalAmount: taxBreakdown.totalAmount,
      suppliedAmount: taxBreakdown.suppliedAmount,
      vat: taxBreakdown.vat,
      taxFreeAmount: taxBreakdown.taxFreeAmount,
      deliveryAddress: deliveryAddress,
      selectedPickupPointInfo: selectedPickupPointInfo,
      createdAt: now,
      updatedAt: now,
      orderNote: orderNote,
      representativeProductName: representativeProductName,
      totalProductCount: totalProductCount,
      locationTagName: locationTagName,
      locationTagId: locationTagId,
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
        userName,
        userContact,
        status,
        deliveryType,
        totalProductAmount,
        totalDeliveryFee,
        totalAmount,
        suppliedAmount,
        vat,
        taxFreeAmount,
        deliveryAddress,
        selectedPickupPointInfo,
        paymentInfo,
        pickupImageUrl,
        isPickupVerified,
        pickupVerifiedAt,
        createdAt,
        updatedAt,
        orderNote,
        cancelReason,
        canceledAt,
        representativeProductName,
        totalProductCount,
        deliveryCompanyName,
        trackingNumber,
        locationTagName,
        locationTagId,
      ];

  OrderModel copyWith({
    String? orderId,
    String? userId,
    String? userName,
    String? userContact,
    OrderStatus? status,
    DeliveryType? deliveryType,
    int? totalProductAmount,
    int? totalDeliveryFee,
    int? totalAmount,
    int? suppliedAmount,
    int? vat,
    int? taxFreeAmount,
    DeliveryAddress? deliveryAddress,
    Map<String, dynamic>? selectedPickupPointInfo,
    PaymentInfo? paymentInfo,
    String? pickupImageUrl,
    bool? isPickupVerified,
    DateTime? pickupVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? orderNote,
    String? cancelReason,
    DateTime? canceledAt,
    String? representativeProductName,
    int? totalProductCount,
    String? deliveryCompanyName,
    String? trackingNumber,
    String? locationTagName,
    String? locationTagId,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userContact: userContact ?? this.userContact,
      status: status ?? this.status,
      deliveryType: deliveryType ?? this.deliveryType,
      totalProductAmount: totalProductAmount ?? this.totalProductAmount,
      totalDeliveryFee: totalDeliveryFee ?? this.totalDeliveryFee,
      totalAmount: totalAmount ?? this.totalAmount,
      suppliedAmount: suppliedAmount ?? this.suppliedAmount,
      vat: vat ?? this.vat,
      taxFreeAmount: taxFreeAmount ?? this.taxFreeAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      selectedPickupPointInfo:
          selectedPickupPointInfo ?? this.selectedPickupPointInfo,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      pickupImageUrl: pickupImageUrl ?? this.pickupImageUrl,
      isPickupVerified: isPickupVerified ?? this.isPickupVerified,
      pickupVerifiedAt: pickupVerifiedAt ?? this.pickupVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      orderNote: orderNote ?? this.orderNote,
      cancelReason: cancelReason ?? this.cancelReason,
      canceledAt: canceledAt ?? this.canceledAt,
      representativeProductName:
          representativeProductName ?? this.representativeProductName,
      totalProductCount: totalProductCount ?? this.totalProductCount,
      deliveryCompanyName: deliveryCompanyName ?? this.deliveryCompanyName,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      locationTagName: locationTagName ?? this.locationTagName,
      locationTagId: locationTagId ?? this.locationTagId,
    );
  }

  // JSON 변환 헬퍼 메서드들
  static OrderStatus _orderStatusFromJson(String value) =>
      OrderStatus.fromString(value);

  static String _orderStatusToJson(OrderStatus status) => status.value;

  static DeliveryType _deliveryTypeFromJson(String value) =>
      DeliveryType.fromString(value);

  static String _deliveryTypeToJson(DeliveryType type) => type.value;

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
