// Web-specific implementation for PaymentScreen
import 'dart:html' as html;
import 'dart:convert';

/// Sets up message listener for web environment
void setupWebMessageListener(Function(Map<String, dynamic>) onMessage) {
  // Listen for postMessage events
  html.window.onMessage.listen((html.MessageEvent event) {
    try {
      // Parse the message data
      final data = event.data;
      Map<String, dynamic> messageData;
      
      if (data is String) {
        messageData = json.decode(data);
      } else if (data is Map) {
        messageData = Map<String, dynamic>.from(data);
      } else {
        return;
      }
      
      // Call the callback with the parsed data
      onMessage(messageData);
    } catch (e) {
      print('Error parsing message: $e');
    }
  });
}

/// Opens payment URL in a new window
html.WindowBase? openPaymentWindow(String url) {
  return html.window.open(url, '_blank');
}

/// Checks if a window is closed
bool isWindowClosed(html.WindowBase? window) {
  if (window == null) return true;
  try {
    return window.closed ?? true;
  } catch (e) {
    return true;
  }
}