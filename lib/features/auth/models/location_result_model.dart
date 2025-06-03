/// 위치 검증 결과를 나타내는 모델 클래스
class LocationResultModel {
  final bool isSuccess;
  final String? locationTagId;
  final String? locationTagName;
  final String locationStatus; // "active" | "pending" | "unavailable" | "none"
  final String? pendingLocationName;
  final String? errorMessage;

  const LocationResultModel({
    required this.isSuccess,
    this.locationTagId,
    this.locationTagName,
    this.locationStatus = 'none',
    this.pendingLocationName,
    this.errorMessage,
  });

  /// 성공 케이스 팩토리 - LocationTag가 정상적으로 매핑된 경우
  factory LocationResultModel.success({
    required String locationTagId,
    required String locationTagName,
    String locationStatus = 'active',
  }) {
    return LocationResultModel(
      isSuccess: true,
      locationTagId: locationTagId,
      locationTagName: locationTagName,
      locationStatus: locationStatus,
    );
  }

  /// 대기 상태 팩토리 - 지원 지역이지만 LocationTag가 없는 경우
  factory LocationResultModel.pending(String dongName) {
    return LocationResultModel(
      isSuccess: true,
      locationStatus: 'pending',
      pendingLocationName: dongName,
    );
  }

  /// 실패 케이스 팩토리 - 지원하지 않는 지역 또는 오류 발생
  factory LocationResultModel.failure(String errorMessage) {
    return LocationResultModel(
      isSuccess: false,
      locationStatus: 'unavailable',
      errorMessage: errorMessage,
    );
  }

  /// 위치 설정 없음 - 기본 상태
  factory LocationResultModel.none() {
    return const LocationResultModel(
      isSuccess: true,
      locationStatus: 'none',
    );
  }

  /// 현재 상태가 유효한 위치 정보를 가지고 있는지 확인
  bool get hasValidLocation =>
      isSuccess && locationTagId != null && locationTagName != null;

  /// 현재 상태가 활성화된 위치인지 확인
  bool get isActiveLocation => locationStatus == 'active' && hasValidLocation;

  /// 현재 상태가 대기 중인지 확인
  bool get isPending => locationStatus == 'pending';

  /// 현재 상태가 사용 불가능한지 확인
  bool get isUnavailable => locationStatus == 'unavailable';

  /// 디버그용 문자열 표현
  @override
  String toString() {
    return 'LocationResultModel('
        'isSuccess: $isSuccess, '
        'locationTagId: $locationTagId, '
        'locationTagName: $locationTagName, '
        'locationStatus: $locationStatus, '
        'pendingLocationName: $pendingLocationName, '
        'errorMessage: $errorMessage'
        ')';
  }
}
