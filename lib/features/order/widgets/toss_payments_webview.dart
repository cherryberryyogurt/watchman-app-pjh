import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';

import '../../../core/config/payment_config.dart';
import '../screens/payment_screen.dart';

/// Toss Payments 웹뷰 컴포넌트
/// 웹뷰를 통해 Toss Payments 결제 프로세스를 진행합니다.
class TossPaymentsWebView extends StatefulWidget {
  final String orderId;
  final int amount;
  final String customerName;
  final String customerEmail;
  final PaymentMethodType paymentMethod;
  final Function(String paymentKey) onSuccess;
  final Function(String? errorMessage) onFailure;
  final VoidCallback? onLoaded;

  const TossPaymentsWebView({
    super.key,
    required this.orderId,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    required this.paymentMethod,
    required this.onSuccess,
    required this.onFailure,
    this.onLoaded,
  });

  @override
  State<TossPaymentsWebView> createState() => _TossPaymentsWebViewState();
}

class _TossPaymentsWebViewState extends State<TossPaymentsWebView> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// 웹뷰 초기화
  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('🌐 Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('🌐 Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
            widget.onLoaded?.call();
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🌐 Navigation request: ${request.url}');

            // 결제 성공/실패 URL 처리
            if (request.url.contains('/payment/success')) {
              _handlePaymentSuccess(request.url);
              return NavigationDecision.prevent;
            } else if (request.url.contains('/payment/fail')) {
              _handlePaymentFailure(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('🌐 Web resource error: ${error.description}');
            widget.onFailure('웹페이지 로딩 중 오류가 발생했습니다.');
          },
        ),
      )
      ..addJavaScriptChannel(
        'TossPayments',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message);
        },
      )
      ..loadRequest(Uri.dataFromString(
        _generatePaymentHTML(),
        mimeType: 'text/html',
        encoding: utf8,
      ));
  }

  /// 결제 HTML 생성
  String _generatePaymentHTML() {
    final paymentId = _generatePaymentId();
    final paymentMethodString = _getPaymentMethodString();
    final formattedAmount = NumberFormat('#,###').format(widget.amount);

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Toss Payments</title>
    <script src="https://js.tosspayments.com/v1/payment"></script>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f8f9fa;
        }
        .container {
            max-width: 400px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .payment-info {
            text-align: center;
            margin-bottom: 30px;
        }
        .amount {
            font-size: 24px;
            font-weight: bold;
            color: #333;
            margin: 10px 0;
        }
        .order-id {
            font-size: 14px;
            color: #666;
        }
        .payment-button {
            width: 100%;
            height: 50px;
            background-color: #3182f6;
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            margin-bottom: 10px;
        }
        .payment-button:hover {
            background-color: #1b64da;
        }
        .payment-button:disabled {
            background-color: #ccc;
            cursor: not-allowed;
        }
        .error-message {
            color: #e74c3c;
            font-size: 14px;
            text-align: center;
            margin-top: 10px;
            display: none;
        }
        .loading {
            display: none;
            text-align: center;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="payment-info">
            <h2>결제 정보</h2>
            <div class="amount">₩$formattedAmount</div>
            <div class="order-id">주문번호: ${widget.orderId}</div>
        </div>
        
        <button id="payment-button" class="payment-button">
            ${_getPaymentButtonText()}
        </button>
        
        <div id="error-message" class="error-message"></div>
        <div id="loading" class="loading">결제를 진행하고 있습니다...</div>
    </div>

    <script>
        const clientKey = '${PaymentConfig.tossClientKey}';
        const tossPayments = TossPayments(clientKey);
        
        const button = document.getElementById('payment-button');
        const errorElement = document.getElementById('error-message');
        const loadingElement = document.getElementById('loading');
        
        // 결제 정보
        const paymentData = {
            amount: ${widget.amount},
            orderId: '$paymentId',
            orderName: '${PaymentConfig.orderName}',
            customerName: '${widget.customerName}',
            customerEmail: '${widget.customerEmail}',
            successUrl: window.location.origin + '/payment/success',
            failUrl: window.location.origin + '/payment/fail',
        };
        
        button.addEventListener('click', async function() {
            try {
                button.disabled = true;
                loadingElement.style.display = 'block';
                errorElement.style.display = 'none';
                
                await tossPayments.requestPayment('$paymentMethodString', paymentData);
            } catch (error) {
                console.error('Payment error:', error);
                button.disabled = false;
                loadingElement.style.display = 'none';
                errorElement.textContent = error.message || '결제 중 오류가 발생했습니다.';
                errorElement.style.display = 'block';
                
                // Flutter로 에러 전달
                if (window.TossPayments) {
                    TossPayments.postMessage(JSON.stringify({
                        type: 'error',
                        message: error.message || '결제 중 오류가 발생했습니다.'
                    }));
                }
            }
        });
        
        // 페이지 로딩 완료 알림
        window.addEventListener('load', function() {
            if (window.TossPayments) {
                TossPayments.postMessage(JSON.stringify({
                    type: 'loaded'
                }));
            }
        });
    </script>
</body>
</html>
    ''';
  }

  /// 결제 ID 생성 (중복 방지를 위한 고유 ID)
  String _generatePaymentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return '${widget.orderId}_${timestamp}_$random';
  }

  /// 결제 수단 문자열 반환
  String _getPaymentMethodString() {
    switch (widget.paymentMethod) {
      case PaymentMethodType.card:
        return '카드';
      case PaymentMethodType.transfer:
        return '계좌이체';
    }
  }

  /// 결제 버튼 텍스트
  String _getPaymentButtonText() {
    switch (widget.paymentMethod) {
      case PaymentMethodType.card:
        return '카드로 결제하기';
      case PaymentMethodType.transfer:
        return '계좌이체로 결제하기';
    }
  }

  /// 결제 성공 처리
  void _handlePaymentSuccess(String url) {
    final uri = Uri.parse(url);
    final paymentKey = uri.queryParameters['paymentKey'];
    final orderId = uri.queryParameters['orderId'];
    final amount = uri.queryParameters['amount'];

    debugPrint(
        '🎉 Payment success: paymentKey=$paymentKey, orderId=$orderId, amount=$amount');

    if (paymentKey != null) {
      widget.onSuccess(paymentKey);
    } else {
      widget.onFailure('결제 키를 받을 수 없습니다.');
    }
  }

  /// 결제 실패 처리
  void _handlePaymentFailure(String url) {
    final uri = Uri.parse(url);
    final code = uri.queryParameters['code'];
    final message = uri.queryParameters['message'];

    debugPrint('❌ Payment failure: code=$code, message=$message');

    widget.onFailure(message ?? '결제가 실패했습니다.');
  }

  /// JavaScript 메시지 처리
  void _handleJavaScriptMessage(String message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      switch (type) {
        case 'loaded':
          debugPrint('🌐 Payment page loaded');
          break;
        case 'error':
          debugPrint('❌ JavaScript error: ${data['message']}');
          widget.onFailure(data['message']);
          break;
        default:
          debugPrint('🌐 Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('🌐 Failed to parse JavaScript message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading)
          Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('결제창을 로딩 중입니다...'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
