// 웹 전용 토스페이먼츠 위젯 구현체
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:html' as html;

/// 웹 환경에서 토스페이먼츠 결제를 처리하는 위젯
/// 토스페이먼츠 SDK v2를 사용하여 정확한 결제 플로우를 구현합니다.
class WebTossPaymentsWidget extends StatefulWidget {
  final String clientKey;
  final String customerKey;
  final int amount;
  final String orderId;
  final String orderName;
  final String customerEmail;
  final String customerName;
  final Function(String, String, int) onSuccess; // paymentKey, orderId, amount
  final Function(String?, String?) onError; // errorCode, errorMessage
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
  State<WebTossPaymentsWidget> createState() => _WebTossPaymentsWidgetState();
}

class _WebTossPaymentsWidgetState extends State<WebTossPaymentsWidget> {
  bool _isLoading = true;
  bool _sdkLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTossPaymentsSDK();
  }

  /// 토스페이먼츠 SDK 로드 및 초기화
  void _loadTossPaymentsSDK() async {
    try {
      // SDK 스크립트가 이미 로드되었는지 확인
      if (web.document.querySelector('script[src*="js.tosspayments.com"]') ==
          null) {
        final script =
            web.document.createElement('script') as web.HTMLScriptElement;
        script.src = 'https://js.tosspayments.com/v2/payment';
        script.onload = ((JSAny? event) {
          debugPrint('✅ 토스페이먼츠 SDK v2 로드 완료');
          _initializePaymentWidget();
        }).toJS;
        script.onerror = ((JSAny? event) {
          debugPrint('❌ 토스페이먼츠 SDK 로드 실패');
          setState(() {
            _errorMessage = '결제 시스템을 불러올 수 없습니다.';
            _isLoading = false;
          });
        }).toJS;
        web.document.head!.appendChild(script);
      } else {
        // 이미 로드되어 있으면 바로 초기화
        _initializePaymentWidget();
      }
    } catch (e) {
      debugPrint('❌ SDK 로드 중 오류: $e');
      setState(() {
        _errorMessage = 'SDK 로드 중 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  /// 결제 위젯 초기화
  void _initializePaymentWidget() {
    try {
      // 토스페이먼츠 SDK 초기화 JavaScript 실행
      final jsCode = '''
        try {
          console.log('🔄 토스페이먼츠 SDK 초기화 시작');
          
          // SDK 초기화
          const tossPayments = TossPayments('${widget.clientKey}');
          const widgets = tossPayments.widgets({ 
            customerKey: '${widget.customerKey}' 
          });
          
          // 결제 금액 설정
          widgets.setAmount({
            currency: 'KRW',
            value: ${widget.amount}
          });
          
          // 결제 UI 렌더링
          widgets.renderPaymentMethods({
            selector: '#payment-method',
            variantKey: 'DEFAULT'
          });
          
          // 전역 변수로 저장 (결제 요청에서 사용)
          window.tossWidgets = widgets;
          
          // Flutter에 초기화 완료 알림
          window.postMessage({ type: 'sdk_ready' }, '*');
          
          console.log('✅ 토스페이먼츠 위젯 초기화 완료');
        } catch (error) {
          console.error('❌ 위젯 초기화 실패:', error);
          window.postMessage({ 
            type: 'sdk_error', 
            message: error.message 
          }, '*');
        }
      ''';

      // JavaScript 코드 실행을 위한 스크립트 태그 생성
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..text = jsCode;
      html.document.head!.append(script);

      // 메시지 리스너 설정
      html.window.addEventListener('message', _handleMessage);
    } catch (e) {
      debugPrint('❌ 위젯 초기화 실패: $e');
      setState(() {
        _errorMessage = '결제 위젯 초기화에 실패했습니다.';
        _isLoading = false;
      });
    }
  }

  /// JavaScript 메시지 처리
  void _handleMessage(html.Event event) {
    if (event is html.MessageEvent) {
      try {
        final data = event.data;
        if (data is Map) {
          switch (data['type']) {
            case 'sdk_ready':
              setState(() {
                _sdkLoaded = true;
                _isLoading = false;
              });
              break;
            case 'sdk_error':
              setState(() {
                _errorMessage = data['message'] ?? '알 수 없는 오류가 발생했습니다.';
                _isLoading = false;
              });
              break;
            case 'payment_success':
              widget.onSuccess(
                data['paymentKey'] ?? '',
                data['orderId'] ?? '',
                data['amount'] ?? 0,
              );
              break;
            case 'payment_error':
              widget.onError(
                data['code'],
                data['message'],
              );
              break;
          }
        }
      } catch (e) {
        debugPrint('❌ 메시지 처리 오류: $e');
      }
    }
  }

  /// 결제 요청
  void _requestPayment() {
    try {
      final jsCode = '''
        try {
          console.log('💳 결제 요청 시작');
          
          const widgets = window.tossWidgets;
          if (!widgets) {
            throw new Error('결제 위젯이 초기화되지 않았습니다.');
          }
          
          // Promise 방식으로 결제 요청 (웹 환경)
          widgets.requestPayment({
            orderId: '${widget.orderId}',
            orderName: '${widget.orderName}',
            customerEmail: '${widget.customerEmail}',
            customerName: '${widget.customerName}',
            windowTarget: 'iframe', // 웹에서는 iframe 사용
          }).then(function(result) {
            console.log('✅ 결제 성공:', result);
            window.postMessage({
              type: 'payment_success',
              paymentKey: result.paymentKey,
              orderId: result.orderId,
              amount: result.amount.value
            }, '*');
          }).catch(function(error) {
            console.error('❌ 결제 실패:', error);
            window.postMessage({
              type: 'payment_error',
              code: error.code,
              message: error.message
            }, '*');
          });
          
        } catch (error) {
          console.error('❌ 결제 요청 오류:', error);
          window.postMessage({
            type: 'payment_error',
            code: 'REQUEST_ERROR',
            message: error.message
          }, '*');
        }
      ''';

      // JavaScript 코드 실행을 위한 스크립트 태그 생성
      final script2 = html.ScriptElement()
        ..type = 'text/javascript'
        ..text = jsCode;
      html.document.head!.append(script2);
    } catch (e) {
      debugPrint('❌ 결제 요청 실패: $e');
      widget.onError('REQUEST_FAILED', '결제 요청에 실패했습니다.');
    }
  }

  @override
  void dispose() {
    html.window.removeEventListener('message', _handleMessage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제하기'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('🔒 안전한 결제 시스템을 준비 중입니다...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _loadTossPaymentsSDK();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 결제 정보
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                const Icon(Icons.payment, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  '결제 금액',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}원',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '주문번호: ${widget.orderId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 결제 수단 선택 영역
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HtmlElementView(
              viewType: 'payment-method',
              creationParams: {'id': 'payment-method'},
            ),
          ),

          const SizedBox(height: 32),

          // 결제하기 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _sdkLoaded ? _requestPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _sdkLoaded ? '결제하기' : '결제 준비 중...',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 보안 안내
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔒 안전한 결제',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '토스페이먼츠의 보안 시스템으로 안전하게 결제됩니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
