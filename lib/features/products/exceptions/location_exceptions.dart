/// 지역 관련 예외 클래스들
class LocationTagNotFoundException implements Exception {
  final String message;

  LocationTagNotFoundException(this.message);

  @override
  String toString() => '지역 태그를 찾을 수 없습니다: $message';
}

class UnsupportedLocationException implements Exception {
  final String message;

  UnsupportedLocationException(this.message);

  @override
  String toString() => '지원하지 않는 지역입니다: $message';
}

class PickupInfoNotFoundException implements Exception {
  final String message;

  PickupInfoNotFoundException(this.message);

  @override
  String toString() => '픽업 정보를 찾을 수 없습니다: $message';
}

class LocationTagNotAvailableException implements Exception {
  final String message;

  LocationTagNotAvailableException(this.message);

  @override
  String toString() => '지역 서비스가 준비되지 않았습니다: $message';
}

class LocationValidationException implements Exception {
  final String message;

  LocationValidationException(this.message);

  @override
  String toString() => '지역 검증에 실패했습니다: $message';
}
