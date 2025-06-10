/// LocationTag 관련 기본 예외 클래스
class LocationTagException implements Exception {
  final String message;

  LocationTagException(this.message);

  @override
  String toString() => 'LocationTagException: $message';
}

/// LocationTag를 찾을 수 없을 때 발생하는 예외
class LocationTagNotFoundException extends LocationTagException {
  LocationTagNotFoundException(String message) : super(message);

  @override
  String toString() => 'LocationTagNotFoundException: $message';
}

/// LocationTag 유효성 검증 실패 시 발생하는 예외
class LocationTagValidationException extends LocationTagException {
  LocationTagValidationException(String message) : super(message);

  @override
  String toString() => 'LocationTagValidationException: $message';
}

/// LocationTag 지역 불일치 시 발생하는 예외
class LocationTagRegionMismatchException extends LocationTagException {
  LocationTagRegionMismatchException(String message) : super(message);

  @override
  String toString() => 'LocationTagRegionMismatchException: $message';
}

/// LocationTag 서비스 이용 불가 지역일 때 발생하는 예외
class LocationTagUnavailableException extends LocationTagException {
  LocationTagUnavailableException(String message) : super(message);

  @override
  String toString() => 'LocationTagUnavailableException: $message';
}

/// LocationTag 중복 생성 시 발생하는 예외
class LocationTagDuplicateException extends LocationTagException {
  LocationTagDuplicateException(String message) : super(message);

  @override
  String toString() => 'LocationTagDuplicateException: $message';
}

/// 주소 파싱 실패 시 발생하는 예외
class AddressParsingException extends LocationTagException {
  AddressParsingException(String message) : super(message);

  @override
  String toString() => 'AddressParsingException: $message';
}
