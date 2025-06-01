/// 주소 입력 관련 에러 메시지 상수
class AddressErrorMessages {
  static const String addressNotFound =
      '입력하신 주소를 찾을 수 없습니다. 도로명 주소를 정확히 입력해주세요.';

  static const String locationServiceDisabled =
      '위치 서비스가 비활성화되어 있습니다. 설정에서 위치 서비스를 활성화해주세요.';

  static const String locationPermissionDenied =
      '동네 인증을 위해 위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.';

  static const String locationPermissionDeniedForever =
      '위치 권한이 영구적으로 거부되었습니다. 설정 > 앱 권한에서 위치 권한을 허용해주세요.';

  static const String network = '네트워크 연결을 확인해주세요.';

  static const String kakaoApi = '주소 검색 서비스에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';

  /// 거리가 너무 멀 때 사용하는 메시지 (distance 값을 넣어야 함)
  static String distanceTooFar(double distance) =>
      '입력하신 주소가 현재 위치에서 ${distance.toStringAsFixed(1)}km 떨어져 있습니다. 현재 위치 근처의 주소를 입력해주세요.';
}
