// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refunded_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefundedItemModel _$RefundedItemModelFromJson(Map<String, dynamic> json) =>
    RefundedItemModel(
      cartItemId: json['cartItemId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productImageUrl: json['productImageUrl'] as String?,
      unitPrice: (json['unitPrice'] as num).toInt(),
      orderedQuantity: (json['orderedQuantity'] as num).toInt(),
      refundQuantity: (json['refundQuantity'] as num).toInt(),
      totalRefundAmount: (json['totalRefundAmount'] as num).toInt(),
      isTaxFree: json['isTaxFree'] as bool? ?? false,
    );

Map<String, dynamic> _$RefundedItemModelToJson(RefundedItemModel instance) =>
    <String, dynamic>{
      'cartItemId': instance.cartItemId,
      'productId': instance.productId,
      'productName': instance.productName,
      'productImageUrl': instance.productImageUrl,
      'unitPrice': instance.unitPrice,
      'orderedQuantity': instance.orderedQuantity,
      'refundQuantity': instance.refundQuantity,
      'totalRefundAmount': instance.totalRefundAmount,
      'isTaxFree': instance.isTaxFree,
    };
