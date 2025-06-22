import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../location/models/location_tag_model.dart';
import '../../location/repositories/location_tag_repository.dart';
import '../services/kakao_map_service.dart';

/// 🌍 사용자 위치 관련 서비스
///
/// 이 서비스는 다음 기능들을 담당합니다:
/// - 주소 검증 및 GPS 위치 확인
/// - 카카오맵 API를 통한 주소-좌표 변환
/// - LocationTag 매핑 및 검증
/// - 위치 기반 사용자 등록 및 업데이트
class UserLocationService {
  final AuthRepository _authRepository;
  final LocationTagRepository _locationTagRepository;
  final KakaoMapService _kakaoMapService;

  UserLocationService({
    required AuthRepository authRepository,
    required LocationTagRepository locationTagRepository,
    required KakaoMapService kakaoMapService,
  })  : _authRepository = authRepository,
        _locationTagRepository = locationTagRepository,
        _kakaoMapService = kakaoMapService;

  /// 📍 위치 정보와 함께 새 사용자 등록
  ///
  /// [name] 사용자 이름
  /// [inputAddress] 사용자가 입력한 주소
  /// [phoneNumber] 전화번호 (선택사항)
  Future<UserModel> registerUserWithLocation({
    required String name,
    required String inputAddress,
    String? phoneNumber,
  }) async {
    try {
      if (kDebugMode) {
        print('🌍 UserLocationService: Registering user with location');
        print('🌍 Name: $name, Address: $inputAddress');
      }

      // 1. 주소 검증 및 좌표 변환
      final addressInfo = await _validateAndConvertAddress(inputAddress);

      // 2. LocationTag 매핑
      final locationResult = await _mapLocationTag(addressInfo.dongName);

      // 3. 사용자 등록
      final user = await _authRepository.signUp(
        name: name,
        phoneNumber: phoneNumber,
        roadNameAddress: addressInfo.roadNameAddress,
        locationAddress: addressInfo.locationAddress,
        locationTagId: locationResult.locationTagId,
        locationTagName: locationResult.locationTagName,
        locationStatus: locationResult.locationStatus,
        pendingLocationName: locationResult.pendingLocationName,
      );

      if (kDebugMode) {
        print('🎉 UserLocationService: User registration completed');
        print('🎉 Status: ${user.locationStatus}');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserLocationService: Registration failed: $e');
      }
      rethrow;
    }
  }

  /// 📍 기존 사용자의 위치 정보 업데이트
  ///
  /// [uid] 사용자 ID
  /// [inputAddress] 새로운 주소
  Future<UserModel> updateUserLocation({
    required String uid,
    required String inputAddress,
  }) async {
    try {
      if (kDebugMode) {
        print('🌍 UserLocationService: Updating user location');
        print('🌍 UID: $uid, Address: $inputAddress');
      }

      // 1. 주소 검증 및 좌표 변환
      final addressInfo = await _validateAndConvertAddress(inputAddress);

      // 2. LocationTag 매핑
      final locationResult = await _mapLocationTag(addressInfo.dongName);

      // 3. 사용자 정보 업데이트
      final user = await _authRepository.updateUserProfile(
        uid: uid,
        roadNameAddress: addressInfo.roadNameAddress,
        locationAddress: addressInfo.locationAddress,
        locationTagId: locationResult.locationTagId,
        locationTagName: locationResult.locationTagName,
        locationStatus: locationResult.locationStatus,
        pendingLocationName: locationResult.pendingLocationName,
      );

      if (kDebugMode) {
        print('🎉 UserLocationService: Location update completed');
        print('🎉 Status: ${user.locationStatus}');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserLocationService: Location update failed: $e');
      }
      rethrow;
    }
  }

  /// 📍 기존 사용자 프로필 저장 (위치 포함)
  Future<UserModel> saveExistingUserWithLocation({
    required String uid,
    required String name,
    required String inputAddress,
    String? phoneNumber,
  }) async {
    try {
      if (kDebugMode) {
        print('🌍 UserLocationService: Saving existing user with location');
        print('🌍 UID: $uid, Address: $inputAddress');
      }

      // 1. 주소 검증 및 좌표 변환
      final addressInfo = await _validateAndConvertAddress(inputAddress);

      // 2. LocationTag 매핑
      final locationResult = await _mapLocationTag(addressInfo.dongName);

      // 3. 기존 사용자 프로필 저장
      final user = await _authRepository.saveUserProfileForExistingUser(
        uid: uid,
        name: name,
        phoneNumber: phoneNumber,
        roadNameAddress: addressInfo.roadNameAddress,
        locationAddress: addressInfo.locationAddress,
        locationTagId: locationResult.locationTagId,
        locationTagName: locationResult.locationTagName,
        locationStatus: locationResult.locationStatus,
        pendingLocationName: locationResult.pendingLocationName,
      );

      if (kDebugMode) {
        print('🎉 UserLocationService: Existing user profile saved');
        print('🎉 Status: ${user.locationStatus}');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserLocationService: Save existing user failed: $e');
      }
      rethrow;
    }
  }

  /// 🚀 위치 정보 없이 사용자 등록
  Future<UserModel> registerUserWithoutLocation({
    required String name,
    String? phoneNumber,
  }) async {
    try {
      if (kDebugMode) {
        print('🌍 UserLocationService: Registering user without location');
      }

      final user = await _authRepository.signUp(
        name: name,
        phoneNumber: phoneNumber,
        locationStatus: 'none',
      );

      if (kDebugMode) {
        print('🎉 UserLocationService: User registered without location');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ UserLocationService: Registration without location failed: $e');
      }
      rethrow;
    }
  }

  /// 📍 사용자 위치 상태만 업데이트 (주소 변경 없이)
  Future<UserModel> updateLocationStatus({
    required String uid,
    required String dongName,
  }) async {
    try {
      if (kDebugMode) {
        print('🌍 UserLocationService: Updating location status only');
        print('🌍 UID: $uid, DongName: $dongName');
      }

      // LocationTag 매핑
      final locationResult = await _mapLocationTag(dongName);

      // 위치 상태만 업데이트
      final user = await _authRepository.updateUserProfile(
        uid: uid,
        locationTagId: locationResult.locationTagId,
        locationTagName: locationResult.locationTagName,
        locationStatus: locationResult.locationStatus,
        pendingLocationName: locationResult.pendingLocationName,
      );

      if (kDebugMode) {
        print('🎉 UserLocationService: Location status updated');
        print('🎉 Status: ${user.locationStatus}');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserLocationService: Location status update failed: $e');
      }
      rethrow;
    }
  }

  /// 🔍 사용자의 현재 위치 상태 조회
  Future<LocationResult> getUserLocationStatus(String uid) async {
    try {
      if (kDebugMode) {
        print('🔍 UserLocationService: Getting user location status for: $uid');
      }

      final user = await _authRepository.getCurrentUser();
      if (user == null || user.uid != uid) {
        throw UserLocationException('사용자 정보를 찾을 수 없습니다');
      }

      // 현재 사용자의 위치 상태를 LocationResult로 변환
      if (user.hasActiveLocationTag) {
        return LocationResult.success(
          locationTagId: user.locationTagId!,
          locationTagName: user.locationTagName!,
          locationStatus: user.locationStatus,
        );
      } else if (user.isLocationPending) {
        return LocationResult.pending(user.pendingLocationName ?? '알 수 없는 지역');
      } else if (user.isLocationUnavailable) {
        return LocationResult.failure('지원하지 않는 지역입니다');
      } else {
        return LocationResult.none();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserLocationService: Failed to get user location status: $e');
      }
      throw UserLocationException('사용자 위치 상태 조회에 실패했습니다: $e');
    }
  }

  /// 🏠 지원 지역 목록 조회
  Future<List<LocationTagModel>> getSupportedRegions() async {
    try {
      if (kDebugMode) {
        print('🏠 UserLocationService: Getting supported regions');
      }
      return await _locationTagRepository.getSupportedRegions();
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserLocationService: Failed to get supported regions: $e');
      }
      throw UserLocationException('지원 지역 목록 조회에 실패했습니다: $e');
    }
  }

  // Private Methods

  /// 🔍 주소 검증 및 좌표 변환
  Future<AddressInfo> _validateAndConvertAddress(String inputAddress) async {
    try {
      if (kDebugMode) {
        print('🔍 UserLocationService: Validating address: $inputAddress');
      }

      // 1. 카카오맵 API로 좌표 검색
      final coordsResult =
          await _kakaoMapService.getCoordsFromAddress(inputAddress);
      final searchedLatitude = coordsResult['latitude']!;
      final searchedLongitude = coordsResult['longitude']!;

      // 2. 좌표로 상세 주소 정보 조회
      final addressInfo = await _kakaoMapService.getAddressFromCoords(
        latitude: searchedLatitude,
        longitude: searchedLongitude,
      );

      // 3. 동(dong) 이름 추출 - locationTag에서 구/군 이름 추출
      final dongName = _extractDongName(addressInfo.locationTag);

      final roadNameAddress = addressInfo.roadNameAddress;
      final locationAddress = addressInfo.locationAddress;

      // 2. GPS 위치 확인 및 거리 검증
      await _validateDistanceWithGPS(searchedLatitude, searchedLongitude);

      if (kDebugMode) {
        print('🔍 UserLocationService: Address validation completed');
        print('🔍 Extracted dongName: $dongName');
      }

      return AddressInfo(
        roadNameAddress: roadNameAddress,
        locationAddress: locationAddress,
        dongName: dongName,
        latitude: searchedLatitude,
        longitude: searchedLongitude,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserLocationService: Address validation failed: $e');
      }
      if (e is AddressValidationException) rethrow;
      throw AddressValidationException('주소 검증에 실패했습니다: $e');
    }
  }

  /// 📍 위치 태그에서 동 이름 추출
  String _extractDongName(String locationTag) {
    // locationTag 형식: "서울특별시 강남구" -> "강남구"를 추출
    final parts = locationTag.split(' ');
    if (parts.length >= 2) {
      return parts[1]; // 구/군 이름 반환
    }
    return locationTag; // 파싱 실패시 전체 반환
  }

  /// 📏 GPS 위치와의 거리 검증
  Future<void> _validateDistanceWithGPS(
      double targetLat, double targetLng) async {
    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationPermissionException('위치 서비스가 비활성화되어 있습니다');
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationPermissionException('위치 권한이 거부되었습니다');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionException('위치 권한이 영구적으로 거부되었습니다');
      }

      // 현재 위치 가져오기
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // 거리 계산
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLat,
        targetLng,
      );

      // 10km 이내 검증
      const maxDistance = 10000; // 10km in meters
      if (distance > maxDistance) {
        throw DistanceValidationException(
            '입력하신 주소가 현재 위치에서 너무 멀리 떨어져 있습니다 (${(distance / 1000).toStringAsFixed(1)}km)');
      }

      if (kDebugMode) {
        print(
            '📏 Distance validation passed: ${(distance / 1000).toStringAsFixed(1)}km');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GPS distance validation failed: $e');
      }
      rethrow;
    }
  }

  /// 🗺️ LocationTag 매핑 및 검증
  Future<LocationResult> _mapLocationTag(String dongName) async {
    try {
      if (kDebugMode) {
        print('🏠 UserLocationService: Mapping LocationTag for: $dongName');
      }

      // 1. 지원 지역 확인
      final isSupported =
          await _locationTagRepository.isValidLocationTagName(dongName);

      if (!isSupported) {
        if (kDebugMode) {
          print('🏠 UserLocationService: Unsupported region: $dongName');
        }
        return LocationResult.failure('$dongName은 아직 지원하지 않는 지역입니다.');
      }

      // 2. LocationTag 존재 여부 확인
      final locationTag =
          await _locationTagRepository.getLocationTagByName(dongName);

      if (locationTag != null && locationTag.isActive) {
        if (kDebugMode) {
          print('🏠 UserLocationService: Active LocationTag found');
        }
        return LocationResult.success(
          locationTagId: locationTag.id,
          locationTagName: locationTag.name,
          locationStatus: 'active',
        );
      }

      // 3. 지원 지역이지만 LocationTag가 없는 경우 - 대기 상태로 설정
      if (kDebugMode) {
        print(
            '🏠 UserLocationService: LocationTag not available, setting to pending');
      }
      return LocationResult.pending(dongName);
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserLocationService: LocationTag mapping failed: $e');
      }
      return LocationResult.failure('위치 설정 중 오류가 발생했습니다: $e');
    }
  }
}

/// 📍 주소 정보 클래스
class AddressInfo {
  final String roadNameAddress;
  final String locationAddress;
  final String dongName;
  final double latitude;
  final double longitude;

  AddressInfo({
    required this.roadNameAddress,
    required this.locationAddress,
    required this.dongName,
    required this.latitude,
    required this.longitude,
  });
}

/// 🗺️ 위치 결과 클래스
class LocationResult {
  final String? locationTagId;
  final String? locationTagName;
  final String locationStatus;
  final String? pendingLocationName;
  final String? errorMessage;

  LocationResult._({
    this.locationTagId,
    this.locationTagName,
    required this.locationStatus,
    this.pendingLocationName,
    this.errorMessage,
  });

  factory LocationResult.success({
    required String locationTagId,
    required String locationTagName,
    required String locationStatus,
  }) {
    return LocationResult._(
      locationTagId: locationTagId,
      locationTagName: locationTagName,
      locationStatus: locationStatus,
    );
  }

  factory LocationResult.pending(String pendingLocationName) {
    return LocationResult._(
      locationStatus: 'pending',
      pendingLocationName: pendingLocationName,
    );
  }

  factory LocationResult.failure(String errorMessage) {
    return LocationResult._(
      locationStatus: 'unavailable',
      errorMessage: errorMessage,
    );
  }

  factory LocationResult.none() {
    return LocationResult._(
      locationStatus: 'none',
    );
  }

  bool get isSuccess => locationStatus == 'active';
  bool get isPending => locationStatus == 'pending';
  bool get isFailure => locationStatus == 'unavailable';
  bool get isNone => locationStatus == 'none';
}

/// 🚨 사용자 위치 관련 예외 클래스들
class UserLocationException implements Exception {
  final String message;
  UserLocationException(this.message);

  @override
  String toString() => 'UserLocationException: $message';
}

class AddressValidationException implements Exception {
  final String message;
  AddressValidationException(this.message);

  @override
  String toString() => 'AddressValidationException: $message';
}

class LocationPermissionException implements Exception {
  final String message;
  LocationPermissionException(this.message);

  @override
  String toString() => 'LocationPermissionException: $message';
}

class DistanceValidationException implements Exception {
  final String message;
  DistanceValidationException(this.message);

  @override
  String toString() => 'DistanceValidationException: $message';
}
