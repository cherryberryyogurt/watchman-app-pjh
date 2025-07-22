// Web-specific implementation for PaymentScreen
import 'dart:html' as html;
import 'dart:convert';

// Global reference to track payment window
html.WindowBase? _paymentWindowRef;
String? _currentOrderId;
Function? _onUnexpectedClose;

/// Sets up message listener for web environment
void setupWebMessageListener(Function(Map<String, dynamic>) onMessage) {
  print('🎧 [WEB] setupWebMessageListener 호출됨');
  print('🎧 [WEB] PostMessage 이벤트 리스너 설정 시작');

  // Listen for postMessage events
  html.window.onMessage.listen((html.MessageEvent event) {
    print('📨 [WEB] PostMessage 이벤트 수신');
    print('📨 [WEB] Event origin: ${event.origin}');
    print('📨 [WEB] Event data type: ${event.data.runtimeType}');

    try {
      // Parse the message data
      final data = event.data;
      Map<String, dynamic> messageData;

      if (data is String) {
        print('📨 [WEB] 문자열 데이터 파싱: $data');
        messageData = json.decode(data);
      } else if (data is Map) {
        print('📨 [WEB] Map 데이터 변환');
        messageData = Map<String, dynamic>.from(data);
      } else {
        print('⚠️ [WEB] 지원하지 않는 데이터 타입, 무시');
        return;
      }

      print('✅ [WEB] 메시지 파싱 성공: $messageData');
      // Call the callback with the parsed data
      onMessage(messageData);
    } catch (e) {
      print('❌ [WEB] 메시지 파싱 오류: $e');
    }
  });

  print('✅ [WEB] PostMessage 리스너 설정 완료');
}

/// Opens payment URL in a new window
html.WindowBase? openPaymentWindow(String url,
    {String? orderId, Function? onUnexpectedClose}) {
  print('🪟 [WEB] openPaymentWindow 호출됨');
  print('🪟 [WEB] URL: $url');
  print('🪟 [WEB] OrderId: $orderId');
  print('🪟 [WEB] window.open 실행 시도 (새 탭/창)');

  try {
    final newWindow = html.window.open(url, '_blank');
    print('✅ [WEB] window.open 성공');
    print('🪟 [WEB] 새 창 객체: ${newWindow != null ? 'NOT NULL' : 'NULL'}');

    if (newWindow == null) {
      print('⚠️ [WEB] 팝업이 차단되었을 가능성이 있습니다');
    } else {
      print('🎯 [WEB] 결제 창이 성공적으로 열렸습니다');

      // Store references for window monitoring
      _paymentWindowRef = newWindow;
      _currentOrderId = orderId;
      _onUnexpectedClose = onUnexpectedClose;

      // Setup window unload detection
      _setupWindowUnloadDetection();
    }

    return newWindow;
  } catch (e) {
    print('❌ [WEB] window.open 실패: $e');
    return null;
  }
}

/// Checks if a window is closed
bool isWindowClosed(html.WindowBase? window) {
  print('🔍 [WEB] isWindowClosed 호출됨');

  if (window == null) {
    print('🔍 [WEB] 창 객체가 null - 닫힌 것으로 간주');
    return true;
  }

  try {
    final isClosed = window.closed ?? true;
    print('🔍 [WEB] 창 상태 확인: ${isClosed ? 'CLOSED' : 'OPEN'}');
    return isClosed;
  } catch (e) {
    print('❌ [WEB] 창 상태 확인 오류: $e - 닫힌 것으로 간주');
    return true;
  }
}

/// Sets up window unload detection for unexpected closure
void _setupWindowUnloadDetection() {
  print('🛡️ [WEB] Window unload detection 설정 시작');

  // Store original page visibility state
  bool wasPaymentProcessing = true;

  // Monitor page visibility changes
  html.document.onVisibilityChange.listen((event) {
    print('👁️ [WEB] Page visibility changed: ${html.document.hidden}');

    if (!html.document.hidden! && wasPaymentProcessing) {
      // User returned to the app, check if payment window is closed
      if (_paymentWindowRef != null && isWindowClosed(_paymentWindowRef)) {
        print('⚠️ [WEB] Payment window closed unexpectedly');
        _handleUnexpectedWindowClose();
      }
    }
  });

  // Also check periodically in case visibility API doesn't trigger
  Future.doWhile(() async {
    await Future.delayed(Duration(seconds: 2));

    if (_paymentWindowRef != null && isWindowClosed(_paymentWindowRef)) {
      print('⚠️ [WEB] Payment window closed (periodic check)');
      _handleUnexpectedWindowClose();
      return false; // Stop checking
    }

    return _paymentWindowRef !=
        null; // Continue checking while window reference exists
  });

  print('✅ [WEB] Window unload detection 설정 완료');
}

/// Handles unexpected window closure
void _handleUnexpectedWindowClose() {
  print('🚨 [WEB] Handling unexpected window close');
  print('🚨 [WEB] Current orderId: $_currentOrderId');

  if (_onUnexpectedClose != null && _currentOrderId != null) {
    print('🚨 [WEB] Calling onUnexpectedClose callback');
    _onUnexpectedClose!(_currentOrderId);
  }

  // Clean up references
  _paymentWindowRef = null;
  _currentOrderId = null;
  _onUnexpectedClose = null;
}

/// Cleans up window monitoring resources
void cleanupWindowMonitoring() {
  print('🧹 [WEB] Cleaning up window monitoring');
  _paymentWindowRef = null;
  _currentOrderId = null;
  _onUnexpectedClose = null;
}
