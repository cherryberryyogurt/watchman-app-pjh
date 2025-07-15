import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:tosspayments_widget_sdk_flutter/model/tosspayments_url.dart';

// Conditional import for web/mobile
import 'payment_screen_stub.dart'
    if (dart.library.html) 'payment_screen_web.dart' as platform;

import '../../../core/theme/color_palette.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/dimensions.dart';
import '../../../core/config/payment_config.dart';
import '../../../core/utils/tax_calculator.dart';
import '../models/order_model.dart';
import '../models/payment_error_model.dart';
import '../widgets/toss_payments_webview.dart';
import '../widgets/payment_loading_overlay.dart';
import '../services/order_service.dart';
import '../../../core/widgets/error_display_widget.dart';
import '../../auth/providers/auth_providers.dart';
import '../services/payments_service.dart';
import 'dart:ui';

// 결제 수단 타입 정의 (임시)
enum PaymentMethodType {
  card,
  transfer,
}

class PaymentScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final String paymentUrl;

  const PaymentScreen({
    super.key,
    required this.order,
    required this.paymentUrl,
  });

  static const String routeName = '/payment';

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late final WebViewController? _webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasInitiatedPayment = false; // 결제 시작 플래그
  Timer? _paymentStatusTimer; // 결제 상태 확인 타이머
  dynamic _paymentWindow; // 결제 창 참조 (웹 전용)

  // iOS 결제 결과 수신을 위한 MethodChannel
  static const MethodChannel _paymentChannel =
      MethodChannel('com.pjh.watchman/payment_result');

  @override
  void initState() {
    super.initState();

    // 🔄 TossPaymentsWebView를 사용하므로 기존 웹뷰 초기화는 제거
    // paymentUrl이 빈 문자열인 경우 TossPaymentsWebView 사용
    if (widget.paymentUrl.isEmpty) {
      debugPrint('💳 PaymentScreen: TossPaymentsWebView 사용 모드');
      _webViewController = null;

      // 🆕 웹 환경에서 자동 결제 시작 (build에서 이동)
      if (kIsWeb) {
        // 메시지 리스너 설정
        platform.setupWebMessageListener((data) {
          debugPrint('🌐 웹 메시지 수신: $data');
          _handleWebPaymentMessage(data);
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _redirectToIndependentPaymentPage();

          // 🆕 결제 타임아웃 설정 (10분)
          Timer(Duration(minutes: 10), () {
            if (mounted && _isLoading) {
              debugPrint('⏰ 결제 타임아웃 - 홈으로 이동');
              setState(() {
                _isLoading = false;
              });
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            }
          });
        });
      }
    } else {
      debugPrint('💳 PaymentScreen: 기존 WebView 사용 모드 (하위 호환성)');
      if (!kIsWeb) {
        _initializeWebView();
        _setupPaymentResultListener();
      } else {
        _webViewController = null;
      }
    }
  }

  @override
  void dispose() {
    _paymentStatusTimer?.cancel();
    _paymentStatusTimer = null;
    // 결제 창이 열려있다면 닫기
    if (kIsWeb && _paymentWindow != null) {
      debugPrint('🪟 결제 창 닫기');
    }
    super.dispose();
  }

  void _initializeWebView() {
    if (kIsWeb) return;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('🔄 결제 페이지 로드 시작: $url');
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            debugPrint('✅ 결제 페이지 로드 완료: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ 웹뷰 오류: ${error.description}');
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🔄 네비게이션 요청: ${request.url}');

            // 결제 완료 후 앱으로 돌아오는 URL 스킴 처리
            if (request.url.startsWith('gonggoo://payment')) {
              _handlePaymentResult(request.url);
              return NavigationDecision.prevent;
            }

            // 토스페이먼츠 URL 변환 처리
            return _tossPaymentsWebview(request.url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  /// 토스페이먼츠 URL 변환 함수
  NavigationDecision _tossPaymentsWebview(String url) {
    if (kIsWeb) return NavigationDecision.navigate;

    try {
      final appScheme = ConvertUrl(url);
      if (appScheme.isAppLink()) {
        appScheme.launchApp(mode: LaunchMode.externalApplication);
        return NavigationDecision.prevent;
      }
    } catch (e) {
      // Fallback: Try to open in browser
      debugPrint('App scheme conversion failed: $e');
      _launchInBrowser(url);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _launchInBrowser(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        debugPrint('❌ 브라우저 실행 불가: $url');
      }
    } catch (e) {
      debugPrint('❌ 브라우저 실행 오류: $e');
    }
  }

  // iOS에서 결제 결과를 받기 위한 리스너 설정
  void _setupPaymentResultListener() {
    if (kIsWeb || !Platform.isIOS) return;

    _paymentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPaymentResult') {
        final Map<String, dynamic> result =
            Map<String, dynamic>.from(call.arguments);
        debugPrint('💳 iOS에서 결제 결과 수신: $result');

        // URL 형태로 변환하여 기존 로직 재사용
        final queryParams =
            result.entries.map((e) => '${e.key}=${e.value}').join('&');
        final url = 'gonggoo://payment?$queryParams';

        _handlePaymentResult(url);
      }
    });
  }

  // bool _shouldLaunchExternally(String url) {
  //   // 외부 앱 실행이 필요한 URL 스킴들
  //   final externalSchemes = [
  //     'kakaotalk://',
  //     'supertoss://',
  //     'hdcardappcardansimclick://',
  //     'shinhan-sr-ansimclick://',
  //     'smshinhanansimclick://',
  //     'kb-acp://',
  //     'mpocket.online.ansimclick://',
  //     'scardcertiapp://',
  //     'lottesmartpay://',
  //     'lotteappcard://',
  //     'cloudpay://',
  //     'nhappvardansimclick://',
  //     'nhallonepayansimclick://',
  //     'citispay://',
  //     'citicardappkr://',
  //     'citimobileapp://',
  //     'itmss://',
  //     'payco://',
  //     'kftc-bankpay://',
  //     'v3mobileplusstore://',
  //     'ispmobile://',
  //     'wooripay://',
  //     'bancatcard://',
  //     'toss://',
  //     'intent://',
  //   ];

  //   return externalSchemes.any((scheme) => url.startsWith(scheme));
  // }

  // Future<void> _launchExternalApp(String url) async {
  //   if (kIsWeb) {
  //     // 웹에서는 새 탭으로 열기
  //     await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  //     return;
  //   }

  //   try {
  //     final uri = Uri.parse(url);
  //     if (await canLaunchUrl(uri)) {
  //       await launchUrl(uri, mode: LaunchMode.externalApplication);
  //     } else {
  //       debugPrint('❌ 외부 앱 실행 불가: $url');
  //       // 앱이 설치되지 않은 경우 마켓으로 이동하는 로직은 네이티브에서 처리
  //     }
  //   } catch (e) {
  //     debugPrint('❌ 외부 앱 실행 오류: $e');
  //   }
  // }

  void _handlePaymentResult(String url) {
    debugPrint('💳 결제 결과 처리: $url');

    final uri = Uri.parse(url);
    final queryParams = uri.queryParameters;

    // 결제 성공/실패 여부 확인
    final paymentKey = queryParams['paymentKey'];
    final orderId = queryParams['orderId'];
    final amount = queryParams['amount'];
    final confirmed = queryParams['confirmed'];

    if (paymentKey != null && orderId != null && amount != null) {
      if (confirmed == 'true') {
        // 이미 승인된 결제 - 성공 화면으로 바로 이동
        _navigateToSuccessScreen(paymentKey, orderId, amount);
      } else {
        // 미승인 결제 - 승인 처리 필요
        _showPaymentSuccess(paymentKey, orderId, amount);
      }
    } else {
      // 결제 실패
      final errorCode = queryParams['code'];
      final errorMessage = queryParams['message'];
      final error = PaymentError(
        code: errorCode ?? 'UNKNOWN_ERROR',
        message: errorMessage ?? '알 수 없는 오류가 발생했습니다.',
      );
      _handlePaymentFailureWithOrderCleanup(error);
    }
  }

  /// 🆕 웹 환경에서 결제 메시지 처리
  void _handleWebPaymentMessage(Map<String, dynamic> data) {
    debugPrint('🌐 웹 결제 메시지 수신: $data');

    // 결제 처리 완료 시 타이머 정리
    _paymentStatusTimer?.cancel();
    _paymentStatusTimer = null;

    // 🆕 로딩 상태 업데이트
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    final messageType = data['type'] as String?;

    switch (messageType) {
      case 'payment_confirmed':
        // 이미 승인된 결제
        final paymentKey = data['paymentKey'] as String?;
        final orderId = data['orderId'] as String?;
        final amount = data['amount']?.toString();

        if (paymentKey != null && orderId != null && amount != null) {
          _navigateToSuccessScreen(paymentKey, orderId, amount);
        }
        break;

      case 'payment_needs_confirmation':
        // 승인이 필요한 결제
        final paymentKey = data['paymentKey'] as String?;
        final orderId = data['orderId'] as String?;
        final amount = data['amount']?.toString();

        if (paymentKey != null && orderId != null && amount != null) {
          _showPaymentSuccess(paymentKey, orderId, amount);
        }
        break;

      case 'payment_error':
        // 결제 오류
        final errorMessage = data['error'] as String?;
        final error = PaymentError(
          code: 'WEB_PAYMENT_ERROR',
          message: errorMessage ?? '웹 결제 중 오류가 발생했습니다.',
        );
        _handlePaymentFailureWithOrderCleanup(error);
        break;

      case 'payment_cancelled':
        // 결제 취소
        final errorMessage = data['error'] as String?;
        final error = PaymentError(
          code: 'USER_CANCEL',
          message: errorMessage ?? '사용자가 결제를 취소했습니다.',
        );
        _handlePaymentFailureWithOrderCleanup(error);
        break;

      case 'payment_failed':
        // 결제 실패 (payment-fail.html에서 전달)
        final errorCode = data['code'] as String?;
        final errorMessage = data['message'] as String?;
        final error = PaymentError(
          code: errorCode ?? 'PAYMENT_FAILED',
          message: errorMessage ?? '결제가 실패했습니다.',
        );
        _handlePaymentFailureWithOrderCleanup(error);
        break;

      case 'payment_retry':
        // 결제 재시도 요청
        debugPrint('🔄 결제 재시도 요청 받음');
        // 현재 PaymentScreen을 닫고 다시 열기
        if (mounted) {
          Navigator.of(context).pop();
          // CheckoutScreen에서 다시 결제 시도하도록 함
        }
        break;

      case 'payment_started':
        // 🆕 결제 시작 알림 (QR 코드 스캔 등)
        debugPrint('🎯 결제 프로세스 시작됨 (QR 코드 결제 등)');
        // 사용자에게 결제 진행 중임을 표시할 수 있음
        break;

      case 'payment_window_closing':
        // 🆕 결제 창이 닫히고 있음
        debugPrint('🪟 결제 창 닫기 감지 - 결제 상태 확인 시작');
        // 결제 완료 여부를 더 적극적으로 확인
        _checkPaymentCompletionSignal();
        break;

      default:
        // 기존 메시지 타입 처리
        final paymentKey = data['paymentKey'] as String?;
        final orderId = data['orderId'] as String?;
        final amount = data['amount']?.toString();

        if (paymentKey != null && orderId != null && amount != null) {
          _showPaymentSuccess(paymentKey, orderId, amount);
        }
        break;
    }
  }

  /// 승인 완료된 결제의 성공 화면 이동
  void _navigateToSuccessScreen(
      String paymentKey, String orderId, String amount) {
    debugPrint('✅ 승인된 결제 성공 화면 이동: $paymentKey');

    // 🆕 결제 성공 시 명시적으로 PaymentScreen을 제거하고 성공 화면으로 이동
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        '/order-success',
        arguments: {
          'orderId': widget.order.orderId,
          'paymentKey': paymentKey,
          'amount': int.parse(amount),
        },
      );
    }
  }

  /// 🔒 결제 성공 처리 (보안 강화됨)
  ///
  /// Cloud Functions를 통해 서버에서 결제 승인 처리
  void _showPaymentSuccess(
      String paymentKey, String orderId, String amount) async {
    try {
      debugPrint('🔒 Cloud Functions를 통한 결제 승인 시작');

      // 로딩 오버레이 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PaymentLoadingOverlays.approving(
          onTimeout: () {
            if (mounted) {
              Navigator.of(context).pop();
              _showPaymentError(PaymentError(
                code: 'TIMEOUT',
                message: '결제 승인 처리 시간이 초과되었습니다.',
              ));
            }
          },
        ),
      );

      // OrderService를 통해 Cloud Functions 호출
      final orderService = ref.read(orderServiceProvider);
      final paymentInfo = await orderService.confirmPayment(
        orderId: orderId,
        paymentKey: paymentKey,
        amount: int.parse(amount),
      );

      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.of(context).pop();

      debugPrint('✅ 결제 승인 완료: ${paymentInfo.paymentKey}');

      // 결제 성공 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/order-success',
          arguments: {
            'orderId': widget.order.orderId,
            'paymentKey': paymentInfo.paymentKey,
            'amount': paymentInfo.totalAmount,
          },
        );
      }
    } catch (e) {
      // 로딩 오버레이 닫기
      if (mounted) Navigator.of(context).pop();

      debugPrint('❌ 결제 승인 실패: $e');

      // PaymentError로 변환하여 처리
      final paymentError = PaymentError(
        code: 'PAYMENT_CONFIRM_FAILED',
        message: e.toString(),
        details: 'Cloud Functions 호출 실패',
      );

      if (mounted) {
        _handlePaymentFailureWithOrderCleanup(paymentError);
      }
    }
  }

  /// 🆕 개선된 결제 오류 처리
  void _showPaymentError(PaymentError error) {
    // 로그 레벨에 따른 디버그 출력
    if (error.shouldIncludeDebugInfo) {
      debugPrint('❌ 결제 오류: ${error.toString()}');
    }

    // 에러 로깅
    error.log(userId: ref.read(currentUserProvider)?.uid);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: ErrorDisplayWidget(
          error: error,
          title: '결제 오류',
          showDetails: kDebugMode,
          showActions: true,
          maxWidth: 400,
          onRetry: error.isRetryable
              ? () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  // 재시도 로직 - 결제 화면 새로고침
                  if (_webViewController != null) {
                    _webViewController!.reload();
                  } else {
                    // TossPaymentsWebView 재시도는 상위에서 처리
                    setState(() {
                      _errorMessage = null;
                      _isLoading = true;
                    });
                  }
                }
              : null,
          onClose: () {
            Navigator.of(context).pop(); // 다이얼로그 닫기
            Navigator.of(context).pop('payment_cancelled'); // 결제 화면 닫기
          },
        ),
      ),
    );
  }

  /// 🆕 기존 메서드 호환성 유지
  void _showPaymentFailure(String? errorCode, String? errorMessage) {
    final error = PaymentError(
      code: errorCode ?? 'UNKNOWN_ERROR',
      message: errorMessage ?? '알 수 없는 오류가 발생했습니다.',
    );
    _showPaymentError(error);
  }

  /// 💳 결제 실패 시 대기 중인 주문 삭제 처리
  Future<void> _handlePaymentFailureWithOrderCleanup(PaymentError error) async {
    try {
      debugPrint('💳 결제 실패로 인한 주문 정리 시작: ${widget.order.orderId}');

      // 주문 서비스를 통해 pending 주문 삭제 및 재고 복구 (Firebase Functions 통해)
      final orderService = ref.read(orderServiceProvider);
      await orderService.deletePendingOrderOnPaymentFailure(
        widget.order.orderId,
        reason: '결제 실패: ${error.code} - ${error.message}',
      );

      debugPrint('✅ 결제 실패 주문 정리 완료: ${widget.order.orderId}');
    } catch (e) {
      debugPrint('⚠️ 결제 실패 주문 정리 중 오류 (결제 실패는 여전히 처리됨): $e');
      // 주문 삭제 실패는 사용자에게 별도로 알리지 않음
      // 결제 실패가 주요 이슈이므로 그것을 우선 처리
    }

    // 원래 결제 실패 처리 진행
    _showPaymentError(error);
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결제 취소'),
        content: const Text('결제를 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('계속 결제'),
          ),
          TextButton(
            onPressed: () async {
              // 컨텍스트 캡처
              final dialogContext = context;
              Navigator.of(dialogContext).pop(); // 다이얼로그 닫기

              // BuildContext를 사용하는 작업을 먼저 수행
              if (!mounted) return;

              // 로딩 다이얼로그 표시
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // pending 상태의 주문 삭제 및 재고 복구
                final orderService = ref.read(orderServiceProvider);
                await orderService.deletePendingOrderOnPaymentFailure(
                  widget.order.orderId,
                  reason: '사용자가 결제를 취소했습니다.',
                );

                debugPrint('✅ 결제 취소로 인한 주문 삭제 완료: ${widget.order.orderId}');
              } catch (e) {
                debugPrint('⚠️ 결제 취소 시 주문 삭제 실패: $e');
                // 주문 삭제 실패해도 결제 화면은 닫기
              } finally {
                // 로딩 다이얼로그 닫기 및 결제 화면 닫기
                if (mounted) {
                  Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
                  Navigator.of(context).pop('payment_cancelled'); // 결제 화면 닫기
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: ColorPalette.error,
            ),
            child: const Text('결제 취소'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('결제하기 ${kIsWeb ? '(웹)' : '(모바일)'}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showCancelConfirmation();
          },
        ),
      ),
      body: kIsWeb ? _buildWebView() : _buildMobileView(),
    );
  }

  /// 웹 환경용 뷰
  Widget _buildWebView() {
    // 🆕 결제 시작은 initState에서 처리하므로 여기서는 UI만 표시
    // 리다이렉트 중 표시할 로딩 화면
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('결제 페이지로 이동 중...'),
        ],
      ),
    );
  }

  /// 독립 결제 페이지로 리다이렉트
  void _redirectToIndependentPaymentPage() {
    // 🆕 강화된 중복 결제 방지
    if (_hasInitiatedPayment) {
      debugPrint('⚠️ 이미 결제가 시작되었습니다. 중복 실행 방지');
      return;
    }

    // 🆕 웹 환경이 아닌 경우 실행하지 않음
    if (!kIsWeb) {
      debugPrint('⚠️ 웹 환경이 아님. 결제 페이지 리다이렉트 취소');
      return;
    }

    _hasInitiatedPayment = true;
    debugPrint('🚀 독립 결제 페이지 리다이렉트 시작 (주문: ${widget.order.orderId})');

    final tossPaymentsService = ref.read(tossPaymentsServiceProvider);

    // payments_service에서 설정 가져오기
    final paymentConfig = tossPaymentsService.getPaymentWidgetConfig(
      orderId: widget.order.orderId,
      amount: widget.order.totalAmount,
      orderName: 'w${widget.order.orderId}',
      // customerEmail: '${widget.order.userId}@example.com',
      customerEmail: '',
      customerName: widget.order.userId,
      suppliedAmount: widget.order.suppliedAmount,
      vat: widget.order.vat,
      taxFreeAmount: widget.order.taxFreeAmount,
      autoPayment: true, // 🆕 자동 결제 모드 활성화
    );

    // 웹 환경에서만 실행
    if (paymentConfig['isWeb'] == true) {
      final paymentUrl = paymentConfig['paymentUrl'] as String;

      // 결제 완료 후 메시지 수신을 위한 리스너 설정
      _setupWebMessageListener();

      // 🆕 새 창에서 결제 페이지 열기 (에러 처리 추가)
      if (kIsWeb) {
        debugPrint('🌐 새 창에서 결제 페이지 열기: $paymentUrl');
        try {
          // 웹 전용 window.open 사용
          _paymentWindow = platform.openPaymentWindow(paymentUrl);
          debugPrint('✅ 결제 페이지 열기 성공');

          // 결제 창 상태 모니터링 시작
          _startPaymentWindowMonitoring();
        } catch (e) {
          debugPrint('❌ 결제 페이지 열기 실패: $e');
          // 실패 시 플래그 리셋하여 재시도 가능하게 함
          _hasInitiatedPayment = false;
        }
      }
    }
  }

  /// 웹 환경에서 결제 결과 메시지 수신
  void _setupWebMessageListener() {
    // 웹 환경에서만 실행
    if (!kIsWeb) return;

    // PostMessage를 통한 결제 결과 수신 리스너 설정
    debugPrint('🌐 웹 결제 메시지 리스너 설정');

    // 웹 환경에서 window.addEventListener를 사용하여 postMessage 수신
    // dart:html 패키지를 사용하면 트리 쉐이킹 문제가 있으므로
    // dart:js_interop을 사용하여 처리
    try {
      // JavaScript interop을 사용하여 message 이벤트 리스너 추가
      _setupJsMessageListener();

      debugPrint('🌐 postMessage 리스너 설정 완료');
    } catch (e) {
      debugPrint('⚠️ 웹 메시지 리스너 설정 실패: $e');
    }

    // URL 쿼리 파라미터를 통한 결제 결과 확인 (fallback)
    // 웹에서 리다이렉트로 돌아온 경우 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForWebPaymentResult();
    });

    // 간단한 polling 방식으로 결제 완료 확인
    // 실제 프로덕션에서는 더 효율적인 방법 사용 권장
    _startPaymentStatusPolling();
  }

  /// JavaScript message 이벤트 리스너 설정 (단순화된 구현)
  void _setupJsMessageListener() {
    if (!kIsWeb) return;

    debugPrint('🌐 웹 환경 메시지 리스너 설정 (폴링 방식)');

    // 웹 환경에서는 URL 기반 폴링과 로컬스토리지를 통한 메시지 전달 사용
    // 실제 postMessage 리스너는 payment-success.html과 payment-fail.html에서 처리

    Timer? messageCheckTimer;
    messageCheckTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // URL fragment나 query parameter 변화 감지
      _checkForWebPaymentResult();
    });

    // 5분 후 타이머 정리
    Timer(Duration(minutes: 5), () {
      messageCheckTimer?.cancel();
    });
  }

  /// 웹 환경에서 메시지 수신 시뮬레이션 (테스트용)
  void _simulatePaymentMessage(Map<String, dynamic> data) {
    if (!kIsWeb || !mounted) return;

    debugPrint('🧪 결제 메시지 시뮬레이션: $data');
    _handleWebPaymentMessage(data);
  }

  /// 🆕 결제 창 모니터링 시작
  void _startPaymentWindowMonitoring() {
    if (!kIsWeb || _paymentWindow == null) return;

    debugPrint('🔍 결제 창 모니터링 시작');

    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // 결제 창이 닫혔는지 확인
      if (platform.isWindowClosed(_paymentWindow)) {
        debugPrint('🪟 결제 창이 닫혔습니다 - 결제 완료 처리');
        timer.cancel();

        // 결제 창이 닫혔으므로 상태 확인
        _checkPaymentCompletionAfterWindowClose();
      }
    });
  }

  /// 🆕 결제 창이 닫힌 후 완료 처리
  void _checkPaymentCompletionAfterWindowClose() {
    debugPrint('💳 결제 창 닫힘 - 결제 상태 최종 확인');

    // 잠시 대기 후 상태 확인 (메시지가 도착할 시간을 줌)
    Timer(Duration(seconds: 2), () {
      if (!mounted) return;

      // 메시지를 받지 못했다면 주문 상태 확인 시도
      if (_isLoading) {
        debugPrint('⚠️ 결제 결과를 받지 못했습니다 - 주문 상태 확인');
        _checkOrderStatusFallback();
      }
    });
  }

  /// 🆕 결제 결과 메시지를 받지 못한 경우 주문 상태 확인
  void _checkOrderStatusFallback() async {
    try {
      // 주문 상태를 확인하여 결제 완료 여부 판단
      final orderService = ref.read(orderServiceProvider);
      // 실제 구현에서는 주문 상태 API 호출
      // 현재는 홈으로 이동 (사용자가 주문 내역에서 확인 가능)

      debugPrint('💳 주문 상태 확인 후 홈으로 이동');

      if (mounted) {
        // 로딩 상태 해제
        setState(() {
          _isLoading = false;
        });

        // 홈으로 이동
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      debugPrint('❌ 주문 상태 확인 실패: $e');

      if (mounted) {
        // 로딩 상태 해제
        setState(() {
          _isLoading = false;
        });

        // 홈으로 이동
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  /// 결제 상태 폴링 시작 (웹 환경에서만)
  void _startPaymentStatusPolling() {
    if (!kIsWeb) return;

    debugPrint('🔄 결제 상태 폴링 시작 (QR 결제 대응)');

    // 🆕 QR 결제 완료 감지를 위한 더 자주 확인
    _paymentStatusTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _checkForWebPaymentResult();

      // 🆕 LocalStorage나 다른 방법으로 결제 완료 신호 확인
      _checkPaymentCompletionSignal();
    });

    // 10분 후 타이머 정리 (QR 결제는 시간이 더 걸릴 수 있음)
    Timer(Duration(minutes: 10), () {
      _paymentStatusTimer?.cancel();
      _paymentStatusTimer = null;
      debugPrint('🕐 결제 상태 폴링 타임아웃');
    });
  }

  /// 🆕 결제 완료 신호 확인 (QR 결제 대응)
  void _checkPaymentCompletionSignal() {
    if (!kIsWeb || !mounted) return;

    // 여기서는 임시로 URL 변화나 다른 신호를 감지
    // 실제로는 LocalStorage나 다른 저장소를 통해 신호를 받을 수 있음
    final currentUrl = Uri.base.toString();

    // QR 결제 완료 후 리다이렉트 URL 패턴 감지
    if (currentUrl.contains('payment-success') ||
        currentUrl.contains('order-success') ||
        currentUrl.contains('paymentKey=')) {
      debugPrint('🎯 QR 결제 완료 신호 감지: $currentUrl');

      // URL에서 결제 정보 추출
      final uri = Uri.parse(currentUrl);
      final paymentKey = uri.queryParameters['paymentKey'];
      final orderId = uri.queryParameters['orderId'];
      final amount = uri.queryParameters['amount'];

      if (paymentKey != null && orderId != null && amount != null) {
        _handleWebPaymentMessage({
          'type': 'payment_confirmed',
          'paymentKey': paymentKey,
          'orderId': orderId,
          'amount': int.tryParse(amount) ?? 0,
        });
      }
    }
  }

  /// 웹 환경에서 URL 파라미터로 결제 결과 확인
  void _checkForWebPaymentResult() {
    if (!kIsWeb) return;

    final uri = Uri.base;
    final fragment = uri.fragment;

    // Flutter 웹 라우팅에서 #/payment/confirm 등의 경로 처리
    if (fragment.contains('/payment/confirm')) {
      final queryStart = fragment.indexOf('?');
      if (queryStart != -1) {
        final queryString = fragment.substring(queryStart + 1);
        final queryParams = Uri.splitQueryString(queryString);

        final paymentKey = queryParams['paymentKey'];
        final orderId = queryParams['orderId'];
        final amount = queryParams['amount'];

        if (paymentKey != null && orderId != null && amount != null) {
          // 승인이 필요한 결제로 처리
          _handleWebPaymentMessage({
            'type': 'payment_needs_confirmation',
            'paymentKey': paymentKey,
            'orderId': orderId,
            'amount': int.tryParse(amount) ?? 0,
          });
        }
      }
    } else if (fragment.contains('/payment/complete')) {
      final queryStart = fragment.indexOf('?');
      if (queryStart != -1) {
        final queryString = fragment.substring(queryStart + 1);
        final queryParams = Uri.splitQueryString(queryString);

        final paymentKey = queryParams['paymentKey'];
        final orderId = queryParams['orderId'];
        final amount = queryParams['amount'];
        final confirmed = queryParams['confirmed'];

        if (paymentKey != null && orderId != null && amount != null) {
          if (confirmed == 'true') {
            // 이미 승인된 결제
            _handleWebPaymentMessage({
              'type': 'payment_confirmed',
              'paymentKey': paymentKey,
              'orderId': orderId,
              'amount': int.tryParse(amount) ?? 0,
            });
          } else {
            // 승인이 필요한 결제
            _handleWebPaymentMessage({
              'type': 'payment_needs_confirmation',
              'paymentKey': paymentKey,
              'orderId': orderId,
              'amount': int.tryParse(amount) ?? 0,
            });
          }
        }
      }
    } else if (fragment.contains('/payment/failed')) {
      final queryStart = fragment.indexOf('?');
      if (queryStart != -1) {
        final queryString = fragment.substring(queryStart + 1);
        final queryParams = Uri.splitQueryString(queryString);

        final errorMessage = queryParams['error'];
        final error = PaymentError(
          code: 'WEB_PAYMENT_FAILED',
          message: errorMessage ?? '결제 실패',
        );
        _handlePaymentFailureWithOrderCleanup(error);
      }
    }
  }

  /// 🆕 환불 정책 다이얼로그 표시
  void _showRefundPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '<와치맨 공동구매 반품/교환/환불 정책>',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '''1. 기본 원칙
당사는 『전자상거래 등에서의 소비자보호에 관한 법률』에 따라, 소비자의 권리를 보호하며 다음과 같은 기준으로 반품, 교환, 환불을 처리합니다.

2. 반품 및 교환 가능 기간
- 신선식품(농수축산물)의 경우 수령일로부터 2일 이내, 영업시간 내에 접수된 경우만 가능
- 가공식품 등 기타 상품의 경우 수령일로부터 7일 이내, 영업시간 내에 접수된 경우만 가능
- 수령일이 불분명한 경우, 배송완료를 공지한 날(픽업/직접배송) 또는 배송완료로 표시된 날(택배발송) 기준으로 산정

3. 반품 및 교환이 가능한 경우
- 상품에 하자가 있는 경우 (파손, 부패, 오배송 등)
- 제품이 소비자의 과실 없이 변질·손상된 경우
- 판매자의 귀책사유로 인해 제품에 하자가 발생한 경우
- 표시·광고 내용과 다르거나, 계약 내용과 다르게 이행된 경우
- 동일 상품으로의 교환 요청이 어려울 경우, 환불로 처리
- 농수산물의 경우, 당일 수령 후 2일 이내 상태 이상 발견 시 사진과 함께 영업시간 내 고객센터로 연락

4. 반품 및 교환이 불가능한 경우
- 소비자 귀책 사유로 상품이 멸실·훼손된 경우
- 소비자의 사용 또는 일부 소비로 상품의 가치가 현저히 감소한 경우
- 신선식품(농산물 등) 특성상 단순 변심, 외관 또는 맛과 같은 주관적인 요소가 반영될 수 있는 사유로 인한 반품은 불가
- 공동구매 특성상 수령 장소 및 시간에 맞춰 수령하지 않아 발생한 품질 저하 또는 유통문제

5. 환불 처리
- 환불은 카드결제 취소 또는 계좌환불 방식으로 진행됩니다.
- PG사 결제 취소 기준에 따라 영업일 기준 3~7일 이내 처리됩니다.
- 카드결제의 경우, 승인 취소는 카드사 정책에 따라 시일이 소요될 수 있습니다.
- 현금결제(무통장 입금) 환불 시, 정확한 계좌 정보를 고객이 제공해야 하며, 제공된 계좌 정보 오류로 인한 불이익은 책임지지 않습니다.

6. 고객 문의처
- 어플 내 [고객문의] 메뉴
- 각 오픈채팅방 내 CS담당자
- 카카오톡 '와치맨컴퍼니'
- 고객센터 010-6486-2591
- 운영시간: 오전 10시 ~ 오후 6시
- 문의 접수 후 영업일 기준 1~2일 내 회신 드립니다.

7. 기타
본 정책은 소비자 보호와 서비스 신뢰 유지를 위한 기준이며, 공동구매 특성상 일부 사항은 사전 고지 없이 변경될 수 있습니다. 변경 시, 어플 공지사항 및 약관 페이지를 통해 고지합니다.''',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
      ),
    );
  }

  /// 모바일 환경용 뷰
  Widget _buildMobileView() {
    return Column(
      children: [
        Expanded(
          child: _buildPaymentView(),
        ),
        _buildPolicyLink(),
      ],
    );
  }

  /// 🆕 환불 정책 링크 위젯
  Widget _buildPolicyLink() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: Dimensions.spacingSm, horizontal: Dimensions.spacingMd),
      child: GestureDetector(
        onTap: _showRefundPolicyDialog,
        child: Text(
          '와치맨 공동구매 반품/교환/환불 정책 보기',
          style: TextStyles.bodySmall.copyWith(
            color: ColorPalette.textSecondaryLight,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  /// 🆕 분리된 결제 뷰 위젯
  Widget _buildPaymentView() {
    // 🔄 TossPaymentsWebView 사용 모드인 경우
    if (widget.paymentUrl.isEmpty) {
      // 🆕 주문에서 세금 정보 생성
      final taxBreakdown = OrderTaxBreakdown(
        suppliedAmount: widget.order.suppliedAmount,
        vat: widget.order.vat,
        taxFreeAmount: widget.order.taxFreeAmount,
        totalAmount: widget.order.totalAmount,
      );

      return TossPaymentsWebView(
        orderId: widget.order.orderId,
        amount: widget.order.totalAmount,
        customerName: widget.order.userId, // 실제로는 사용자 이름으로 변경 필요
        customerEmail: '${widget.order.userId}@example.com',
        paymentMethod: PaymentMethodType.card,
        taxBreakdown: taxBreakdown, // 🆕 세금 정보 전달
        onSuccess: (paymentKey, orderId, amount) {
          debugPrint('📱 모바일 결제 성공: $paymentKey, $orderId, $amount');
          _showPaymentSuccess(paymentKey, orderId, amount.toString());
        },
        onFailure: (errorMessage) {
          debugPrint('📱 모바일 결제 실패: $errorMessage');
          final error = PaymentError(
            code: 'PAYMENT_FAILED',
            message: errorMessage ?? '결제가 실패했습니다.',
          );
          _handlePaymentFailureWithOrderCleanup(error);
        },
        onLoaded: () {
          debugPrint('📱 모바일 결제창 로드 완료');
        },
      );
    }

    // 🔄 기존 WebView 사용 모드 (하위 호환성)
    return Stack(
      children: [
        if (_webViewController != null)
          WebViewWidget(controller: _webViewController!),

        // 로딩 인디케이터
        if (_isLoading)
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: ColorPalette.primary,
                  ),
                  const SizedBox(height: Dimensions.spacingMd),
                  Text(
                    '결제 페이지를 불러오는 중입니다...',
                    style: TextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

        // 오류 메시지
        if (_errorMessage != null)
          Container(
            color: Colors.white,
            child: Center(
              child: ErrorDisplayWidget(
                error: PaymentError(
                  code: 'WEBVIEW_ERROR',
                  message: _errorMessage!,
                ),
                title: '페이지 로딩 오류',
                showDetails: kDebugMode,
                showActions: true,
                maxWidth: 350,
                onRetry: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _webViewController?.reload();
                },
                onClose: () {
                  Navigator.of(context).pop('payment_cancelled');
                },
              ),
            ),
          ),
      ],
    );
  }
}
