// Stub implementation for non-web platforms

/// Sets up message listener for web environment (stub for mobile)
void setupWebMessageListener(Function(Map<String, dynamic>) onMessage) {
  // No-op on non-web platforms
}

/// Opens payment URL in a new window (stub for mobile)
dynamic openPaymentWindow(String url) {
  return null;
}

/// Checks if a window is closed (stub for mobile)
bool isWindowClosed(dynamic window) {
  return true;
}