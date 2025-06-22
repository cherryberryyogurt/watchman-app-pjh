import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/index.dart';
import '../services/connectivity_service.dart';

/// 오프라인 상태 배너 위젯
class OfflineBanner extends ConsumerWidget {
  final bool showConnectionType;
  final bool isCompact;

  const OfflineBanner({
    super.key,
    this.showConnectionType = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<bool>(
      stream: ConnectivityService.connectionStream,
      initialData: true, // 기본값은 연결됨으로 가정
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        // 연결된 상태이면 배너 숨김
        if (isConnected) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: EdgeInsets.all(
              isCompact ? Dimensions.paddingSm : Dimensions.paddingMd),
          decoration: BoxDecoration(
            color: ColorPalette.warning,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  color: Colors.white,
                  size: isCompact ? 16 : 20,
                ),
                SizedBox(
                    width: isCompact
                        ? Dimensions.spacingXs
                        : Dimensions.spacingSm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '인터넷 연결을 확인해주세요',
                        style: (isCompact
                                ? TextStyles.bodySmall
                                : TextStyles.bodyMedium)
                            .copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 2),
                        Text(
                          '일부 기능이 제한될 수 있습니다',
                          style: TextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showConnectionType) ...[
                  const SizedBox(width: Dimensions.spacingSm),
                  FutureBuilder<String>(
                    future: ConnectivityService.getConnectionType(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != '연결 없음') {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSm,
                            vertical: Dimensions.paddingXs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusSm),
                          ),
                          child: Text(
                            snapshot.data!,
                            style: TextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 연결 상태 인디케이터 위젯 (작은 아이콘)
class ConnectionIndicator extends ConsumerWidget {
  final double size;
  final bool showLabel;

  const ConnectionIndicator({
    super.key,
    this.size = 16,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<bool>(
      stream: ConnectivityService.connectionStream,
      initialData: true,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        if (showLabel) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                size: size,
                color: isConnected ? Colors.green : ColorPalette.error,
              ),
              const SizedBox(width: Dimensions.spacingXs),
              Text(
                isConnected ? '온라인' : '오프라인',
                style: TextStyles.bodySmall.copyWith(
                  color: isConnected ? Colors.green : ColorPalette.error,
                ),
              ),
            ],
          );
        }

        return Icon(
          isConnected ? Icons.wifi : Icons.wifi_off,
          size: size,
          color: isConnected ? Colors.green : ColorPalette.error,
        );
      },
    );
  }
}

/// 연결 복구 대기 다이얼로그
class ConnectionWaitDialog extends StatelessWidget {
  final String title;
  final String message;
  final Duration timeout;
  final VoidCallback? onCancel;

  const ConnectionWaitDialog({
    super.key,
    this.title = '네트워크 연결 대기 중',
    this.message = '인터넷 연결을 확인하고 있습니다...',
    this.timeout = const Duration(seconds: 30),
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: Dimensions.spacingMd),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyles.bodyMedium,
          ),
          const SizedBox(height: Dimensions.spacingSm),
          Text(
            '최대 ${timeout.inSeconds}초 대기',
            style: TextStyles.bodySmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? ColorPalette.textSecondaryDark
                  : ColorPalette.textSecondaryLight,
            ),
          ),
        ],
      ),
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: const Text('취소'),
          ),
      ],
    );
  }

  /// 연결 복구 대기 다이얼로그 표시
  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? message,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    bool isConnected = false;

    // 다이얼로그 표시
    final dialogFuture = showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConnectionWaitDialog(
        title: title ?? '네트워크 연결 대기 중',
        message: message ?? '인터넷 연결을 확인하고 있습니다...',
        timeout: timeout,
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    // 연결 복구 대기
    try {
      await ConnectivityService.waitForConnection(timeout: timeout);
      isConnected = true;

      // 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // 타임아웃 또는 오류 발생
      if (context.mounted) {
        Navigator.of(context).pop(false);
      }
    }

    // 다이얼로그 결과 반환
    final result = await dialogFuture;
    return result ?? isConnected;
  }
}
