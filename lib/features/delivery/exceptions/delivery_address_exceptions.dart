/// 배송 주소 관련 예외 클래스들
class DeliveryAddressException implements Exception {
  final String message;
  DeliveryAddressException(this.message);

  @override
  String toString() => 'DeliveryAddressException: $message';
}

/// 배송 주소를 찾을 수 없을 때 발생하는 예외
class DeliveryAddressNotFoundException extends DeliveryAddressException {
  DeliveryAddressNotFoundException(String message) : super(message);
}

/// 배송 주소 제한 초과 예외
class DeliveryAddressLimitExceededException extends DeliveryAddressException {
  DeliveryAddressLimitExceededException(String message) : super(message);
}

/// 배송 주소 검증 실패 예외
class DeliveryAddressValidationException extends DeliveryAddressException {
  DeliveryAddressValidationException(String message) : super(message);
}