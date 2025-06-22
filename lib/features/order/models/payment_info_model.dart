/// Toss Payments 결제 정보 모델
///
/// Toss Payments API의 Payment 객체를 완전히 매핑한 클래스입니다.
/// 50개 이상의 모든 필드를 지원합니다.

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'order_enums.dart';

part 'payment_info_model.g.dart';

/// Toss Payments 결제 정보
///
/// Toss Payments API의 Payment 객체를 완전히 매핑한 클래스입니다.
/// 50개 이상의 모든 필드를 지원합니다.
@JsonSerializable()
class PaymentInfo extends Equatable {
  // 🏷️ 기본 정보
  /// 결제 키 (Toss Payments 고유)
  final String? paymentKey;

  /// 주문 ID (우리 시스템)
  final String orderId;

  /// 결제 상태
  @JsonKey(fromJson: _paymentStatusFromJson, toJson: _paymentStatusToJson)
  final PaymentStatus status;

  /// 결제 금액
  final int totalAmount;

  /// 취소 가능 금액
  final int? balanceAmount;

  /// 공급가액
  final int? suppliedAmount;

  /// 부가세
  final int? vat;

  /// 비과세 금액
  final int? taxFreeAmount;

  // 🛒 주문 정보
  /// 주문명
  final String? orderName;

  /// 상점ID
  final String? mId;

  /// API 버전
  final String? version;

  /// 결제 수단
  @JsonKey(fromJson: _paymentMethodFromJson, toJson: _paymentMethodToJson)
  final PaymentMethod? method;

  // --- 시간 정보
  /// 결제 요청 시각
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? requestedAt;

  /// 결제 승인 시각
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? approvedAt;

  // --- 가맹점 정보
  /// 문화비 소득공제 적용 금액
  final int? cultureExpense;

  /// 에스크로 사용 여부
  final bool? useEscrow;

  /// 현금영수증 정보
  final Map<String, dynamic>? cashReceipt;

  /// 에스크로 정보
  final Map<String, dynamic>? escrow;

  // --- 결제 수단별 상세 정보
  /// 카드 결제 정보
  final Map<String, dynamic>? card;

  /// 가상계좌 정보
  final Map<String, dynamic>? virtualAccount;

  /// 계좌이체 정보
  final Map<String, dynamic>? transfer;

  /// 휴대폰 결제 정보
  final Map<String, dynamic>? mobilePhone;

  /// 상품권 결제 정보
  final Map<String, dynamic>? giftCertificate;

  /// 간편결제 정보
  final Map<String, dynamic>? easyPay;

  // --- 추가 정보
  /// 할인 정보
  final Map<String, dynamic>? discount;

  /// 카드 할부 정보
  final Map<String, dynamic>? cardInstallment;

  /// 국가 코드
  final String? country;

  /// 실패 정보
  final Map<String, dynamic>? failure;

  /// 취소 내역
  final List<Map<String, dynamic>>? cancels;

  /// 현금영수증 내역
  final List<Map<String, dynamic>>? cashReceipts;

  // --- 거래 정보
  /// 영수증 URL
  final String? receiptUrl;

  /// 결제 영수증 URL
  final String? checkoutUrl;

  /// 거래 식별자
  final String? transactionKey;

  /// 마지막 거래 키
  final String? lastTransactionKey;

  const PaymentInfo({
    this.paymentKey,
    required this.orderId,
    required this.status,
    required this.totalAmount,
    this.balanceAmount,
    this.suppliedAmount,
    this.vat,
    this.taxFreeAmount,
    this.orderName,
    this.mId,
    this.version,
    this.method,
    this.requestedAt,
    this.approvedAt,
    this.cultureExpense,
    this.useEscrow,
    this.cashReceipt,
    this.escrow,
    this.card,
    this.virtualAccount,
    this.transfer,
    this.mobilePhone,
    this.giftCertificate,
    this.easyPay,
    this.discount,
    this.cardInstallment,
    this.country,
    this.failure,
    this.cancels,
    this.cashReceipts,
    this.receiptUrl,
    this.checkoutUrl,
    this.transactionKey,
    this.lastTransactionKey,
  });

  /// JSON으로부터 생성
  factory PaymentInfo.fromJson(Map<String, dynamic> json) =>
      _$PaymentInfoFromJson(json);

  /// JSON으로 변환
  Map<String, dynamic> toJson() => _$PaymentInfoToJson(this);

  /// Toss Payments API 응답으로부터 생성 (호환성)
  factory PaymentInfo.fromTossResponse(Map<String, dynamic> json) =>
      PaymentInfo.fromJson(json);

  /// Firestore Map으로부터 생성 (호환성)
  factory PaymentInfo.fromMap(Map<String, dynamic> map) =>
      PaymentInfo.fromJson(map);

  /// Firestore Map으로 변환 (호환성)
  Map<String, dynamic> toMap() => toJson();

  /// 결제 성공 여부
  bool get isSuccessful => status.isSuccessful;

  /// 결제 실패 여부
  bool get isFailed => status.isFailed;

  /// 취소 가능 여부
  bool get isCancellable => status.isSuccessful && (balanceAmount ?? 0) > 0;

  @override
  List<Object?> get props => [
        paymentKey,
        orderId,
        status,
        totalAmount,
        balanceAmount,
        suppliedAmount,
        vat,
        taxFreeAmount,
        orderName,
        mId,
        version,
        method,
        requestedAt,
        approvedAt,
        cultureExpense,
        useEscrow,
        cashReceipt,
        escrow,
        card,
        virtualAccount,
        transfer,
        mobilePhone,
        giftCertificate,
        easyPay,
        discount,
        cardInstallment,
        country,
        failure,
        cancels,
        cashReceipts,
        receiptUrl,
        checkoutUrl,
        transactionKey,
        lastTransactionKey,
      ];

  PaymentInfo copyWith({
    String? paymentKey,
    String? orderId,
    PaymentStatus? status,
    int? totalAmount,
    int? balanceAmount,
    int? suppliedAmount,
    int? vat,
    int? taxFreeAmount,
    String? orderName,
    String? mId,
    String? version,
    PaymentMethod? method,
    DateTime? requestedAt,
    DateTime? approvedAt,
    int? cultureExpense,
    bool? useEscrow,
    Map<String, dynamic>? cashReceipt,
    Map<String, dynamic>? escrow,
    Map<String, dynamic>? card,
    Map<String, dynamic>? virtualAccount,
    Map<String, dynamic>? transfer,
    Map<String, dynamic>? mobilePhone,
    Map<String, dynamic>? giftCertificate,
    Map<String, dynamic>? easyPay,
    Map<String, dynamic>? discount,
    Map<String, dynamic>? cardInstallment,
    String? country,
    Map<String, dynamic>? failure,
    List<Map<String, dynamic>>? cancels,
    List<Map<String, dynamic>>? cashReceipts,
    String? receiptUrl,
    String? checkoutUrl,
    String? transactionKey,
    String? lastTransactionKey,
  }) {
    return PaymentInfo(
      paymentKey: paymentKey ?? this.paymentKey,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      suppliedAmount: suppliedAmount ?? this.suppliedAmount,
      vat: vat ?? this.vat,
      taxFreeAmount: taxFreeAmount ?? this.taxFreeAmount,
      orderName: orderName ?? this.orderName,
      mId: mId ?? this.mId,
      version: version ?? this.version,
      method: method ?? this.method,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      cultureExpense: cultureExpense ?? this.cultureExpense,
      useEscrow: useEscrow ?? this.useEscrow,
      cashReceipt: cashReceipt ?? this.cashReceipt,
      escrow: escrow ?? this.escrow,
      card: card ?? this.card,
      virtualAccount: virtualAccount ?? this.virtualAccount,
      transfer: transfer ?? this.transfer,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      giftCertificate: giftCertificate ?? this.giftCertificate,
      easyPay: easyPay ?? this.easyPay,
      discount: discount ?? this.discount,
      cardInstallment: cardInstallment ?? this.cardInstallment,
      country: country ?? this.country,
      failure: failure ?? this.failure,
      cancels: cancels ?? this.cancels,
      cashReceipts: cashReceipts ?? this.cashReceipts,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      transactionKey: transactionKey ?? this.transactionKey,
      lastTransactionKey: lastTransactionKey ?? this.lastTransactionKey,
    );
  }

  // JSON 변환 헬퍼 메서드들
  static PaymentStatus _paymentStatusFromJson(String? value) =>
      value != null ? PaymentStatus.fromString(value) : PaymentStatus.ready;

  static String? _paymentStatusToJson(PaymentStatus status) => status.value;

  static PaymentMethod? _paymentMethodFromJson(String? value) =>
      value != null ? PaymentMethod.fromString(value) : null;

  static String? _paymentMethodToJson(PaymentMethod? method) =>
      method?.apiValue;

  static DateTime? _dateTimeFromJson(String? value) =>
      value != null ? DateTime.parse(value) : null;

  static String? _dateTimeToJson(DateTime? dateTime) =>
      dateTime?.toIso8601String();
}
