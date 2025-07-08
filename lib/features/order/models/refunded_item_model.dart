/// 환불 상품 아이템 모델
///
/// 개별 환불 상품 정보를 저장하는 모델입니다.
/// RefundModel에서 refundedItems 필드의 요소로 사용됩니다.

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'refunded_item_model.g.dart';

/// 📦 환불 상품 아이템
///
/// 환불 요청 시 선택된 개별 상품의 정보를 저장합니다.
@JsonSerializable()
class RefundedItemModel extends Equatable {
  /// 장바구니 아이템 ID (OrderedProduct와 매칭용)
  final String cartItemId;

  /// 상품 ID
  final String productId;

  /// 상품명 (주문 당시 상품명)
  final String productName;

  /// 상품 이미지 URL
  final String? productImageUrl;

  /// 주문 당시 단가
  final int unitPrice;

  /// 주문된 총 수량 (참조용)
  final int orderedQuantity;

  /// 환불 요청 수량
  final int refundQuantity;

  /// 개별 상품 환불 금액 (unitPrice * refundQuantity)
  final int totalRefundAmount;

  /// 면세 여부
  final bool isTaxFree;

  const RefundedItemModel({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.unitPrice,
    required this.orderedQuantity,
    required this.refundQuantity,
    required this.totalRefundAmount,
    this.isTaxFree = false,
  });

  /// JSON으로부터 생성
  factory RefundedItemModel.fromJson(Map<String, dynamic> json) =>
      _$RefundedItemModelFromJson(json);

  /// JSON으로 변환
  Map<String, dynamic> toJson() => _$RefundedItemModelToJson(this);

  /// Firestore Map으로부터 생성 (호환성)
  factory RefundedItemModel.fromMap(Map<String, dynamic> map) =>
      RefundedItemModel.fromJson(map);

  /// Firestore Map으로 변환 (호환성)
  Map<String, dynamic> toMap() => toJson();

  /// OrderedProduct로부터 RefundedItemModel 생성
  factory RefundedItemModel.fromOrderedProduct({
    required String cartItemId,
    required String productId,
    required String productName,
    String? productImageUrl,
    required int unitPrice,
    required int orderedQuantity,
    required int refundQuantity,
    bool isTaxFree = false,
  }) {
    return RefundedItemModel(
      cartItemId: cartItemId,
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      unitPrice: unitPrice,
      orderedQuantity: orderedQuantity,
      refundQuantity: refundQuantity,
      totalRefundAmount: unitPrice * refundQuantity,
      isTaxFree: isTaxFree,
    );
  }

  /// 부분 환불인지 확인
  bool get isPartialRefund => refundQuantity < orderedQuantity;

  /// 전체 환불인지 확인
  bool get isFullRefund => refundQuantity == orderedQuantity;

  /// 환불 비율 (0.0 ~ 1.0)
  double get refundRatio => refundQuantity / orderedQuantity;

  @override
  List<Object?> get props => [
        cartItemId,
        productId,
        productName,
        productImageUrl,
        unitPrice,
        orderedQuantity,
        refundQuantity,
        totalRefundAmount,
        isTaxFree,
      ];

  RefundedItemModel copyWith({
    String? cartItemId,
    String? productId,
    String? productName,
    String? productImageUrl,
    int? unitPrice,
    int? orderedQuantity,
    int? refundQuantity,
    int? totalRefundAmount,
    bool? isTaxFree,
  }) {
    return RefundedItemModel(
      cartItemId: cartItemId ?? this.cartItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      orderedQuantity: orderedQuantity ?? this.orderedQuantity,
      refundQuantity: refundQuantity ?? this.refundQuantity,
      totalRefundAmount: totalRefundAmount ?? this.totalRefundAmount,
      isTaxFree: isTaxFree ?? this.isTaxFree,
    );
  }
}
