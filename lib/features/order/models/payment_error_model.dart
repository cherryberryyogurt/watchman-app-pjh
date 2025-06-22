/// 🔒 결제 오류 관리 시스템
///
/// TossPayments SDK v2 및 기타 결제 관련 오류를 체계적으로 관리합니다.
import 'package:flutter/foundation.dart';

class PaymentError {
  final String code;
  final String message;
  final String? details;
  final DateTime timestamp;
  final Map<String, dynamic>? context; // 추가 컨텍스트 정보

  PaymentError({
    required this.code,
    required this.message,
    this.details,
    this.context,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// JSON으로 변환 (로깅용)
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }

  /// JSON에서 생성
  factory PaymentError.fromJson(Map<String, dynamic> json) {
    return PaymentError(
      code: json['code'] ?? 'UNKNOWN_ERROR',
      message: json['message'] ?? '알 수 없는 오류',
      details: json['details'],
      context: json['context'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'PaymentError(code: $code, message: $message, details: $details, timestamp: $timestamp, context: $context)';
  }

  /// 로깅용 간단한 문자열
  String toLogString() {
    return '[$code] $message${details != null ? ' - $details' : ''}';
  }
}

/// 🔒 결제 오류 처리기 (SDK v2 대응)
class PaymentErrorHandler {
  /// TossPayments SDK v2 오류 코드를 사용자 친화적 메시지로 변환
  static String getErrorMessage(String errorCode) {
    switch (errorCode.toUpperCase()) {
      // === 사용자 취소 ===
      case 'USER_CANCEL':
      case 'PAY_PROCESS_CANCELED':
      case 'PAYMENT_CANCELED':
        return '사용자가 결제를 취소했습니다.';
      case 'PAYMENT_WINDOW_CLOSED':
        return '결제창이 닫혔습니다.';

      // === 네트워크 오류 ===
      case 'NETWORK_ERROR':
      case 'CONNECTION_ERROR':
        return '네트워크 연결을 확인해주세요.';
      case 'TIMEOUT':
      case 'REQUEST_TIMEOUT':
        return '요청 시간이 초과되었습니다. 다시 시도해주세요.';
      case 'DNS_ERROR':
        return '네트워크 설정을 확인해주세요.';

      // === 카드 관련 오류 ===
      case 'CARD_EXPIRED':
      case 'EXPIRED_CARD':
        return '카드 유효기간이 만료되었습니다.';
      case 'INSUFFICIENT_FUNDS':
      case 'NOT_ENOUGH_BALANCE':
        return '잔액이 부족합니다.';
      case 'CARD_DECLINED':
      case 'CARD_REJECTED':
        return '카드가 거절되었습니다. 카드사에 문의해주세요.';
      case 'INVALID_CARD':
      case 'INVALID_CARD_NUMBER':
        return '올바르지 않은 카드 정보입니다.';
      case 'CARD_NOT_SUPPORTED':
        return '지원되지 않는 카드입니다.';
      case 'CARD_COMPANY_NOT_AVAILABLE':
        return '카드사 서비스가 일시적으로 중단되었습니다.';
      case 'EXCEED_MAX_CARD_INSTALLMENT_PLAN':
        return '할부 개월 수가 초과되었습니다.';

      // === 간편결제 관련 오류 ===
      case 'EASYPAY_NOT_SUPPORTED':
        return '지원되지 않는 간편결제입니다.';
      case 'EASYPAY_AMOUNT_LIMIT_EXCEEDED':
        return '간편결제 한도를 초과했습니다.';
      case 'EASYPAY_SERVICE_UNAVAILABLE':
        return '간편결제 서비스가 일시적으로 중단되었습니다.';

      // === 가상계좌 관련 오류 ===
      case 'VIRTUAL_ACCOUNT_EXPIRED':
        return '가상계좌 입금 기한이 만료되었습니다.';
      case 'VIRTUAL_ACCOUNT_NOT_FOUND':
        return '가상계좌 정보를 찾을 수 없습니다.';
      case 'VIRTUAL_ACCOUNT_ALREADY_DEPOSITED':
        return '이미 입금이 완료된 가상계좌입니다.';

      // === 시스템 오류 ===
      case 'INTERNAL_SERVER_ERROR':
      case 'SERVER_ERROR':
        return '일시적인 시스템 오류입니다. 잠시 후 다시 시도해주세요.';
      case 'SERVICE_UNAVAILABLE':
      case 'TEMPORARILY_UNAVAILABLE':
        return '서비스가 일시적으로 중단되었습니다. 잠시 후 다시 시도해주세요.';
      case 'MAINTENANCE':
        return '시스템 점검 중입니다. 잠시 후 다시 시도해주세요.';

      // === 인증 오류 ===
      case 'UNAUTHORIZED':
      case 'AUTHENTICATION_FAILED':
        return '인증에 실패했습니다. 다시 로그인해주세요.';
      case 'FORBIDDEN':
      case 'ACCESS_DENIED':
        return '접근 권한이 없습니다.';
      case 'TOKEN_EXPIRED':
        return '인증이 만료되었습니다. 다시 로그인해주세요.';

      // === 결제 정보 오류 ===
      case 'INVALID_REQUEST':
      case 'BAD_REQUEST':
        return '결제 정보가 올바르지 않습니다.';
      case 'INVALID_AMOUNT':
      case 'AMOUNT_TOO_LOW':
      case 'AMOUNT_TOO_HIGH':
        return '결제 금액이 올바르지 않습니다.';
      case 'DUPLICATE_ORDER':
      case 'ALREADY_PROCESSED':
        return '이미 처리된 주문입니다.';
      case 'ORDER_NOT_FOUND':
        return '주문 정보를 찾을 수 없습니다.';
      case 'PAYMENT_NOT_FOUND':
        return '결제 정보를 찾을 수 없습니다.';

      // === 앱 관련 오류 ===
      case 'APP_NOT_INSTALLED':
        return '결제 앱이 설치되지 않았습니다.';
      case 'APP_VERSION_NOT_SUPPORTED':
        return '결제 앱 버전을 업데이트해주세요.';
      case 'APP_SCHEME_NOT_SUPPORTED':
        return '앱 연동에 실패했습니다.';

      // === 웹뷰/브라우저 관련 오류 ===
      case 'WEBVIEW_ERROR':
      case 'BROWSER_NOT_SUPPORTED':
        return '결제창 로딩 중 오류가 발생했습니다.';
      case 'JAVASCRIPT_ERROR':
      case 'SDK_ERROR':
        return '결제 처리 중 오류가 발생했습니다.';
      case 'POPUP_BLOCKED':
        return '팝업이 차단되었습니다. 팝업 차단을 해제해주세요.';

      // === SDK v2 특화 오류 ===
      case 'WIDGET_NOT_INITIALIZED':
        return '결제 위젯 초기화에 실패했습니다.';
      case 'PAYMENT_WIDGET_NOT_FOUND':
        return '결제 위젯을 찾을 수 없습니다.';
      case 'INVALID_CLIENT_KEY':
        return '잘못된 클라이언트 키입니다.';
      case 'CUSTOMER_KEY_REQUIRED':
        return '고객 키가 필요합니다.';
      case 'PAYMENT_METHOD_NOT_SUPPORTED':
        return '지원되지 않는 결제수단입니다.';

      // === 보안 관련 오류 ===
      case 'SECURITY_ERROR':
      case 'CORS_ERROR':
        return '보안 오류가 발생했습니다.';
      case 'INVALID_SIGNATURE':
        return '서명 검증에 실패했습니다.';

      // === 기본 오류 ===
      case 'UNKNOWN_ERROR':
      default:
        return '결제 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
  }

  /// 오류 레벨 결정 (더 세분화)
  static PaymentErrorLevel getErrorLevel(String errorCode) {
    switch (errorCode.toUpperCase()) {
      // 정보성 (사용자 의도적 행동)
      case 'USER_CANCEL':
      case 'PAY_PROCESS_CANCELED':
      case 'PAYMENT_CANCELED':
      case 'PAYMENT_WINDOW_CLOSED':
        return PaymentErrorLevel.info;

      // 경고 (사용자가 수정 가능한 문제)
      case 'NETWORK_ERROR':
      case 'CONNECTION_ERROR':
      case 'TIMEOUT':
      case 'REQUEST_TIMEOUT':
      case 'CARD_EXPIRED':
      case 'EXPIRED_CARD':
      case 'INSUFFICIENT_FUNDS':
      case 'NOT_ENOUGH_BALANCE':
      case 'INVALID_CARD':
      case 'INVALID_CARD_NUMBER':
      case 'CARD_NOT_SUPPORTED':
      case 'INVALID_AMOUNT':
      case 'AMOUNT_TOO_LOW':
      case 'AMOUNT_TOO_HIGH':
      case 'APP_NOT_INSTALLED':
      case 'APP_VERSION_NOT_SUPPORTED':
      case 'POPUP_BLOCKED':
        return PaymentErrorLevel.warning;

      // 심각 (시스템 문제 또는 복구 어려운 상황)
      case 'INTERNAL_SERVER_ERROR':
      case 'SERVER_ERROR':
      case 'SERVICE_UNAVAILABLE':
      case 'TEMPORARILY_UNAVAILABLE':
      case 'MAINTENANCE':
      case 'UNAUTHORIZED':
      case 'AUTHENTICATION_FAILED':
      case 'FORBIDDEN':
      case 'ACCESS_DENIED':
      case 'TOKEN_EXPIRED':
      case 'CARD_DECLINED':
      case 'CARD_REJECTED':
      case 'DUPLICATE_ORDER':
      case 'ALREADY_PROCESSED':
      case 'SECURITY_ERROR':
      case 'CORS_ERROR':
      case 'INVALID_SIGNATURE':
      case 'INVALID_CLIENT_KEY':
        return PaymentErrorLevel.error;

      // 치명적 (시스템 오류)
      case 'WIDGET_NOT_INITIALIZED':
      case 'PAYMENT_WIDGET_NOT_FOUND':
      case 'SDK_ERROR':
      case 'JAVASCRIPT_ERROR':
        return PaymentErrorLevel.critical;

      default:
        return PaymentErrorLevel.error;
    }
  }

  /// 재시도 가능 여부 확인 (더 정교한 로직)
  static bool isRetryable(String errorCode) {
    switch (errorCode.toUpperCase()) {
      // 재시도 가능 (일시적 문제)
      case 'NETWORK_ERROR':
      case 'CONNECTION_ERROR':
      case 'TIMEOUT':
      case 'REQUEST_TIMEOUT':
      case 'DNS_ERROR':
      case 'INTERNAL_SERVER_ERROR':
      case 'SERVER_ERROR':
      case 'SERVICE_UNAVAILABLE':
      case 'TEMPORARILY_UNAVAILABLE':
      case 'CARD_COMPANY_NOT_AVAILABLE':
      case 'EASYPAY_SERVICE_UNAVAILABLE':
      case 'WEBVIEW_ERROR':
      case 'BROWSER_NOT_SUPPORTED':
        return true;

      // 재시도 불가능 (사용자 의도 또는 영구적 문제)
      case 'USER_CANCEL':
      case 'PAY_PROCESS_CANCELED':
      case 'PAYMENT_CANCELED':
      case 'PAYMENT_WINDOW_CLOSED':
      case 'CARD_EXPIRED':
      case 'EXPIRED_CARD':
      case 'INSUFFICIENT_FUNDS':
      case 'NOT_ENOUGH_BALANCE':
      case 'INVALID_CARD':
      case 'INVALID_CARD_NUMBER':
      case 'CARD_DECLINED':
      case 'CARD_REJECTED':
      case 'DUPLICATE_ORDER':
      case 'ALREADY_PROCESSED':
      case 'ORDER_NOT_FOUND':
      case 'PAYMENT_NOT_FOUND':
      case 'VIRTUAL_ACCOUNT_EXPIRED':
      case 'VIRTUAL_ACCOUNT_ALREADY_DEPOSITED':
      case 'UNAUTHORIZED':
      case 'FORBIDDEN':
      case 'ACCESS_DENIED':
      case 'INVALID_CLIENT_KEY':
      case 'SECURITY_ERROR':
      case 'INVALID_SIGNATURE':
        return false;

      // 조건부 재시도 (기본적으로 허용)
      default:
        return true;
    }
  }

  /// 자동 재시도 가능 여부 (사용자 개입 없이)
  static bool isAutoRetryable(String errorCode) {
    switch (errorCode.toUpperCase()) {
      case 'NETWORK_ERROR':
      case 'CONNECTION_ERROR':
      case 'TIMEOUT':
      case 'REQUEST_TIMEOUT':
      case 'INTERNAL_SERVER_ERROR':
      case 'SERVER_ERROR':
        return true;
      default:
        return false;
    }
  }

  /// 재시도 지연 시간 (초)
  static int getRetryDelay(String errorCode, int attemptCount) {
    switch (errorCode.toUpperCase()) {
      case 'NETWORK_ERROR':
      case 'CONNECTION_ERROR':
        return [1, 3, 5, 10][attemptCount.clamp(0, 3)]; // 1초, 3초, 5초, 10초
      case 'TIMEOUT':
      case 'REQUEST_TIMEOUT':
        return [2, 5, 10][attemptCount.clamp(0, 2)]; // 2초, 5초, 10초
      case 'INTERNAL_SERVER_ERROR':
      case 'SERVER_ERROR':
        return [3, 10, 30][attemptCount.clamp(0, 2)]; // 3초, 10초, 30초
      default:
        return 5; // 기본 5초
    }
  }

  /// 최대 재시도 횟수
  static int getMaxRetryCount(String errorCode) {
    switch (errorCode.toUpperCase()) {
      case 'NETWORK_ERROR':
      case 'CONNECTION_ERROR':
        return 3;
      case 'TIMEOUT':
      case 'REQUEST_TIMEOUT':
        return 2;
      case 'INTERNAL_SERVER_ERROR':
      case 'SERVER_ERROR':
        return 2;
      default:
        return 1;
    }
  }

  /// 디버그 정보 포함 여부
  static bool shouldIncludeDebugInfo(String errorCode) {
    switch (errorCode.toUpperCase()) {
      case 'USER_CANCEL':
      case 'PAY_PROCESS_CANCELED':
      case 'PAYMENT_CANCELED':
      case 'PAYMENT_WINDOW_CLOSED':
        return false;
      default:
        return kDebugMode; // 디버그 모드에서만 포함
    }
  }

  /// 사용자 액션 제안
  static List<PaymentErrorAction> getSuggestedActions(String errorCode) {
    switch (errorCode.toUpperCase()) {
      case 'NETWORK_ERROR':
      case 'CONNECTION_ERROR':
        return [
          PaymentErrorAction.checkNetwork,
          PaymentErrorAction.retry,
        ];
      case 'CARD_EXPIRED':
      case 'EXPIRED_CARD':
        return [
          PaymentErrorAction.updatePaymentMethod,
          PaymentErrorAction.useAlternativePayment,
        ];
      case 'INSUFFICIENT_FUNDS':
      case 'NOT_ENOUGH_BALANCE':
        return [
          PaymentErrorAction.checkBalance,
          PaymentErrorAction.useAlternativePayment,
        ];
      case 'APP_NOT_INSTALLED':
        return [
          PaymentErrorAction.installApp,
          PaymentErrorAction.useAlternativePayment,
        ];
      case 'POPUP_BLOCKED':
        return [
          PaymentErrorAction.allowPopup,
          PaymentErrorAction.retry,
        ];
      default:
        return [PaymentErrorAction.retry, PaymentErrorAction.contactSupport];
    }
  }

  /// 에러 로깅 (개발/운영 환경별)
  static void logError(PaymentError error,
      {String? userId, String? sessionId}) {
    final logData = {
      ...error.toJson(),
      'userId': userId,
      'sessionId': sessionId,
      'platform': defaultTargetPlatform.name,
      'isDebugMode': kDebugMode,
    };

    if (kDebugMode) {
      debugPrint('🔴 PaymentError: ${error.toLogString()}');
      debugPrint('📊 Context: $logData');
    } else {
      // 운영 환경에서는 로깅 서비스로 전송
      // FirebaseCrashlytics.instance.recordError(error, null, information: logData);
    }
  }
}

/// 결제 오류 레벨 (더 세분화)
enum PaymentErrorLevel {
  info, // 정보성 (사용자 취소 등)
  warning, // 경고 (사용자가 수정 가능)
  error, // 오류 (시스템 문제)
  critical, // 치명적 (긴급 수정 필요)
}

/// 사용자 액션 제안
enum PaymentErrorAction {
  retry, // 다시 시도
  checkNetwork, // 네트워크 확인
  updatePaymentMethod, // 결제수단 변경
  useAlternativePayment, // 다른 결제수단 사용
  checkBalance, // 잔액 확인
  installApp, // 앱 설치
  allowPopup, // 팝업 허용
  contactSupport, // 고객센터 문의
  refreshPage, // 페이지 새로고침
  clearCache, // 캐시 삭제
}

/// 결제 오류 확장 메서드
extension PaymentErrorExtension on PaymentError {
  PaymentErrorLevel get level => PaymentErrorHandler.getErrorLevel(code);
  String get userMessage => PaymentErrorHandler.getErrorMessage(code);
  bool get isRetryable => PaymentErrorHandler.isRetryable(code);
  bool get isAutoRetryable => PaymentErrorHandler.isAutoRetryable(code);
  bool get shouldIncludeDebugInfo =>
      PaymentErrorHandler.shouldIncludeDebugInfo(code);
  List<PaymentErrorAction> get suggestedActions =>
      PaymentErrorHandler.getSuggestedActions(code);
  int getRetryDelay(int attemptCount) =>
      PaymentErrorHandler.getRetryDelay(code, attemptCount);
  int get maxRetryCount => PaymentErrorHandler.getMaxRetryCount(code);

  /// 로깅
  void log({String? userId, String? sessionId}) {
    PaymentErrorHandler.logError(this, userId: userId, sessionId: sessionId);
  }
}
