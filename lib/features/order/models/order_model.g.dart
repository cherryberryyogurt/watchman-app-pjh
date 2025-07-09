// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryAddress _$DeliveryAddressFromJson(Map<String, dynamic> json) =>
    DeliveryAddress(
      recipientName: json['recipientName'] as String,
      recipientPhone: json['recipientPhone'] as String,
      postalCode: json['postalCode'] as String,
      address: json['address'] as String,
      detailAddress: json['detailAddress'] as String,
      deliveryNote: json['deliveryNote'] as String?,
    );

Map<String, dynamic> _$DeliveryAddressToJson(DeliveryAddress instance) =>
    <String, dynamic>{
      'recipientName': instance.recipientName,
      'recipientPhone': instance.recipientPhone,
      'postalCode': instance.postalCode,
      'address': instance.address,
      'detailAddress': instance.detailAddress,
      'deliveryNote': instance.deliveryNote,
    };

OrderedProduct _$OrderedProductFromJson(Map<String, dynamic> json) =>
    OrderedProduct(
      cartItemId: json['cartItemId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productDescription: json['productDescription'] as String,
      productImageUrl: json['productImageUrl'] as String,
      unitPrice: (json['unitPrice'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      totalPrice: (json['totalPrice'] as num).toInt(),
      deliveryType:
          OrderedProduct._deliveryTypeFromJson(json['deliveryType'] as String),
      isTaxFree: json['isTaxFree'] as bool? ?? false,
      itemStatus: json['itemStatus'] == null
          ? OrderItemStatus.preparing
          : OrderedProduct._orderItemStatusFromJson(
              json['itemStatus'] as String),
      pickupImageUrl: json['pickupImageUrl'] as String?,
      isPickupVerified: json['isPickupVerified'] as bool? ?? false,
      pickupVerifiedAt: OrderedProduct._timestampFromJson(
          json['pickupVerifiedAt'] as Timestamp?),
    );

Map<String, dynamic> _$OrderedProductToJson(OrderedProduct instance) =>
    <String, dynamic>{
      'cartItemId': instance.cartItemId,
      'productId': instance.productId,
      'productName': instance.productName,
      'productDescription': instance.productDescription,
      'productImageUrl': instance.productImageUrl,
      'unitPrice': instance.unitPrice,
      'quantity': instance.quantity,
      'totalPrice': instance.totalPrice,
      'deliveryType': OrderedProduct._deliveryTypeToJson(instance.deliveryType),
      'isTaxFree': instance.isTaxFree,
      'itemStatus': OrderedProduct._orderItemStatusToJson(instance.itemStatus),
      'pickupImageUrl': instance.pickupImageUrl,
      'isPickupVerified': instance.isPickupVerified,
      'pickupVerifiedAt':
          OrderedProduct._timestampToJson(instance.pickupVerifiedAt),
    };

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userContact: json['userContact'] as String?,
      status: OrderModel._orderStatusFromJson(json['status'] as String),
      deliveryType:
          OrderModel._deliveryTypeFromJson(json['deliveryType'] as String),
      totalProductAmount: (json['totalProductAmount'] as num).toInt(),
      totalDeliveryFee: (json['totalDeliveryFee'] as num).toInt(),
      totalAmount: (json['totalAmount'] as num).toInt(),
      suppliedAmount: (json['suppliedAmount'] as num?)?.toInt() ?? 0,
      vat: (json['vat'] as num?)?.toInt() ?? 0,
      taxFreeAmount: (json['taxFreeAmount'] as num?)?.toInt() ?? 0,
      deliveryAddress: json['deliveryAddress'] == null
          ? null
          : DeliveryAddress.fromJson(
              json['deliveryAddress'] as Map<String, dynamic>),
      paymentInfo: json['paymentInfo'] == null
          ? null
          : PaymentInfo.fromJson(json['paymentInfo'] as Map<String, dynamic>),
      pickupImageUrl: json['pickupImageUrl'] as String?,
      isPickupVerified: json['isPickupVerified'] as bool? ?? false,
      pickupVerifiedAt:
          OrderModel._timestampFromJson(json['pickupVerifiedAt'] as Timestamp?),
      createdAt:
          OrderModel._timestampRequiredFromJson(json['createdAt'] as Timestamp),
      updatedAt:
          OrderModel._timestampRequiredFromJson(json['updatedAt'] as Timestamp),
      orderNote: json['orderNote'] as String?,
      cancelReason: json['cancelReason'] as String?,
      canceledAt:
          OrderModel._timestampFromJson(json['canceledAt'] as Timestamp?),
      representativeProductName: json['representativeProductName'] as String?,
      totalProductCount: (json['totalProductCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'userId': instance.userId,
      'userName': instance.userName,
      'userContact': instance.userContact,
      'status': OrderModel._orderStatusToJson(instance.status),
      'deliveryType': OrderModel._deliveryTypeToJson(instance.deliveryType),
      'totalProductAmount': instance.totalProductAmount,
      'totalDeliveryFee': instance.totalDeliveryFee,
      'totalAmount': instance.totalAmount,
      'representativeProductName': instance.representativeProductName,
      'totalProductCount': instance.totalProductCount,
      'suppliedAmount': instance.suppliedAmount,
      'vat': instance.vat,
      'taxFreeAmount': instance.taxFreeAmount,
      'deliveryAddress': instance.deliveryAddress,
      'paymentInfo': instance.paymentInfo,
      'pickupImageUrl': instance.pickupImageUrl,
      'isPickupVerified': instance.isPickupVerified,
      'pickupVerifiedAt':
          OrderModel._timestampToJson(instance.pickupVerifiedAt),
      'createdAt': OrderModel._timestampRequiredToJson(instance.createdAt),
      'updatedAt': OrderModel._timestampRequiredToJson(instance.updatedAt),
      'orderNote': instance.orderNote,
      'cancelReason': instance.cancelReason,
      'canceledAt': OrderModel._timestampToJson(instance.canceledAt),
    };
