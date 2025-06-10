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

PaymentInfo _$PaymentInfoFromJson(Map<String, dynamic> json) => PaymentInfo(
      paymentKey: json['paymentKey'] as String?,
      orderId: json['orderId'] as String,
      status: PaymentInfo._paymentStatusFromJson(json['status'] as String?),
      totalAmount: (json['totalAmount'] as num).toInt(),
      balanceAmount: (json['balanceAmount'] as num?)?.toInt(),
      suppliedAmount: (json['suppliedAmount'] as num?)?.toInt(),
      vat: (json['vat'] as num?)?.toInt(),
      taxFreeAmount: (json['taxFreeAmount'] as num?)?.toInt(),
      orderName: json['orderName'] as String?,
      mId: json['mId'] as String?,
      version: json['version'] as String?,
      method: PaymentInfo._paymentMethodFromJson(json['method'] as String?),
      requestedAt:
          PaymentInfo._dateTimeFromJson(json['requestedAt'] as String?),
      approvedAt: PaymentInfo._dateTimeFromJson(json['approvedAt'] as String?),
      cultureExpense: (json['cultureExpense'] as num?)?.toInt(),
      useEscrow: json['useEscrow'] as bool?,
      cashReceipt: json['cashReceipt'] as Map<String, dynamic>?,
      escrow: json['escrow'] as Map<String, dynamic>?,
      card: json['card'] as Map<String, dynamic>?,
      virtualAccount: json['virtualAccount'] as Map<String, dynamic>?,
      transfer: json['transfer'] as Map<String, dynamic>?,
      mobilePhone: json['mobilePhone'] as Map<String, dynamic>?,
      giftCertificate: json['giftCertificate'] as Map<String, dynamic>?,
      easyPay: json['easyPay'] as Map<String, dynamic>?,
      discount: json['discount'] as Map<String, dynamic>?,
      cardInstallment: json['cardInstallment'] as Map<String, dynamic>?,
      country: json['country'] as String?,
      failure: json['failure'] as Map<String, dynamic>?,
      cancels: (json['cancels'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      cashReceipts: (json['cashReceipts'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      receiptUrl: json['receiptUrl'] as String?,
      checkoutUrl: json['checkoutUrl'] as String?,
      transactionKey: json['transactionKey'] as String?,
      lastTransactionKey: json['lastTransactionKey'] as String?,
    );

Map<String, dynamic> _$PaymentInfoToJson(PaymentInfo instance) =>
    <String, dynamic>{
      'paymentKey': instance.paymentKey,
      'orderId': instance.orderId,
      'status': PaymentInfo._paymentStatusToJson(instance.status),
      'totalAmount': instance.totalAmount,
      'balanceAmount': instance.balanceAmount,
      'suppliedAmount': instance.suppliedAmount,
      'vat': instance.vat,
      'taxFreeAmount': instance.taxFreeAmount,
      'orderName': instance.orderName,
      'mId': instance.mId,
      'version': instance.version,
      'method': PaymentInfo._paymentMethodToJson(instance.method),
      'requestedAt': PaymentInfo._dateTimeToJson(instance.requestedAt),
      'approvedAt': PaymentInfo._dateTimeToJson(instance.approvedAt),
      'cultureExpense': instance.cultureExpense,
      'useEscrow': instance.useEscrow,
      'cashReceipt': instance.cashReceipt,
      'escrow': instance.escrow,
      'card': instance.card,
      'virtualAccount': instance.virtualAccount,
      'transfer': instance.transfer,
      'mobilePhone': instance.mobilePhone,
      'giftCertificate': instance.giftCertificate,
      'easyPay': instance.easyPay,
      'discount': instance.discount,
      'cardInstallment': instance.cardInstallment,
      'country': instance.country,
      'failure': instance.failure,
      'cancels': instance.cancels,
      'cashReceipts': instance.cashReceipts,
      'receiptUrl': instance.receiptUrl,
      'checkoutUrl': instance.checkoutUrl,
      'transactionKey': instance.transactionKey,
      'lastTransactionKey': instance.lastTransactionKey,
    };

OrderedProduct _$OrderedProductFromJson(Map<String, dynamic> json) =>
    OrderedProduct(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productDescription: json['productDescription'] as String,
      productImageUrl: json['productImageUrl'] as String,
      unitPrice: (json['unitPrice'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      totalPrice: (json['totalPrice'] as num).toInt(),
      deliveryType:
          OrderedProduct._deliveryTypeFromJson(json['deliveryType'] as String),
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
      'productId': instance.productId,
      'productName': instance.productName,
      'productDescription': instance.productDescription,
      'productImageUrl': instance.productImageUrl,
      'unitPrice': instance.unitPrice,
      'quantity': instance.quantity,
      'totalPrice': instance.totalPrice,
      'deliveryType': OrderedProduct._deliveryTypeToJson(instance.deliveryType),
      'itemStatus': OrderedProduct._orderItemStatusToJson(instance.itemStatus),
      'pickupImageUrl': instance.pickupImageUrl,
      'isPickupVerified': instance.isPickupVerified,
      'pickupVerifiedAt':
          OrderedProduct._timestampToJson(instance.pickupVerifiedAt),
    };

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      status: OrderModel._orderStatusFromJson(json['status'] as String),
      totalProductAmount: (json['totalProductAmount'] as num).toInt(),
      totalDeliveryFee: (json['totalDeliveryFee'] as num).toInt(),
      totalAmount: (json['totalAmount'] as num).toInt(),
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
    );

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'userId': instance.userId,
      'status': OrderModel._orderStatusToJson(instance.status),
      'totalProductAmount': instance.totalProductAmount,
      'totalDeliveryFee': instance.totalDeliveryFee,
      'totalAmount': instance.totalAmount,
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

OrderWebhookLog _$OrderWebhookLogFromJson(Map<String, dynamic> json) =>
    OrderWebhookLog(
      logId: json['logId'] as String,
      orderId: json['orderId'] as String,
      eventType: OrderWebhookLog._webhookEventTypeFromJson(
          json['eventType'] as String),
      rawPayload: json['rawPayload'] as Map<String, dynamic>,
      isProcessed: json['isProcessed'] as bool? ?? false,
      processResult: json['processResult'] as String?,
      errorMessage: json['errorMessage'] as String?,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      receivedAt: OrderWebhookLog._timestampRequiredFromJson(
          json['receivedAt'] as Timestamp),
      processedAt:
          OrderWebhookLog._timestampFromJson(json['processedAt'] as Timestamp?),
    );

Map<String, dynamic> _$OrderWebhookLogToJson(OrderWebhookLog instance) =>
    <String, dynamic>{
      'logId': instance.logId,
      'orderId': instance.orderId,
      'eventType': OrderWebhookLog._webhookEventTypeToJson(instance.eventType),
      'rawPayload': instance.rawPayload,
      'isProcessed': instance.isProcessed,
      'processResult': instance.processResult,
      'errorMessage': instance.errorMessage,
      'retryCount': instance.retryCount,
      'receivedAt':
          OrderWebhookLog._timestampRequiredToJson(instance.receivedAt),
      'processedAt': OrderWebhookLog._timestampToJson(instance.processedAt),
    };
