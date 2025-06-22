/// 🗺️ 위치 관련 통합 예외 클래스
///
/// 모든 위치, LocationTag, 주소 관련 예외를 통합 관리합니다.
library;

/// 위치 관련 기본 예외 클래스
abstract class LocationException implements Exception {
  final String message;
  final String? details;
  final Map<String, dynamic>? context;

  const LocationException(
    this.message, {
    this.details,
    this.context,
  });

  @override
  String toString() => 'LocationException: $message';
}

// =============================================================================
// LocationTag 관련 예외들
// =============================================================================

/// LocationTag를 찾을 수 없을 때 발생하는 예외
class LocationTagNotFoundException extends LocationException {
  const LocationTagNotFoundException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'LocationTagNotFoundException: $message';
}

/// LocationTag 유효성 검증 실패 시 발생하는 예외
class LocationTagValidationException extends LocationException {
  const LocationTagValidationException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'LocationTagValidationException: $message';
}

/// LocationTag 지역 불일치 시 발생하는 예외
class LocationTagRegionMismatchException extends LocationException {
  const LocationTagRegionMismatchException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'LocationTagRegionMismatchException: $message';
}

/// LocationTag 서비스 이용 불가 지역일 때 발생하는 예외
class LocationTagUnavailableException extends LocationException {
  const LocationTagUnavailableException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'LocationTagUnavailableException: $message';
}

/// LocationTag 중복 생성 시 발생하는 예외
class LocationTagDuplicateException extends LocationException {
  const LocationTagDuplicateException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'LocationTagDuplicateException: $message';
}

/// LocationTag 매핑 실패 예외
class LocationTagMappingException extends LocationException {
  const LocationTagMappingException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'LocationTagMappingException: $message';
}

/// LocationTag 생성 실패 예외
class LocationTagCreationException extends LocationException {
  const LocationTagCreationException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'LocationTagCreationException: $message';
}

// =============================================================================
// 지역 지원 관련 예외들
// =============================================================================

/// 지원하지 않는 지역일 때 발생하는 예외
class UnsupportedLocationException extends LocationException {
  const UnsupportedLocationException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'UnsupportedLocationException: $message';
}

/// 지역 서비스가 준비되지 않았을 때 발생하는 예외
class LocationServiceUnavailableException extends LocationException {
  const LocationServiceUnavailableException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'LocationServiceUnavailableException: $message';
}

// =============================================================================
// 주소 관련 예외들
// =============================================================================

/// 주소 파싱 실패 시 발생하는 예외
class AddressParsingException extends LocationException {
  const AddressParsingException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'AddressParsingException: $message';
}

/// 주소 검증 실패 시 발생하는 예외
class AddressValidationException extends LocationException {
  const AddressValidationException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'AddressValidationException: $message';
}

// =============================================================================
// 픽업 관련 예외들
// =============================================================================

/// 픽업 정보를 찾을 수 없을 때 발생하는 예외
class PickupInfoNotFoundException extends LocationException {
  const PickupInfoNotFoundException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'PickupInfoNotFoundException: $message';
}

/// 픽업 서비스 이용 불가능할 때 발생하는 예외
class PickupServiceUnavailableException extends LocationException {
  const PickupServiceUnavailableException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'PickupServiceUnavailableException: $message';
}

// =============================================================================
// 사용자 위치 관련 예외들
// =============================================================================

/// 사용자 위치 설정 관련 예외
class UserLocationException extends LocationException {
  const UserLocationException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'UserLocationException: $message';
}

/// 사용자 위치 태그가 설정되지 않았을 때 발생하는 예외
class UserLocationTagNotSetException extends UserLocationException {
  const UserLocationTagNotSetException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'UserLocationTagNotSetException: $message';
}

/// 사용자의 해당 지역 접근 권한이 없을 때 발생하는 예외
class UserLocationAccessDeniedException extends UserLocationException {
  const UserLocationAccessDeniedException(
    super.message, {
    super.details,
    super.context,
  });

  @override
  String toString() => 'UserLocationAccessDeniedException: $message';
}

// =============================================================================
// 편의 팩토리 메서드들
// =============================================================================

/// 위치 예외 생성을 위한 편의 클래스
class LocationExceptions {
  LocationExceptions._();

  /// LocationTag를 찾을 수 없음
  static LocationTagNotFoundException tagNotFound(String tagName) {
    return LocationTagNotFoundException(
      '지역 태그를 찾을 수 없습니다: $tagName',
      context: {'tagName': tagName},
    );
  }

  /// 지원하지 않는 지역
  static UnsupportedLocationException unsupportedRegion(String region) {
    return UnsupportedLocationException(
      '지원하지 않는 지역입니다: $region',
      context: {'region': region},
    );
  }

  /// 주소 파싱 실패
  static AddressParsingException addressParsingFailed(String address) {
    return AddressParsingException(
      '주소를 분석할 수 없습니다: $address',
      context: {'address': address},
    );
  }

  /// 픽업 정보 없음
  static PickupInfoNotFoundException pickupInfoNotFound(String locationTagId) {
    return PickupInfoNotFoundException(
      '픽업 정보를 찾을 수 없습니다',
      context: {'locationTagId': locationTagId},
    );
  }

  /// 사용자 위치 미설정
  static UserLocationTagNotSetException userLocationNotSet(String userId) {
    return UserLocationTagNotSetException(
      '사용자 위치가 설정되지 않았습니다',
      context: {'userId': userId},
    );
  }
}
