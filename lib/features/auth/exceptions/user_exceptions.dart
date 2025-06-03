/// 사용자 관련 예외 클래스들
class UserLocationTagNotSetException implements Exception {
  final String message;

  UserLocationTagNotSetException(this.message);

  @override
  String toString() => '사용자 위치가 설정되지 않았습니다: $message';
}

class UserLocationAccessDeniedException implements Exception {
  final String message;

  UserLocationAccessDeniedException(this.message);

  @override
  String toString() => '해당 지역에 접근 권한이 없습니다: $message';
}

class UserAddressValidationException implements Exception {
  final String message;

  UserAddressValidationException(this.message);

  @override
  String toString() => '주소 검증에 실패했습니다: $message';
}

class UserNotFoundException implements Exception {
  final String message;

  UserNotFoundException(this.message);

  @override
  String toString() => '사용자를 찾을 수 없습니다: $message';
}
