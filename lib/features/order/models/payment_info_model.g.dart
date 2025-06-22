// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
