import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tosspayments_widget_sdk_flutter/model/tosspayments_url.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/payment_config.dart';
import '../screens/payment_screen.dart';
import '../models/payment_error_model.dart';

/// 🔒 Toss Payments 웹뷰 컴포넌트 (보안 강화됨)
///
/// 웹뷰를 통해 Toss Payments 결제 프로세스를 진행합니다.
/// Android, iOS, Web 환경을 모두 지원하며, 시크릿 키는 서버에서만 관리됩니다.
class TossPaymentsWebView extends StatefulWidget {
  final String orderId;
  final int amount;
  final String customerName;
  final String customerEmail;
  final PaymentMethodType paymentMethod;
  final Function(String paymentKey, String orderId, int amount) onSuccess;
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

    // 🔒 입력값 유효성 검증
    if (!_validateInputs()) {
      widget.onFailure('유효하지 않은 결제 정보입니다.');
      return;
    }

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

            // 웹 환경에서는 URL 변환 스킵
            if (kIsWeb) {
              return _handleWebNavigation(request.url);
            }

            // 토스페이먼츠 URL 변환 처리 (모바일만)
            return _handleMobileNavigation(request.url);
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

  /// 웹 환경에서의 네비게이션 처리
  NavigationDecision _handleWebNavigation(String url) {
    // 결제 성공/실패 URL 처리
    if (url.contains('/payment/success')) {
      _handlePaymentSuccess(url);
      return NavigationDecision.prevent;
    } else if (url.contains('/payment/fail')) {
      _handlePaymentFailure(url);
      return NavigationDecision.prevent;
    }

    // 웹에서는 모든 네비게이션을 허용
    return NavigationDecision.navigate;
  }

  /// 모바일 환경에서의 네비게이션 처리
  NavigationDecision _handleMobileNavigation(String url) {
    // 결제 성공/실패 URL 처리
    if (url.contains('/payment/success')) {
      _handlePaymentSuccess(url);
      return NavigationDecision.prevent;
    } else if (url.contains('/payment/fail')) {
      _handlePaymentFailure(url);
      return NavigationDecision.prevent;
    }

    // 토스페이먼츠 URL 변환 처리
    return _tossPaymentsWebview(url);
  }

  /// 토스페이먼츠 URL 변환 함수
  NavigationDecision _tossPaymentsWebview(String url) {
    try {
      final appScheme = ConvertUrl(url); // Intent URL을 앱스킴 URL로 변환

      if (appScheme.isAppLink()) {
        // 앱스킴 URL인지 확인
        debugPrint('🚀 외부 앱 실행: $url');
        appScheme.launchApp(
            mode:
                LaunchMode.externalApplication); // 앱 설치 상태에 따라 앱 실행 또는 마켓으로 이동
        return NavigationDecision.prevent;
      }
    } catch (e) {
      debugPrint('🔄 URL 변환 실패, 기본 처리: $e');
    }

    return NavigationDecision.navigate;
  }

  /// 🔒 결제 HTML 생성 (보안 강화됨 - XSS 방지)
  ///
  /// 클라이언트 키만 사용하여 안전한 결제 위젯 생성
  String _generatePaymentHTML() {
    // SDK v1에서는 paymentId와 paymentMethodString이 불필요
    final formattedAmount = NumberFormat('#,###').format(widget.amount);

    // 입력값 보안 검증 및 이스케이프 처리
    final sanitizedOrderId = _sanitizeInput(widget.orderId);
    final sanitizedCustomerName = _sanitizeInput(widget.customerName);
    final sanitizedCustomerEmail = _sanitizeInput(widget.customerEmail);
    final sanitizedClientKey = _sanitizeInput(PaymentConfig.tossClientKey);
    final sanitizedAmount = widget.amount.toString(); // 숫자는 안전함
    final sanitizedOrderName = _sanitizeInput(PaymentConfig.orderName);

    // 웹/모바일별 windowTarget 설정
    final windowTarget = kIsWeb ? 'self' : 'iframe';

    // 웹/모바일별 추가 스크립트
    final platformScript = kIsWeb ? _getWebScript() : _getMobileScript();

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>Toss Payments</title>
    <script src="https://js.tosspayments.com/v1/payment"></script>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f8f9fa;
            -webkit-user-select: none;
            -webkit-touch-callout: none;
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
            font-weight: 600;
            cursor: pointer;
            transition: background-color 0.2s;
        }
        .payment-button:hover {
            background-color: #2563eb;
        }
        .payment-button:disabled {
            background-color: #d1d5db;
            cursor: not-allowed;
        }
        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100px;
        }
        .spinner {
            width: 40px;
            height: 40px;
            border: 4px solid #f3f4f6;
            border-top: 4px solid #3182f6;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .error {
            color: #dc2626;
            text-align: center;
            margin-top: 20px;
        }
        #payment-method {
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="payment-info">
            <h2>결제하기</h2>
            <div class="amount">${sanitizedAmount}원</div>
            <div class="order-id">주문번호: ${_escapeJavaScript(sanitizedOrderId)}</div>
        </div>
        
        <div id="payment-method">
            <div class="loading">
                <div class="spinner"></div>
            </div>
        </div>
        
        <button id="payment-button" class="payment-button" disabled>
            결제 준비중...
        </button>
    </div>

    <script>
        // 전역 변수로 선언
        let tossPayments = null;
        let isInitialized = false;

        // SDK 스크립트가 로드되었는지 확인하는 함수
        function waitForSDK() {
            if (typeof TossPayments !== 'undefined') {
                console.log('✅ TossPayments SDK가 로드되었습니다.');
                initializePayment();
            } else {
                console.log('⏳ TossPayments SDK 로드 대기 중...');
                setTimeout(waitForSDK, 100);
            }
        }

        // 결제 초기화 함수
        function initializePayment() {
            console.log('💳 TossPaymentsWebView: 결제 초기화 시작');
            
            try {
                // 🔒 토스페이먼츠 SDK v1 초기화
                console.log('💳 TossPayments SDK 초기화 중...');
                tossPayments = TossPayments('${_escapeJavaScript(sanitizedClientKey)}');
                
                // 초기화 완료
                isInitialized = true;
                console.log('✅ 결제 초기화 완료');
                
                // 버튼 활성화
                const button = document.getElementById('payment-button');
                button.disabled = false;
                button.textContent = '결제하기';
                button.onclick = requestPayment;
                
                // 로딩 스피너 숨기기
                const paymentMethod = document.getElementById('payment-method');
                paymentMethod.innerHTML = '<p style="text-align: center; color: #666;">결제 준비가 완료되었습니다.</p>';
                
            } catch (error) {
                console.error('❌ 결제 초기화 실패:', error);
                showError(error.message || '결제 초기화에 실패했습니다.');
                
                // Flutter로 에러 전달
                if (window.TossPayments && window.TossPayments.postMessage) {
                    window.TossPayments.postMessage(JSON.stringify({
                        type: 'error',
                        message: error.message || '결제 초기화에 실패했습니다.'
                    }));
                }
            }
        }

        // 🔒 결제 요청 함수
        async function requestPayment() {
            console.log('💳 결제 요청 시작');
            const button = document.getElementById('payment-button');
            
            if (!isInitialized) {
                console.error('❌ SDK가 초기화되지 않았습니다.');
                showError('결제 시스템이 아직 준비되지 않았습니다.');
                return;
            }
            
            button.disabled = true;
            button.textContent = '결제 진행중...';
            
            try {
                // SDK v1 결제 요청
                console.log('💳 토스페이먼츠 결제창 호출');
                await tossPayments.requestPayment('카드', {
                    amount: ${sanitizedAmount},
                    orderId: '${_escapeJavaScript(sanitizedOrderId)}',
                    orderName: '${_escapeJavaScript(widget.orderId)}',
                    customerEmail: '${_escapeJavaScript(sanitizedCustomerEmail)}',
                    customerName: '구매자',
                    successUrl: '${PaymentConfig.getSuccessUrlWithParams(orderId: _escapeJavaScript(sanitizedOrderId), amount: sanitizedAmount.toString())}',
                    failUrl: '${PaymentConfig.getFailUrlWithParams(orderId: _escapeJavaScript(sanitizedOrderId))}'
                });
                
                console.log('✅ 결제창 호출 성공');
                
            } catch (error) {
                console.error('❌ 결제 요청 실패:', error);
                showError(error.message || '결제 요청에 실패했습니다.');
                button.disabled = false;
                button.textContent = '결제하기';
            }
        }
        
        // 에러 표시 함수
        function showError(message) {
            const paymentMethod = document.getElementById('payment-method');
            paymentMethod.innerHTML = '<div class="error">' + message + '</div>';
            
            // Flutter로 에러 전달
            if (window.TossPayments && window.TossPayments.postMessage) {
                window.TossPayments.postMessage(JSON.stringify({
                    type: 'error',
                    message: message
                }));
            }
        }

        // 모바일 환경 확인
        const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
        
        if (isMobile) {
            console.log('📱 모바일 환경에서 토스페이먼츠 결제 실행');
        } else {
            console.log('💻 데스크톱 환경에서 토스페이먼츠 결제 실행');
        }

        // 페이지 로드 후 SDK 확인
        window.addEventListener('DOMContentLoaded', function() {
            console.log('📄 DOM 로드 완료');
            console.log('모바일 환경 초기화 완료');
            // SDK 로드 대기
            waitForSDK();
        });
    </script>
</body>
</html>
    ''';
  }

  /// JavaScript 메시지 처리
  void _handleJavaScriptMessage(String message) {
    try {
      final data = json.decode(message);
      final type = data['type'];

      switch (type) {
        case 'success':
          final paymentKey = data['paymentKey'] as String;
          final orderId = data['orderId'] as String;
          final amount = data['amount'] as int;

          debugPrint(
              '✅ 결제 성공: PaymentKey=$paymentKey, OrderId=$orderId, Amount=$amount');
          widget.onSuccess(paymentKey, orderId, amount);
          break;

        case 'fail':
        case 'error':
          final errorMessage = data['message'] as String?;
          debugPrint('❌ 결제 실패: $errorMessage');
          widget.onFailure(errorMessage);
          break;

        default:
          debugPrint('⚠️ 알 수 없는 메시지 타입: $type');
      }
    } catch (e) {
      debugPrint('❌ JavaScript 메시지 파싱 실패: $e');
      widget.onFailure('결제 처리 중 오류가 발생했습니다.');
    }
  }

  /// 결제 성공 URL 처리
  void _handlePaymentSuccess(String url) {
    try {
      final uri = Uri.parse(url);
      final paymentKey = uri.queryParameters['paymentKey'];
      final orderId = uri.queryParameters['orderId'];
      final amount = int.tryParse(uri.queryParameters['amount'] ?? '');

      if (paymentKey != null && orderId != null && amount != null) {
        debugPrint(
            '✅ URL에서 결제 성공 정보 추출: PaymentKey=$paymentKey, OrderId=$orderId, Amount=$amount');
        widget.onSuccess(paymentKey, orderId, amount);
      } else {
        debugPrint('❌ 결제 성공 URL에서 필수 파라미터 누락');
        widget.onFailure('결제 성공 정보를 확인할 수 없습니다.');
      }
    } catch (e) {
      debugPrint('❌ 결제 성공 URL 파싱 실패: $e');
      widget.onFailure('결제 성공 정보 처리 중 오류가 발생했습니다.');
    }
  }

  /// 결제 실패 URL 처리
  void _handlePaymentFailure(String url) {
    try {
      final uri = Uri.parse(url);
      final message = uri.queryParameters['message'] ?? '결제가 취소되었습니다.';

      debugPrint('❌ URL에서 결제 실패 정보 추출: $message');
      widget.onFailure(message);
    } catch (e) {
      debugPrint('❌ 결제 실패 URL 파싱 실패: $e');
      widget.onFailure('결제가 실패했습니다.');
    }
  }

  // SDK v1에서는 결제 ID 생성과 결제 수단 문자열 변환이 불필요
  // paymentWidget에서 자동으로 처리됨

  /// 웹 환경 스크립트
  String _getWebScript() {
    return '''
        console.log('🌐 웹 환경에서 토스페이먼츠 위젯 실행');
        
        // 웹 환경 최적화
        document.addEventListener('DOMContentLoaded', function() {
            console.log('웹 환경 초기화 완료');
            
            // 팝업 차단 감지 및 대체 처리
            const originalOpen = window.open;
            window.open = function(...args) {
                console.log('🚀 팝업 열기 시도:', args[0]);
                const popup = originalOpen.apply(this, args);
                
                if (!popup || popup.closed || typeof popup.closed == 'undefined') {
                    console.warn('⚠️ 팝업이 차단되었습니다. 현재 창에서 결제를 진행합니다.');
                    // 팝업이 차단된 경우 현재 창에서 결제 진행
                    if (args[0]) {
                        window.location.href = args[0];
                    }
                    return null;
                }
                
                return popup;
            };
            
            // 웹 환경에서 결제 완료 후 처리
            window.addEventListener('beforeunload', function() {
                console.log('🌐 웹 페이지 종료 감지');
            });
            
            // Cross-Origin-Opener-Policy 지원 확인
            if (window.crossOriginIsolated !== undefined) {
                console.log('🔒 Cross-Origin-Opener-Policy 지원됨');
            }
        });
        
        // 웹 환경에서 결제 성공/실패 URL 처리
        function handleWebPaymentResult() {
            const urlParams = new URLSearchParams(window.location.search);
            const paymentKey = urlParams.get('paymentKey');
            const orderId = urlParams.get('orderId');
            const amount = urlParams.get('amount');
            
            if (paymentKey && orderId && amount) {
                console.log('✅ 웹에서 결제 성공 감지');
                if (window.TossPayments) {
                    window.TossPayments.postMessage(JSON.stringify({
                        type: 'success',
                        paymentKey: paymentKey,
                        orderId: orderId,
                        amount: parseInt(amount)
                    }));
                }
            }
            
            const errorCode = urlParams.get('code');
            const errorMessage = urlParams.get('message');
            
            if (errorCode || errorMessage) {
                console.log('❌ 웹에서 결제 실패 감지');
                if (window.TossPayments) {
                    window.TossPayments.postMessage(JSON.stringify({
                        type: 'fail',
                        message: errorMessage || '결제가 실패했습니다.'
                    }));
                }
            }
        }
        
        // 페이지 로드 시 결제 결과 확인
        window.addEventListener('load', handleWebPaymentResult);
    ''';
  }

  /// 모바일 환경 스크립트
  String _getMobileScript() {
    return '''
        console.log('📱 모바일 환경에서 토스페이먼츠 위젯 실행');
        
        // 모바일 환경 최적화
        document.addEventListener('DOMContentLoaded', function() {
            // 모바일 터치 이벤트 최적화
            document.body.style.webkitTouchCallout = 'none';
            document.body.style.webkitUserSelect = 'none';
            
            console.log('모바일 환경 초기화 완료');
        });
    ''';
  }

  /// 🔒 입력값 XSS 방지를 위한 이스케이프 처리
  String _sanitizeInput(String input) {
    if (input.isEmpty) return '';

    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;')
        .replaceAll('\\', '&#x5C;')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll('\t', '');
  }

  /// 🔒 JavaScript 문자열용 이스케이프 처리
  String _escapeJavaScript(String input) {
    if (input.isEmpty) return '';

    return input
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// 🔒 입력값 유효성 검증
  bool _validateInputs() {
    // 주문 ID 검증
    if (widget.orderId.isEmpty || widget.orderId.length > 100) {
      debugPrint('❌ 유효하지 않은 주문 ID: ${widget.orderId}');
      return false;
    }

    // 금액 검증
    if (widget.amount <= 0 || widget.amount > 100000000) {
      debugPrint('❌ 유효하지 않은 금액: ${widget.amount}');
      return false;
    }

    // 고객 정보 검증
    if (widget.customerName.isEmpty || widget.customerName.length > 50) {
      debugPrint('❌ 유효하지 않은 고객명: ${widget.customerName}');
      return false;
    }

    // 이메일 간단 검증
    if (widget.customerEmail.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(widget.customerEmail)) {
      debugPrint('❌ 유효하지 않은 이메일: ${widget.customerEmail}');
      return false;
    }

    return true;
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
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF3182F6)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '🔒 안전한 결제창을 불러오는 중...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
