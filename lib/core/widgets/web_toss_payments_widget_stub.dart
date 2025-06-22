// 모바일용 토스페이먼츠 위젯 스텁 구현체
import 'package:flutter/material.dart';

/// 모바일 환경에서는 WebView를 통해 결제를 처리하므로 이 위젯은 사용되지 않습니다.
/// 컴파일 오류를 방지하기 위한 스텁 구현체입니다.
class WebTossPaymentsWidget extends StatelessWidget {
  final String clientKey;
  final String customerKey;
  final int amount;
  final String orderId;
  final String orderName;
  final String customerEmail;
  final String customerName;
  final Function(String, String, int) onSuccess;
  final Function(String?, String?) onError;
  final Function() onClose;

  const WebTossPaymentsWidget({
    super.key,
    required this.clientKey,
    required this.customerKey,
    required this.amount,
    required this.orderId,
    required this.orderName,
    required this.customerEmail,
    required this.customerName,
    required this.onSuccess,
    required this.onError,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 오류'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              '모바일 환경에서는 WebTossPaymentsWidget을 사용할 수 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'TossPaymentsWebView를 사용해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
