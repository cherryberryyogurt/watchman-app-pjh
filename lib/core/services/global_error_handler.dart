import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../features/order/models/payment_error_model.dart';
import '../widgets/error_display_widget.dart';
import '../widgets/error_snack_bar.dart';

/// 🚨 글로벌 에러 핸들러
///
/// 앱 전체에서 발생하는 에러를 일관되게 처리하고 로깅합니다.
class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  /// 초기화 - 앱 시작 시 호출
  static void initialize() {
    // Flutter 프레임워크 에러 처리
    FlutterError.onError = (FlutterErrorDetails details) {
      _instance._handleFlutterError(details);
    };

    // Dart 비동기 에러 처리
    PlatformDispatcher.instance.onError = (error, stack) {
      _instance._handlePlatformError(error, stack);
      return true;
    };

    debugPrint('🚨 GlobalErrorHandler 초기화 완료');
  }

  /// Flutter 프레임워크 에러 처리
  void _handleFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      // 개발 모드에서는 기본 에러 출력
      FlutterError.presentError(details);
    } else {
      // 운영 모드에서는 로그로 기록
      debugPrint('🚨 Flutter Fatal Error: ${details.exceptionAsString()}');
      debugPrint('Stack: ${details.stack}');
    }

    // 결제 관련 에러인지 확인
    if (_isPaymentRelatedError(details.exception)) {
      _logPaymentError(details.exception, details.stack);
    }

    debugPrint('🚨 Flutter Error: ${details.exceptionAsString()}');
  }

  /// 플랫폼 에러 처리
  bool _handlePlatformError(Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('🚨 Platform Error: $error');
      debugPrint('Stack: $stack');
    } else {
      debugPrint('🚨 Platform Fatal Error: $error');
      debugPrint('Stack: $stack');
    }

    // 결제 관련 에러인지 확인
    if (_isPaymentRelatedError(error)) {
      _logPaymentError(error, stack);
    }

    return true;
  }

  /// 결제 관련 에러인지 확인
  bool _isPaymentRelatedError(Object error) {
    if (error is PaymentError) return true;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('payment') ||
        errorString.contains('toss') ||
        errorString.contains('결제') ||
        errorString.contains('order') ||
        errorString.contains('주문');
  }

  /// 결제 에러 로깅
  void _logPaymentError(Object error, StackTrace? stack) {
    if (error is PaymentError) {
      error.log();
    } else {
      final paymentError = PaymentError(
        code: 'GLOBAL_ERROR',
        message: error.toString(),
        context: {
          'errorType': error.runtimeType.toString(),
          'stackTrace': stack?.toString(),
          'source': 'global_error_handler',
        },
      );
      paymentError.log();
    }
  }

  /// 에러 다이얼로그 표시 (UI 컨텍스트에서 호출)
  static void showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: ErrorDisplayWidget(
          error: error,
          title: title ?? '오류',
          showDetails: kDebugMode,
          showActions: true,
          maxWidth: 400,
          onRetry: onRetry,
          onClose: onClose ?? () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// 에러 스낵바 표시 (간단한 에러용)
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    ErrorSnackBar.show(
      context,
      error,
      duration: duration,
      onRetry: onRetry,
    );
  }

  /// 에러 리포팅 (운영 환경)
  static void reportError(
    dynamic error,
    StackTrace? stack, {
    String? userId,
    Map<String, dynamic>? context,
    bool fatal = false,
  }) {
    if (kDebugMode) {
      debugPrint('🚨 Error Report: $error');
      if (stack != null) debugPrint('Stack: $stack');
      if (context != null) debugPrint('Context: $context');
    } else {
      // 운영 환경에서는 로그로 기록 (나중에 외부 로깅 서비스 연동 가능)
      debugPrint('🚨 Error Report (${fatal ? 'FATAL' : 'NON-FATAL'}): $error');
      if (stack != null) debugPrint('Stack: $stack');
      if (userId != null) debugPrint('User ID: $userId');
      if (context != null) debugPrint('Context: $context');
    }

    // PaymentError인 경우 추가 로깅
    if (error is PaymentError) {
      error.log(userId: userId);
    }
  }

  /// 결제 에러 전용 핸들러
  static void handlePaymentError(
    BuildContext context,
    PaymentError error, {
    VoidCallback? onRetry,
    VoidCallback? onClose,
  }) {
    // 에러 로깅
    error.log();

    // 에러 레벨에 따른 처리
    switch (error.level) {
      case PaymentErrorLevel.info:
        // 정보성 메시지는 스낵바로 표시
        showErrorSnackBar(context, error, onRetry: onRetry);
        break;
      case PaymentErrorLevel.warning:
      case PaymentErrorLevel.error:
      case PaymentErrorLevel.critical:
        // 경고/오류/치명적 에러는 다이얼로그로 표시
        showErrorDialog(
          context,
          error,
          title: '결제 오류',
          onRetry: onRetry,
          onClose: onClose,
        );
        break;
    }
  }

  /// 네트워크 에러 핸들러
  static void handleNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    final error = PaymentError(
      code: 'NETWORK_ERROR',
      message: '네트워크 연결을 확인해주세요.',
    );

    showErrorDialog(
      context,
      error,
      title: '네트워크 오류',
      onRetry: onRetry,
    );
  }

  /// 인증 에러 핸들러
  static void handleAuthError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    final error = PaymentError(
      code: 'AUTHENTICATION_REQUIRED',
      message: '로그인이 필요합니다.',
    );

    showErrorDialog(
      context,
      error,
      title: '인증 오류',
      onRetry: onRetry,
    );
  }
}
