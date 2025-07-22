// Stub implementation for non-web platforms

/// Sets up message listener for web environment (stub for mobile)
void setupWebMessageListener(Function(Map<String, dynamic>) onMessage) {
  // No-op on non-web platforms
}

/// Opens payment URL in a new window (stub for mobile)
dynamic openPaymentWindow(String url, {String? orderId, Function? onUnexpectedClose}) {
  return null;
}

/// Checks if a window is closed (stub for mobile)
bool isWindowClosed(dynamic window) {
  return true;
}

/// Redirects to payment URL in the same window (stub for mobile)
void redirectToPaymentUrl(String url) {
  // No-op on non-web platforms
}

/// Cleans up window monitoring resources (stub for mobile)
void cleanupWindowMonitoring() {
  // No-op on non-web platforms
}