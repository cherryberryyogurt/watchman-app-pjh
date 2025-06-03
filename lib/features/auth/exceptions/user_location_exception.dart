/// 사용자 위치 관련 예외 클래스
class UserLocationException implements Exception {
  final String message;

  UserLocationException(this.message);

  @override
  String toString() => '위치 설정 오류: $message';
}

/// 주소 검증 실패 예외
class AddressValidationException extends UserLocationException {
  AddressValidationException(String message) : super(message);

  @override
  String toString() => '주소 검증 실패: $message';
}

/// LocationTag 매핑 실패 예외
class LocationTagMappingException extends UserLocationException {
  LocationTagMappingException(String message) : super(message);

  @override
  String toString() => 'LocationTag 매핑 실패: $message';
}

/// 지원하지 않는 지역 예외
class UnsupportedRegionException extends UserLocationException {
  UnsupportedRegionException(String message) : super(message);

  @override
  String toString() => '지원하지 않는 지역: $message';
}
