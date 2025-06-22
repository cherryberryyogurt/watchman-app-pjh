import 'package:flutter/material.dart';
import '../../features/order/models/payment_error_model.dart';
import '../theme/color_palette.dart';

/// 🚨 에러 스낵바
///
/// 간단한 에러 메시지를 스낵바로 표시합니다.
class ErrorSnackBar {
  /// 에러 스낵바 표시
  static void show(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    String message;
    Color backgroundColor = ColorPalette.error;
    IconData icon = Icons.error;

    if (error is PaymentError) {
      message = error.message;
      // 에러 레벨에 따른 색상 조정
      switch (error.level) {
        case PaymentErrorLevel.info:
          backgroundColor = ColorPalette.info;
          icon = Icons.info;
          break;
        case PaymentErrorLevel.warning:
          backgroundColor = ColorPalette.warning;
          icon = Icons.warning;
          break;
        case PaymentErrorLevel.error:
        case PaymentErrorLevel.critical:
          backgroundColor = ColorPalette.error;
          icon = Icons.error;
          break;
      }
    } else {
      message = error.toString();
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 기존 스낵바 제거
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  scaffoldMessenger.hideCurrentSnackBar();
                  onRetry();
                },
                child: const Text(
                  '재시도',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: onRetry == null
            ? null
            : SnackBarAction(
                label: '닫기',
                textColor: Colors.white,
                onPressed: () => scaffoldMessenger.hideCurrentSnackBar(),
              ),
      ),
    );
  }

  /// 성공 스낵바 표시
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: ColorPalette.success,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 정보 스낵바 표시
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: ColorPalette.info,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
