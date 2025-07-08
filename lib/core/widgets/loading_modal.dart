import 'package:flutter/material.dart';
import '../theme/index.dart';

/// 로딩 모달 유틸리티
///
/// 비동기 작업 중 사용자에게 진행 상황을 알리는 모달 다이얼로그
class LoadingModal {
  /// 로딩 모달 표시
  ///
  /// [context] - 모달을 표시할 컨텍스트
  /// [message] - 표시할 메시지 (기본값: "처리 중입니다...")
  /// [barrierDismissible] - 배경 터치로 닫기 가능 여부 (기본값: false)
  ///
  /// Returns: 모달을 닫을 수 있는 함수
  static VoidCallback show(
    BuildContext context, {
    String message = "처리 중입니다...",
    bool barrierDismissible = false,
  }) {
    // 🛡️ 위젯이 unmount될 가능성이 있는 context를 사용하는 대신,
    // 안정적인 NavigatorState를 미리 캡처합니다.
    final NavigatorState navigatorState = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return _LoadingModalDialog(message: message);
      },
    );

    // 모달을 닫는 함수 반환
    return () {
      // 캡처해둔 navigatorState를 사용하여 안전하게 pop합니다.
      if (navigatorState.canPop()) {
        navigatorState.pop();
      }
    };
  }

  /// 특정 작업과 함께 로딩 모달 표시
  ///
  /// [context] - 모달을 표시할 컨텍스트
  /// [future] - 실행할 비동기 작업
  /// [message] - 표시할 메시지
  ///
  /// Returns: 비동기 작업의 결과
  static Future<T> showWithFuture<T>(
    BuildContext context,
    Future<T> future, {
    String message = "처리 중입니다...",
  }) async {
    // 🛡️ 위젯이 unmount될 가능성이 있는 context를 사용하는 대신,
    // 안정적인 NavigatorState를 미리 캡처합니다.
    final NavigatorState navigatorState = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _LoadingModalDialog(message: message);
      },
    );

    try {
      final result = await future;
      if (navigatorState.canPop()) {
        navigatorState.pop();
      }
      return result;
    } catch (e) {
      if (navigatorState.canPop()) {
        navigatorState.pop();
      }
      rethrow;
    }
  }
}

/// 로딩 모달 다이얼로그 위젯
class _LoadingModalDialog extends StatelessWidget {
  final String message;

  const _LoadingModalDialog({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingXl),
        decoration: BoxDecoration(
          color:
              isDarkMode ? ColorPalette.surfaceDark : ColorPalette.surfaceLight,
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
          boxShadow: isDarkMode ? null : Styles.shadowLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 로딩 인디케이터
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.primary),
                strokeWidth: 3,
              ),
            ),

            const SizedBox(height: Dimensions.spacingLg),

            // 메시지
            Text(
              message,
              style: TextStyles.bodyLarge.copyWith(
                color: isDarkMode
                    ? ColorPalette.textPrimaryDark
                    : ColorPalette.textPrimaryLight,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
