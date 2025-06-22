/// 웹훅 로그 모델
///
/// Toss Payments에서 오는 모든 웹훅을 로깅합니다.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'order_enums.dart';

part 'order_webhook_log_model.g.dart';

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
