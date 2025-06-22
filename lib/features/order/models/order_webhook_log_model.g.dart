// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_webhook_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
