// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refund_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefundModel _$RefundModelFromJson(Map<String, dynamic> json) => RefundModel(
      refundId: json['refundId'] as String,
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      status: RefundModel._refundStatusFromJson(json['status'] as String),
      type: RefundModel._refundTypeFromJson(json['type'] as String),
      refundAmount: (json['refundAmount'] as num).toInt(),
      actualRefundAmount: (json['actualRefundAmount'] as num?)?.toInt(),
      originalOrderAmount: (json['originalOrderAmount'] as num).toInt(),
      refundFee: (json['refundFee'] as num?)?.toInt() ?? 0,
      refundReason: json['refundReason'] as String,
      adminNotes: json['adminNotes'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      paymentMethod:
          RefundModel._paymentMethodFromJson(json['paymentMethod'] as String),
      paymentKey: json['paymentKey'] as String?,
      providerRefundId: json['providerRefundId'] as String?,
      refundBankName: json['refundBankName'] as String?,
      refundAccountNumber: json['refundAccountNumber'] as String?,
      refundAccountHolder: json['refundAccountHolder'] as String?,
      requestedAt: RefundModel._timestampRequiredFromJson(
          json['requestedAt'] as Timestamp),
      approvedAt:
          RefundModel._timestampFromJson(json['approvedAt'] as Timestamp?),
      processingStartedAt: RefundModel._timestampFromJson(
          json['processingStartedAt'] as Timestamp?),
      completedAt:
          RefundModel._timestampFromJson(json['completedAt'] as Timestamp?),
      updatedAt: RefundModel._timestampRequiredFromJson(
          json['updatedAt'] as Timestamp),
      processedByAdminId: json['processedByAdminId'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastErrorMessage: json['lastErrorMessage'] as String?,
      processingDurationSeconds:
          (json['processingDurationSeconds'] as num?)?.toInt(),
      clientInfo: json['clientInfo'] as Map<String, dynamic>?,
      providerResponse: json['providerResponse'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$RefundModelToJson(RefundModel instance) =>
    <String, dynamic>{
      'refundId': instance.refundId,
      'orderId': instance.orderId,
      'userId': instance.userId,
      'status': RefundModel._refundStatusToJson(instance.status),
      'type': RefundModel._refundTypeToJson(instance.type),
      'refundAmount': instance.refundAmount,
      'actualRefundAmount': instance.actualRefundAmount,
      'originalOrderAmount': instance.originalOrderAmount,
      'refundFee': instance.refundFee,
      'refundReason': instance.refundReason,
      'adminNotes': instance.adminNotes,
      'rejectionReason': instance.rejectionReason,
      'paymentMethod': RefundModel._paymentMethodToJson(instance.paymentMethod),
      'paymentKey': instance.paymentKey,
      'providerRefundId': instance.providerRefundId,
      'refundBankName': instance.refundBankName,
      'refundAccountNumber': instance.refundAccountNumber,
      'refundAccountHolder': instance.refundAccountHolder,
      'requestedAt': RefundModel._timestampRequiredToJson(instance.requestedAt),
      'approvedAt': RefundModel._timestampToJson(instance.approvedAt),
      'processingStartedAt':
          RefundModel._timestampToJson(instance.processingStartedAt),
      'completedAt': RefundModel._timestampToJson(instance.completedAt),
      'updatedAt': RefundModel._timestampRequiredToJson(instance.updatedAt),
      'processedByAdminId': instance.processedByAdminId,
      'idempotencyKey': instance.idempotencyKey,
      'retryCount': instance.retryCount,
      'lastErrorMessage': instance.lastErrorMessage,
      'processingDurationSeconds': instance.processingDurationSeconds,
      'clientInfo': instance.clientInfo,
      'providerResponse': instance.providerResponse,
    };
