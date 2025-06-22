import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../features/order/models/payment_error_model.dart';
import '../theme/color_palette.dart';

/// 🎨 에러 표시 위젯
///
/// PaymentError 및 일반 에러를 사용자 친화적으로 표시합니다.
class ErrorDisplayWidget extends StatelessWidget {
  final dynamic error;
  final String? title;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final bool showDetails;
  final bool showActions;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  const ErrorDisplayWidget({
    super.key,
    required this.error,
    this.title,
    this.onRetry,
    this.onClose,
    this.showDetails = false,
    this.showActions = true,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentError = error is PaymentError ? error as PaymentError : null;

    return Container(
      width: maxWidth,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getErrorColor(paymentError?.level ?? PaymentErrorLevel.error),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 에러 헤더
          Row(
            children: [
              Icon(
                _getErrorIcon(paymentError?.level ?? PaymentErrorLevel.error),
                color: _getErrorColor(
                    paymentError?.level ?? PaymentErrorLevel.error),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ??
                          _getErrorTitle(
                              paymentError?.level ?? PaymentErrorLevel.error),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getErrorColor(
                            paymentError?.level ?? PaymentErrorLevel.error),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      paymentError?.userMessage ?? error.toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
            ],
          ),

          // 상세 정보 (디버그 모드 또는 요청 시)
          if (showDetails &&
              paymentError != null &&
              paymentError.shouldIncludeDebugInfo) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '상세 정보',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('오류 코드', paymentError.code),
                  if (paymentError.details != null)
                    _buildDetailRow('상세', paymentError.details!),
                  _buildDetailRow(
                      '발생 시간',
                      '${paymentError.timestamp.hour.toString().padLeft(2, '0')}:'
                          '${paymentError.timestamp.minute.toString().padLeft(2, '0')}:'
                          '${paymentError.timestamp.second.toString().padLeft(2, '0')}'),
                ],
              ),
            ),
          ],

          // 제안된 액션들
          if (showActions &&
              paymentError != null &&
              paymentError.suggestedActions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '해결 방법',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...paymentError.suggestedActions.map(
                (action) => _buildActionChip(context, action, paymentError)),
          ],

          // 액션 버튼들
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (paymentError?.isRetryable == true && onRetry != null) ...[
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                    style: TextButton.styleFrom(
                      foregroundColor: _getErrorColor(
                          paymentError?.level ?? PaymentErrorLevel.error),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: () => _showSupportOptions(context),
                  child: const Text('도움말'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, PaymentErrorAction action,
      PaymentError paymentError) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ActionChip(
        avatar: Icon(
          _getActionIcon(action),
          size: 16,
        ),
        label: Text(
          _getActionText(action),
          style: const TextStyle(fontSize: 12),
        ),
        onPressed: () => _handleAction(context, action, paymentError),
        backgroundColor: Colors.grey.shade100,
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  IconData _getErrorIcon(PaymentErrorLevel level) {
    switch (level) {
      case PaymentErrorLevel.info:
        return Icons.info_outline;
      case PaymentErrorLevel.warning:
        return Icons.warning_amber_outlined;
      case PaymentErrorLevel.error:
        return Icons.error_outline;
      case PaymentErrorLevel.critical:
        return Icons.dangerous_outlined;
    }
  }

  Color _getErrorColor(PaymentErrorLevel level) {
    switch (level) {
      case PaymentErrorLevel.info:
        return Colors.blue;
      case PaymentErrorLevel.warning:
        return Colors.orange;
      case PaymentErrorLevel.error:
        return ColorPalette.error;
      case PaymentErrorLevel.critical:
        return Colors.red.shade800;
    }
  }

  String _getErrorTitle(PaymentErrorLevel level) {
    switch (level) {
      case PaymentErrorLevel.info:
        return '알림';
      case PaymentErrorLevel.warning:
        return '주의';
      case PaymentErrorLevel.error:
        return '오류';
      case PaymentErrorLevel.critical:
        return '심각한 오류';
    }
  }

  IconData _getActionIcon(PaymentErrorAction action) {
    switch (action) {
      case PaymentErrorAction.retry:
        return Icons.refresh;
      case PaymentErrorAction.checkNetwork:
        return Icons.wifi;
      case PaymentErrorAction.updatePaymentMethod:
        return Icons.credit_card;
      case PaymentErrorAction.useAlternativePayment:
        return Icons.payment;
      case PaymentErrorAction.checkBalance:
        return Icons.account_balance_wallet;
      case PaymentErrorAction.installApp:
        return Icons.download;
      case PaymentErrorAction.allowPopup:
        return Icons.open_in_new;
      case PaymentErrorAction.contactSupport:
        return Icons.support_agent;
      case PaymentErrorAction.refreshPage:
        return Icons.refresh;
      case PaymentErrorAction.clearCache:
        return Icons.clear_all;
    }
  }

  String _getActionText(PaymentErrorAction action) {
    switch (action) {
      case PaymentErrorAction.retry:
        return '다시 시도';
      case PaymentErrorAction.checkNetwork:
        return '네트워크 확인';
      case PaymentErrorAction.updatePaymentMethod:
        return '결제수단 변경';
      case PaymentErrorAction.useAlternativePayment:
        return '다른 결제수단 사용';
      case PaymentErrorAction.checkBalance:
        return '잔액 확인';
      case PaymentErrorAction.installApp:
        return '앱 설치';
      case PaymentErrorAction.allowPopup:
        return '팝업 허용';
      case PaymentErrorAction.contactSupport:
        return '고객센터 문의';
      case PaymentErrorAction.refreshPage:
        return '페이지 새로고침';
      case PaymentErrorAction.clearCache:
        return '캐시 삭제';
    }
  }

  void _handleAction(BuildContext context, PaymentErrorAction action,
      PaymentError paymentError) {
    switch (action) {
      case PaymentErrorAction.retry:
        onRetry?.call();
        break;
      case PaymentErrorAction.checkNetwork:
        _showNetworkGuide(context);
        break;
      case PaymentErrorAction.updatePaymentMethod:
        _showPaymentMethodGuide(context);
        break;
      case PaymentErrorAction.useAlternativePayment:
        _showAlternativePaymentGuide(context);
        break;
      case PaymentErrorAction.checkBalance:
        _showBalanceGuide(context);
        break;
      case PaymentErrorAction.installApp:
        _showAppInstallGuide(context);
        break;
      case PaymentErrorAction.allowPopup:
        _showPopupGuide(context);
        break;
      case PaymentErrorAction.contactSupport:
        _showSupportOptions(context);
        break;
      case PaymentErrorAction.refreshPage:
        _refreshPage(context);
        break;
      case PaymentErrorAction.clearCache:
        _showCacheGuide(context);
        break;
    }
  }

  void _showNetworkGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('네트워크 확인'),
        content: const Text(
          '다음 사항을 확인해주세요:\n\n'
          '• Wi-Fi 또는 모바일 데이터 연결 상태\n'
          '• 인터넷 속도가 충분한지 확인\n'
          '• 다른 앱에서 인터넷이 정상 작동하는지 확인\n'
          '• VPN 사용 중인 경우 일시적으로 해제',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결제수단 변경'),
        content: const Text(
          '다음과 같이 해보세요:\n\n'
          '• 다른 카드로 시도\n'
          '• 카드 유효기간 및 정보 확인\n'
          '• 카드사에 문의하여 온라인 결제 차단 여부 확인\n'
          '• 간편결제나 다른 결제수단 이용',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showAlternativePaymentGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('다른 결제수단 사용'),
        content: const Text(
          '다음 결제수단을 이용해보세요:\n\n'
          '• 간편결제 (토스페이, 카카오페이 등)\n'
          '• 다른 카드\n'
          '• 계좌이체\n'
          '• 가상계좌',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showBalanceGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('잔액 확인'),
        content: const Text(
          '다음 사항을 확인해주세요:\n\n'
          '• 카드 한도 및 잔액\n'
          '• 일일/월간 결제 한도\n'
          '• 해외결제 차단 설정\n'
          '• 카드사 앱에서 실시간 한도 확인',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showAppInstallGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 설치'),
        content: const Text(
          '결제를 위해 필요한 앱을 설치해주세요:\n\n'
          '• 앱스토어에서 해당 앱 검색\n'
          '• 최신 버전으로 설치\n'
          '• 설치 후 다시 결제 시도\n'
          '• 또는 다른 결제수단 이용',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showPopupGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('팝업 허용'),
        content: const Text(
          '브라우저에서 팝업을 허용해주세요:\n\n'
          '• 주소창 옆의 팝업 차단 아이콘 클릭\n'
          '• "이 사이트에서 항상 허용" 선택\n'
          '• 페이지 새로고침 후 다시 시도\n'
          '• 또는 다른 브라우저 사용',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showCacheGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('캐시 삭제'),
        content: const Text(
          '브라우저 캐시를 삭제해보세요:\n\n'
          '• 브라우저 설정 > 개인정보 보호\n'
          '• 쿠키 및 사이트 데이터 삭제\n'
          '• 캐시된 이미지 및 파일 삭제\n'
          '• 브라우저 재시작 후 다시 시도',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _refreshPage(BuildContext context) {
    // 웹에서는 페이지 새로고침, 앱에서는 상태 초기화
    if (kIsWeb) {
      // window.location.reload(); // 웹에서 페이지 새로고침
    } else {
      // 앱에서는 상위 위젯에서 처리하도록 콜백 호출
      onRetry?.call();
    }
  }

  void _showSupportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('고객센터'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('도움이 필요하시면 다음으로 문의해주세요:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('전화 문의'),
              subtitle: const Text('1588-0000'),
              dense: true,
              onTap: () {
                // 전화 걸기 기능
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('이메일 문의'),
              subtitle: const Text('support@gonggoo.com'),
              dense: true,
              onTap: () {
                // 이메일 앱 열기
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('채팅 상담'),
              subtitle: const Text('실시간 채팅 지원'),
              dense: true,
              onTap: () {
                // 채팅 상담 열기
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
