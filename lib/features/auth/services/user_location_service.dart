import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../models/location_result_model.dart';
import '../exceptions/user_location_exception.dart';
import '../../location/repositories/location_tag_repository.dart';
import '../../location/models/location_tag_model.dart';
import '../providers/auth_providers.dart'
    as auth_providers; // authRepositoryProvider import
import '../../common/providers/repository_providers.dart'; // locationTagRepositoryProvider import

part 'user_location_service.g.dart';

/// UserLocationService 인스턴스를 제공하는 Provider입니다.
@riverpod
UserLocationService userLocationService(Ref ref) {
  return UserLocationService(
    ref.watch(auth_providers.authRepositoryProvider), // Provider를 통해 주입
    ref.watch(locationTagRepositoryProvider),
    ref,
  );
}

/// 사용자 위치 설정 및 관리를 담당하는 서비스 클래스입니다.
///
/// 주요 기능:
/// - 회원가입 시 위치 인증 및 사용자 생성
/// - 사용자 위치 정보 업데이트
/// - 주소 검증 및 LocationTag 매핑
/// - 위치 상태 관리
class UserLocationService {
  final AuthRepository _authRepository;
  final LocationTagRepository _locationTagRepository;
  final Ref _ref;

  UserLocationService(
    this._authRepository,
    this._locationTagRepository,
    this._ref,
  );

  /// 🌍 회원가입 시 위치 인증 및 사용자 생성
  Future<UserModel> registerUserWithLocation({
    required String name,
    required String inputAddress,
    String? phoneNumber,
    String? roadNameAddress,
    String? locationAddress,
  }) async {
    try {
      print('🌍 UserLocationService: Starting user registration with location');
      print('🌍 UserLocationService: Input address: $inputAddress');

      // 1. 기존 주소 검증 로직 사용 (카카오맵 API + GPS 10km 이내)
      final addressInfo = await _validateAddress(inputAddress);
      final dongName = addressInfo['region_3depth_name'] ?? '알 수 없는 지역';

      print('🌍 UserLocationService: Extracted dongName: $dongName');

      // 2. LocationTag 매핑 및 검증
      final locationResult = await _mapAndValidateLocationTag(dongName);

      print('🌍 UserLocationService: Location mapping result: $locationResult');

      // 3. AuthRepository 호출 (검증된 데이터로)
      final user = await _authRepository.signUp(
        name: name,
        phoneNumber: phoneNumber,
        roadNameAddress: roadNameAddress ?? addressInfo['road_address_name'],
        locationAddress: locationAddress ?? addressInfo['address_name'],
        locationTagId: locationResult.locationTagId,
        locationTagName: locationResult.locationTagName,
        locationStatus: locationResult.locationStatus,
        pendingLocationName: locationResult.pendingLocationName,
      );

      print('🎉 UserLocationService: User registration completed successfully');
      print('🎉 UserLocationService: User status: ${user.locationStatus}');

      return user;
    } catch (e) {
      print('❌ UserLocationService: Registration failed: $e');
      rethrow;
    }
  }

  /// 🔄 사용자 위치 정보 업데이트
  Future<UserModel> updateUserLocation({
    required String uid,
    required String inputAddress,
    String? name,
    String? phoneNumber,
    String? roadNameAddress,
    String? locationAddress,
  }) async {
    try {
      print('🌍 UserLocationService: Updating user location');
      print('🌍 UserLocationService: UID: $uid, Address: $inputAddress');

      // 1. 주소 검증
      final addressInfo = await _validateAddress(inputAddress);
      final dongName = addressInfo['region_3depth_name'] ?? '알 수 없는 지역';

      print('🌍 UserLocationService: Extracted dongName: $dongName');

      // 2. LocationTag 매핑 및 검증
      final locationResult = await _mapAndValidateLocationTag(dongName);

      print('🌍 UserLocationService: Location mapping result: $locationResult');

      // 3. AuthRepository 호출
      final user = await _authRepository.updateUserProfile(
        uid: uid,
        name: name,
        phoneNumber: phoneNumber,
        roadNameAddress: roadNameAddress ?? addressInfo['road_address_name'],
        locationAddress: locationAddress ?? addressInfo['address_name'],
        locationTagId: locationResult.locationTagId,
        locationTagName: locationResult.locationTagName,
        locationStatus: locationResult.locationStatus,
        pendingLocationName: locationResult.pendingLocationName,
      );

      print('🎉 UserLocationService: Location update completed');
      print('🎉 UserLocationService: User status: ${user.locationStatus}');

      return user;
    } catch (e) {
      print('❌ UserLocationService: Location update failed: $e');
      rethrow;
    }
  }

  /// 📍 기존 사용자 프로필 저장 (위치 포함)
  Future<UserModel> saveExistingUserWithLocation({
    required String uid,
    required String name,
    required String inputAddress,
    String? phoneNumber,
    String? roadNameAddress,
    String? locationAddress,
  }) async {
    try {
      print('🌍 UserLocationService: Saving existing user with location');
      print('🌍 UserLocationService: UID: $uid, Address: $inputAddress');

      // 1. 주소 검증
      final addressInfo = await _validateAddress(inputAddress);
      final dongName = addressInfo['region_3depth_name'] ?? '알 수 없는 지역';

      print('🌍 UserLocationService: Extracted dongName: $dongName');

      // 2. LocationTag 매핑 및 검증
      final locationResult = await _mapAndValidateLocationTag(dongName);

      print('🌍 UserLocationService: Location mapping result: $locationResult');

      // 3. AuthRepository 호출
      final user = await _authRepository.saveUserProfileForExistingUser(
        uid: uid,
        name: name,
        phoneNumber: phoneNumber,
        roadNameAddress: roadNameAddress ?? addressInfo['road_address_name'],
        locationAddress: locationAddress ?? addressInfo['address_name'],
        locationTagId: locationResult.locationTagId,
        locationTagName: locationResult.locationTagName,
        locationStatus: locationResult.locationStatus,
        pendingLocationName: locationResult.pendingLocationName,
      );

      print('🎉 UserLocationService: Existing user profile saved');
      print('🎉 UserLocationService: User status: ${user.locationStatus}');

      return user;
    } catch (e) {
      print('❌ UserLocationService: Save existing user failed: $e');
      rethrow;
    }
  }

  /// 🚀 위치 정보 없이 회원가입 (나중에 설정)
  Future<UserModel> registerUserWithoutLocation({
    required String name,
    String? phoneNumber,
  }) async {
    try {
      print('🌍 UserLocationService: Registering user without location');

      final user = await _authRepository.signUp(
        name: name,
        phoneNumber: phoneNumber,
        locationStatus: 'none',
      );

      print('🎉 UserLocationService: User registered without location');
      return user;
    } catch (e) {
      print('❌ UserLocationService: Registration without location failed: $e');
      rethrow;
    }
  }

  /// 📍 사용자 위치 상태만 업데이트 (주소 변경 없이)
  Future<UserModel> updateLocationStatus({
    required String uid,
    required String dongName,
  }) async {
    try {
      print('🌍 UserLocationService: Updating location status only');
      print('🌍 UserLocationService: UID: $uid, DongName: $dongName');

      // LocationTag 매핑 및 검증
      final locationResult = await _mapAndValidateLocationTag(dongName);

      print('🌍 UserLocationService: Location mapping result: $locationResult');

      // AuthRepository를 통해 위치 상태만 업데이트
      final user = await _authRepository.updateUserProfile(
        uid: uid,
        locationTagId: locationResult.locationTagId,
        locationTagName: locationResult.locationTagName,
        locationStatus: locationResult.locationStatus,
        pendingLocationName: locationResult.pendingLocationName,
      );

      print('🎉 UserLocationService: Location status updated');
      print('🎉 UserLocationService: User status: ${user.locationStatus}');

      return user;
    } catch (e) {
      print('❌ UserLocationService: Location status update failed: $e');
      rethrow;
    }
  }

  // Private Methods

  /// 🔍 주소 검증 (기존 로직 사용)
  /// TODO: 기존 카카오맵 API + GPS 검증 로직과 연동 필요
  Future<Map<String, dynamic>> _validateAddress(String inputAddress) async {
    try {
      print('🔍 UserLocationService: Validating address: $inputAddress');

      // TODO: 기존 카카오맵 API + GPS 검증 로직 구현
      // 10km 이내 거리 확인
      // 실제 구현은 기존 코드 참조

      // 임시 더미 데이터 (실제 구현 시 제거)
      final dummyAddressInfo = <String, dynamic>{
        'road_address_name': '서울특별시 강남구 강남대로 396',
        'address_name': '서울특별시 강남구 강남동 123-45',
        'region_3depth_name': '강남동', // 동 이름 추출
      };

      // 실제 구현에서는 다음과 같은 로직이 필요:
      // 1. 카카오맵 API로 주소 정보 조회
      // 2. GPS로 현재 위치 확인
      // 3. 입력된 주소와 현재 위치의 거리 계산
      // 4. 10km 이내인지 검증

      print('🔍 UserLocationService: Address validation completed (dummy)');
      print(
          '🔍 UserLocationService: Extracted region: ${dummyAddressInfo['region_3depth_name']}');

      return dummyAddressInfo;
    } catch (e) {
      print('❌ UserLocationService: Address validation failed: $e');
      throw AddressValidationException('주소 검증에 실패했습니다: $e');
    }
  }

  /// 🗺️ LocationTag 매핑 및 검증
  Future<LocationResultModel> _mapAndValidateLocationTag(
      String dongName) async {
    try {
      print('🏠 UserLocationService: Mapping LocationTag for: $dongName');

      // 1. 지원 지역 확인
      final isSupported =
          await _locationTagRepository.isValidLocationTagName(dongName);
      print('🏠 UserLocationService: Is supported region: $isSupported');

      if (!isSupported) {
        print('🏠 UserLocationService: Unsupported region: $dongName');
        return LocationResultModel.failure('$dongName은 아직 지원하지 않는 지역입니다.');
      }

      // 2. LocationTag 존재 여부 확인
      final locationTag =
          await _locationTagRepository.getLocationTagByName(dongName);
      print(
          '🏠 UserLocationService: LocationTag found: ${locationTag != null}');

      if (locationTag != null && locationTag.isActive) {
        print('🏠 UserLocationService: Active LocationTag found');
        // 정상 케이스: LocationTag 존재
        return LocationResultModel.success(
          locationTagId: locationTag.id,
          locationTagName: locationTag.name,
          locationStatus: 'active',
        );
      }

      // 3. 지원 지역이지만 LocationTag가 없는 경우
      print(
          '🏠 UserLocationService: LocationTag not available, handling missing tag');
      return await _handleMissingLocationTag(dongName);
    } catch (e) {
      print('❌ UserLocationService: LocationTag mapping failed: $e');
      return LocationResultModel.failure('위치 설정 중 오류가 발생했습니다: $e');
    }
  }

  /// 🚧 LocationTag 없는 경우 처리
  Future<LocationResultModel> _handleMissingLocationTag(String dongName) async {
    try {
      print(
          '🚧 UserLocationService: Handling missing LocationTag for: $dongName');

      // 전략 선택 (현재는 전략 B 사용 - 대기 상태 설정)

      // 전략 A: 자동으로 기본 LocationTag 생성
      // try {
      //   final newLocationTag = await _locationTagRepository.createLocationTagForRegion(dongName);
      //   print('🚧 UserLocationService: Auto-created LocationTag: ${newLocationTag.id}');
      //   return LocationResultModel.success(
      //     locationTagId: newLocationTag.id,
      //     locationTagName: newLocationTag.name,
      //     locationStatus: 'active',
      //   );
      // } catch (createError) {
      //   print('🚧 UserLocationService: Auto-creation failed, falling back to pending');
      //   return LocationResultModel.pending(dongName);
      // }

      // 전략 B: 사용자를 대기 상태로 설정 (권장)
      print(
          '🚧 UserLocationService: Setting user to pending for region: $dongName');
      return LocationResultModel.pending(dongName);

      // 전략 C: 서비스 미지원 알림
      // return LocationResultModel.failure('$dongName 지역은 서비스 준비 중입니다.');
    } catch (e) {
      print('❌ UserLocationService: Failed to handle missing LocationTag: $e');
      return LocationResultModel.failure('위치 설정 처리 중 오류가 발생했습니다: $e');
    }
  }

  /// 🔍 사용자의 현재 위치 상태 조회
  Future<LocationResultModel> getUserLocationStatus(String uid) async {
    try {
      print('🔍 UserLocationService: Getting user location status for: $uid');

      final user = await _authRepository.getCurrentUser();
      if (user == null || user.uid != uid) {
        throw UserLocationException('사용자 정보를 찾을 수 없습니다');
      }

      // 현재 사용자의 위치 상태를 LocationResultModel로 변환
      if (user.hasActiveLocationTag) {
        return LocationResultModel.success(
          locationTagId: user.locationTagId!,
          locationTagName: user.locationTagName!,
          locationStatus: user.locationStatus,
        );
      } else if (user.isLocationPending) {
        return LocationResultModel.pending(
            user.pendingLocationName ?? '알 수 없는 지역');
      } else if (user.isLocationUnavailable) {
        return LocationResultModel.failure('지원하지 않는 지역입니다');
      } else {
        return LocationResultModel.none();
      }
    } catch (e) {
      print('❌ UserLocationService: Failed to get user location status: $e');
      throw UserLocationException('사용자 위치 상태 조회에 실패했습니다: $e');
    }
  }

  /// 🏠 지원 지역 목록 조회
  Future<List<LocationTagModel>> getSupportedRegions() async {
    try {
      print('🏠 UserLocationService: Getting supported regions');
      return await _locationTagRepository.getSupportedRegions();
    } catch (e) {
      print('❌ UserLocationService: Failed to get supported regions: $e');
      throw UserLocationException('지원 지역 목록 조회에 실패했습니다: $e');
    }
  }
}
