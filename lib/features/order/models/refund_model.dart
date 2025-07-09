/// Refund 환불 모델 정의
///
/// 전용 'refunds' 컬렉션을 위한 포괄적인 환불 모델
/// 주문과 독립적으로 관리되며 효율적인 쿼리를 지원합니다.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

import 'order_enums.dart';
import 'refunded_item_model.dart';

part 'refund_model.g.dart';

/// 🔄 환불 상태 관리
///
/// 환불 요청부터 완료까지의 전체 생명주기를 관리합니다.
enum RefundStatus {
  /// 환불 요청됨 (사용자가 요청)
  requested('requested', '환불 요청됨'),

  /// 환불 검토 중 (관리자 확인)
  reviewing('reviewing', '검토 중'),

  /// 환불 승인됨 (처리 대기)
  approved('approved', '승인됨'),

  /// 환불 처리 중 (결제사 처리)
  processing('processing', '처리 중'),

  /// 환불 완료됨
  completed('completed', '환불 완료'),

  /// 환불 거절됨
  rejected('rejected', '환불 거절'),

  /// 환불 실패 (기술적 오류)
  failed('failed', '환불 실패'),

  /// 환불 취소됨 (사용자 취소)
  cancelled('cancelled', '요청 취소');

  const RefundStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  /// String 값으로부터 RefundStatus 생성
  static RefundStatus fromString(String value) {
    return RefundStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Invalid RefundStatus: $value'),
    );
  }

  /// 최종 상태 여부 확인
  bool get isFinal => [completed, rejected, failed, cancelled].contains(this);

  /// 처리 가능한 상태 여부 확인
  bool get isProcessable => [requested, reviewing, approved].contains(this);

  /// 성공 상태 여부 확인
  bool get isSuccessful => this == completed;
}

/// 🏷️ 환불 유형
enum RefundType {
  /// 전액 환불
  full('full', '전액 환불'),

  /// 부분 환불
  partial('partial', '부분 환불');

  const RefundType(this.value, this.displayName);

  final String value;
  final String displayName;

  static RefundType fromString(String value) {
    return RefundType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid RefundType: $value'),
    );
  }
}

/// 💰 환불 모델 (메인)
///
/// 전용 'refunds' 컬렉션에 저장되는 환불 정보입니다.
/// 주문과 독립적으로 관리되며 효율적인 쿼리를 지원합니다.
@JsonSerializable(explicitToJson: true)
class RefundModel extends Equatable {
  /// 환불 ID (자동 생성)
  final String refundId;

  /// 원본 주문 ID (참조)
  final String orderId;

  /// 사용자 ID (참조)
  final String userId;

  /// 사용자 이름 (환불 요청 시점 스냅샷)
  final String userName;

  /// 사용자 연락처 (환불 요청 시점 스냅샷)
  final String userContact;

  /// 환불 상태
  @JsonKey(fromJson: _refundStatusFromJson, toJson: _refundStatusToJson)
  final RefundStatus status;

  /// 환불 유형
  @JsonKey(fromJson: _refundTypeFromJson, toJson: _refundTypeToJson)
  final RefundType type;

  // 💰 금액 정보
  /// 환불 요청 금액
  final int refundAmount;

  /// 실제 환불된 금액 (처리 완료 후 설정)
  final int? actualRefundAmount;

  /// 원본 주문 총액 (참조용)
  final int originalOrderAmount;

  /// 환불 수수료 (있는 경우)
  final int refundFee;

  // 📦 환불 상품 목록 (아이템별 환불)
  /// 환불 요청된 상품 목록 (아이템별 환불 시 사용)
  final List<RefundedItemModel>? refundedItems;

  // 📝 환불 사유 및 상세 정보
  /// 환불 사유 (사용자 입력)
  final String refundReason;

  /// 관리자 메모 (내부용)
  final String? adminNotes;

  /// 거절 사유 (거절 시)
  final String? rejectionReason;

  // 💳 결제 정보 (스냅샷)
  /// 원본 결제 수단
  @JsonKey(fromJson: _paymentMethodFromJson, toJson: _paymentMethodToJson)
  final PaymentMethod paymentMethod;

  /// Toss Payments 결제 키
  final String? paymentKey;

  /// 결제사 환불 ID
  final String? providerRefundId;

  // 💳 환불 계좌 정보 (가상계좌 환불 시)
  /// 환불받을 은행명
  final String? refundBankName;

  /// 환불받을 계좌번호
  final String? refundAccountNumber;

  /// 환불받을 계좌 예금주
  final String? refundAccountHolder;

  /// 환불 요청 시각 (시간 정보::감사 추적)
  @JsonKey(
      fromJson: _timestampRequiredFromJson, toJson: _timestampRequiredToJson)
  final DateTime requestedAt;

  /// 환불 승인 시각
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? approvedAt;

  /// 환불 처리 시작 시각
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? processingStartedAt;

  /// 환불 완료 시각
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? completedAt;

  /// 마지막 업데이트 시각
  @JsonKey(
      fromJson: _timestampRequiredFromJson, toJson: _timestampRequiredToJson)
  final DateTime updatedAt;

  // 🔧 처리 정보
  /// 처리한 관리자 ID
  final String? processedByAdminId;

  /// 멱등키 (중복 방지)
  final String? idempotencyKey;

  /// 재시도 횟수
  final int retryCount;

  /// 마지막 오류 메시지
  final String? lastErrorMessage;

  // 📊 메타데이터
  /// 환불 처리 소요 시간 (초)
  final int? processingDurationSeconds;

  /// 클라이언트 정보 (디버깅용)
  final Map<String, dynamic>? clientInfo;

  /// Toss Payments 응답 데이터 (전체)
  final Map<String, dynamic>? providerResponse;

  // 🆕 세금 분해 정보 (환불 시 정확한 VAT 계산용)
  /// 환불 세금 분해 정보
  final Map<String, dynamic>? taxBreakdown;

  const RefundModel({
    required this.refundId,
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.userContact,
    required this.status,
    required this.type,
    required this.refundAmount,
    this.actualRefundAmount,
    required this.originalOrderAmount,
    this.refundFee = 0,
    this.refundedItems,
    required this.refundReason,
    this.adminNotes,
    this.rejectionReason,
    required this.paymentMethod,
    this.paymentKey,
    this.providerRefundId,
    this.refundBankName,
    this.refundAccountNumber,
    this.refundAccountHolder,
    required this.requestedAt,
    this.approvedAt,
    this.processingStartedAt,
    this.completedAt,
    required this.updatedAt,
    this.processedByAdminId,
    this.idempotencyKey,
    this.retryCount = 0,
    this.lastErrorMessage,
    this.processingDurationSeconds,
    this.clientInfo,
    this.providerResponse,
    this.taxBreakdown,
  });

  /// JSON으로부터 생성
  factory RefundModel.fromJson(Map<String, dynamic> json) =>
      _$RefundModelFromJson(json);

  /// JSON으로 변환
  Map<String, dynamic> toJson() => _$RefundModelToJson(this);

  /// Firestore Map으로부터 생성 (호환성)
  factory RefundModel.fromMap(Map<String, dynamic> map) {
    try {
      // 🛡️ 필수 필드 검증 및 기본값 설정
      final String refundId = map['refundId'] ?? '';
      final String orderId = map['orderId'] ?? '';
      final String userId = map['userId'] ?? '';
      final String userName = map['userName'] ?? '알 수 없음';
      final String userContact = map['userContact'] ?? '알 수 없음';

      if (refundId.isEmpty || orderId.isEmpty || userId.isEmpty) {
        throw Exception('RefundModel: 필수 필드가 누락되었습니다');
      }

      // 기본값이 있는 필드들 안전하게 처리
      final Map<String, dynamic> safeMap = {
        'refundId': refundId,
        'orderId': orderId,
        'userId': userId,
        'userName': userName,
        'userContact': userContact,
        'status': map['status'] ?? 'requested',
        'type': map['type'] ?? 'full',
        'refundAmount': map['refundAmount'] ?? 0,
        'actualRefundAmount': map['actualRefundAmount'],
        'originalOrderAmount': map['originalOrderAmount'] ?? 0,
        'refundFee': map['refundFee'] ?? 0,
        'refundedItems': map['refundedItems'],
        'refundReason': map['refundReason'] ?? '',
        'adminNotes': map['adminNotes'],
        'rejectionReason': map['rejectionReason'],
        'paymentMethod': map['paymentMethod'] ?? 'card',
        'paymentKey': map['paymentKey'],
        'providerRefundId': map['providerRefundId'],
        'refundBankName': map['refundBankName'],
        'refundAccountNumber': map['refundAccountNumber'],
        'refundAccountHolder': map['refundAccountHolder'],
        'requestedAt': map['requestedAt'],
        'approvedAt': map['approvedAt'],
        'processingStartedAt': map['processingStartedAt'],
        'completedAt': map['completedAt'],
        'updatedAt': map['updatedAt'],
        'processedByAdminId': map['processedByAdminId'],
        'idempotencyKey': map['idempotencyKey'],
        'retryCount': map['retryCount'] ?? 0,
        'lastErrorMessage': map['lastErrorMessage'],
        'processingDurationSeconds': map['processingDurationSeconds'],
        'clientInfo': map['clientInfo'],
        'providerResponse': map['providerResponse'],
        'taxBreakdown': map['taxBreakdown'],
      };

      return RefundModel.fromJson(safeMap);
    } catch (e) {
      debugPrint('❌ RefundModel.fromMap 에러: $e');
      debugPrint('❌ 입력 데이터: $map');
      rethrow;
    }
  }

  /// Firestore Map으로 변환 (호환성)
  Map<String, dynamic> toMap() => toJson();

  /// 새 환불 요청 생성
  factory RefundModel.createRequest({
    required String orderId,
    required String userId,
    required String userName,
    required String userContact,
    required int refundAmount,
    required int originalOrderAmount,
    required String refundReason,
    required PaymentMethod paymentMethod,
    String? paymentKey,
    RefundType type = RefundType.full,
    List<RefundedItemModel>? refundedItems,
    String? refundBankName,
    String? refundAccountNumber,
    String? refundAccountHolder,
    String? idempotencyKey,
    Map<String, dynamic>? clientInfo,
  }) {
    final now = DateTime.now();
    final refundId = _generateRefundId(userId);

    return RefundModel(
      refundId: refundId,
      orderId: orderId,
      userId: userId,
      userName: userName,
      userContact: userContact,
      status: RefundStatus.requested,
      type: type,
      refundAmount: refundAmount,
      originalOrderAmount: originalOrderAmount,
      refundedItems: refundedItems,
      refundReason: refundReason,
      paymentMethod: paymentMethod,
      paymentKey: paymentKey,
      refundBankName: refundBankName,
      refundAccountNumber: refundAccountNumber,
      refundAccountHolder: refundAccountHolder,
      requestedAt: now,
      updatedAt: now,
      idempotencyKey: idempotencyKey,
      clientInfo: clientInfo,
    );
  }

  /// 환불 ID 생성 (userId_timestamp_refund 형태)
  static String _generateRefundId(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${userId}_${timestamp}_refund';
  }

  /// 환불 처리 시간 계산
  Duration? get processingDuration {
    if (requestedAt == null || completedAt == null) return null;
    return completedAt!.difference(requestedAt);
  }

  /// 부분 환불 여부
  bool get isPartialRefund => type == RefundType.partial;

  /// 전액 환불 여부
  bool get isFullRefund => type == RefundType.full;

  /// 가상계좌 환불 여부
  bool get isVirtualAccountRefund =>
      paymentMethod == PaymentMethod.virtualAccount;

  /// 환불 계좌 정보 필요 여부
  bool get needsBankInfo => isVirtualAccountRefund;

  /// 환불 진행 상태 확인
  bool get isInProgress => [
        RefundStatus.requested,
        RefundStatus.reviewing,
        RefundStatus.approved,
        RefundStatus.processing,
      ].contains(status);

  /// 환불 가능 여부 확인
  bool get canBeProcessed => status == RefundStatus.approved;

  /// 환불 취소 가능 여부
  bool get canBeCancelled => [
        RefundStatus.requested,
        RefundStatus.reviewing,
      ].contains(status);

  /// 아이템별 환불 여부
  bool get isItemLevelRefund =>
      refundedItems != null && refundedItems!.isNotEmpty;

  /// 전체 주문 환불 여부
  bool get isOrderLevelRefund => !isItemLevelRefund;

  /// 환불 상품 개수
  int get refundedItemCount => refundedItems?.length ?? 0;

  /// 환불 상품 총 수량
  int get totalRefundedQuantity =>
      refundedItems?.fold<int>(0, (sum, item) => sum + item.refundQuantity) ??
      0;

  @override
  List<Object?> get props => [
        refundId,
        orderId,
        userId,
        userName,
        userContact,
        status,
        type,
        refundAmount,
        actualRefundAmount,
        originalOrderAmount,
        refundFee,
        refundedItems,
        refundReason,
        adminNotes,
        rejectionReason,
        paymentMethod,
        paymentKey,
        providerRefundId,
        refundBankName,
        refundAccountNumber,
        refundAccountHolder,
        requestedAt,
        approvedAt,
        processingStartedAt,
        completedAt,
        updatedAt,
        processedByAdminId,
        idempotencyKey,
        retryCount,
        lastErrorMessage,
        processingDurationSeconds,
        clientInfo,
        providerResponse,
        taxBreakdown,
      ];

  RefundModel copyWith({
    String? refundId,
    String? orderId,
    String? userId,
    String? userName,
    String? userContact,
    RefundStatus? status,
    RefundType? type,
    int? refundAmount,
    int? actualRefundAmount,
    int? originalOrderAmount,
    int? refundFee,
    List<RefundedItemModel>? refundedItems,
    String? refundReason,
    String? adminNotes,
    String? rejectionReason,
    PaymentMethod? paymentMethod,
    String? paymentKey,
    String? providerRefundId,
    String? refundBankName,
    String? refundAccountNumber,
    String? refundAccountHolder,
    DateTime? requestedAt,
    DateTime? approvedAt,
    DateTime? processingStartedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    String? processedByAdminId,
    String? idempotencyKey,
    int? retryCount,
    String? lastErrorMessage,
    int? processingDurationSeconds,
    Map<String, dynamic>? clientInfo,
    Map<String, dynamic>? providerResponse,
    Map<String, dynamic>? taxBreakdown,
  }) {
    return RefundModel(
      refundId: refundId ?? this.refundId,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userContact: userContact ?? this.userContact,
      status: status ?? this.status,
      type: type ?? this.type,
      refundAmount: refundAmount ?? this.refundAmount,
      actualRefundAmount: actualRefundAmount ?? this.actualRefundAmount,
      originalOrderAmount: originalOrderAmount ?? this.originalOrderAmount,
      refundFee: refundFee ?? this.refundFee,
      refundedItems: refundedItems ?? this.refundedItems,
      refundReason: refundReason ?? this.refundReason,
      adminNotes: adminNotes ?? this.adminNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentKey: paymentKey ?? this.paymentKey,
      providerRefundId: providerRefundId ?? this.providerRefundId,
      refundBankName: refundBankName ?? this.refundBankName,
      refundAccountNumber: refundAccountNumber ?? this.refundAccountNumber,
      refundAccountHolder: refundAccountHolder ?? this.refundAccountHolder,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      processingStartedAt: processingStartedAt ?? this.processingStartedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      processedByAdminId: processedByAdminId ?? this.processedByAdminId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      retryCount: retryCount ?? this.retryCount,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      processingDurationSeconds:
          processingDurationSeconds ?? this.processingDurationSeconds,
      clientInfo: clientInfo ?? this.clientInfo,
      providerResponse: providerResponse ?? this.providerResponse,
      taxBreakdown: taxBreakdown ?? this.taxBreakdown,
    );
  }

  // JSON 변환 헬퍼 메서드들
  static RefundStatus _refundStatusFromJson(String value) =>
      RefundStatus.fromString(value);

  static String _refundStatusToJson(RefundStatus status) => status.value;

  static RefundType _refundTypeFromJson(String value) =>
      RefundType.fromString(value);

  static String _refundTypeToJson(RefundType type) => type.value;

  static PaymentMethod _paymentMethodFromJson(String value) =>
      PaymentMethod.fromString(value);

  static String _paymentMethodToJson(PaymentMethod method) => method.value;

  // Nullable DateTime용
  static DateTime? _timestampFromJson(Timestamp? timestamp) =>
      timestamp?.toDate();

  static Timestamp? _timestampToJson(DateTime? dateTime) =>
      dateTime != null ? Timestamp.fromDate(dateTime) : null;

  // Non-nullable DateTime용 (requestedAt, updatedAt)
  static DateTime _timestampRequiredFromJson(Timestamp timestamp) =>
      timestamp.toDate();

  static Timestamp _timestampRequiredToJson(DateTime dateTime) =>
      Timestamp.fromDate(dateTime);
}
