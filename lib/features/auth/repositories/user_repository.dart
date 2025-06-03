import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_model.dart';
import '../exceptions/user_exceptions.dart';
import '../../products/repositories/location_tag_repository.dart';
import '../../products/exceptions/location_exceptions.dart';

part 'user_repository.g.dart';

/// UserRepository 인스턴스를 제공하는 Provider입니다.
@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository(
    FirebaseFirestore.instance,
    ref,
  );
}

/// 사용자 정보 및 위치 관리를 담당하는 Repository 클래스입니다.
///
/// 주요 기능:
/// - 사용자 기본 CRUD 작업
/// - LocationTag 기반 지역 관리
/// - 주소 인증 및 업데이트
/// - 위치 상태 관리
class UserRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  UserRepository(this._firestore, this._ref);

  /// Users 컬렉션 참조
  CollectionReference get _usersCollection => _firestore.collection('users');

  // 👤 사용자 기본 CRUD

  /// 사용자 ID로 사용자 정보 조회
  Future<UserModel?> getUserById(String uid) async {
    try {
      print('👤 UserRepository: getUserById($uid) - 시작');

      final DocumentSnapshot doc = await _usersCollection.doc(uid).get();

      if (!doc.exists) {
        print('👤 UserRepository: 사용자 "$uid"를 찾을 수 없음');
        return null;
      }

      final user = UserModel.fromDocument(doc);
      print('👤 UserRepository: 사용자 "$uid" 조회 완료');
      return user;
    } catch (e) {
      print('👤 UserRepository: getUserById($uid) - 오류: $e');
      throw UserNotFoundException('사용자 정보를 불러오는데 실패했습니다: $e');
    }
  }

  /// 사용자 정보 업데이트
  Future<void> updateUser(UserModel user) async {
    try {
      print('👤 UserRepository: updateUser(${user.uid}) - 시작');

      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      await _usersCollection.doc(user.uid).update(updatedUser.toMap());

      print('👤 UserRepository: 사용자 "${user.uid}" 업데이트 완료');
    } catch (e) {
      print('👤 UserRepository: updateUser(${user.uid}) - 오류: $e');
      throw Exception('사용자 정보 업데이트에 실패했습니다: $e');
    }
  }

  /// 사용자 정보 생성
  Future<void> createUser(UserModel user) async {
    try {
      print('👤 UserRepository: createUser(${user.uid}) - 시작');

      await _usersCollection.doc(user.uid).set(user.toMap());

      print('👤 UserRepository: 사용자 "${user.uid}" 생성 완료');
    } catch (e) {
      print('👤 UserRepository: createUser(${user.uid}) - 오류: $e');
      throw Exception('사용자 생성에 실패했습니다: $e');
    }
  }

  // 🏠 지역 관련 기능

  /// LocationTag 정보와 함께 사용자 조회
  Future<UserModel?> getUserWithLocationTag(String uid) async {
    try {
      print('👤 UserRepository: getUserWithLocationTag($uid) - 시작');

      final user = await getUserById(uid);

      if (user == null) {
        return null;
      }

      // LocationTag 정보 검증 (필요시)
      if (user.hasActiveLocationTag) {
        final locationTagRepo = _ref.read(locationTagRepositoryProvider);
        final locationTag =
            await locationTagRepo.getLocationTagById(user.locationTagId!);

        if (locationTag == null || !locationTag.isActive) {
          print('👤 UserRepository: 사용자의 LocationTag가 비활성화되거나 존재하지 않음');
          // LocationTag 상태를 unavailable로 업데이트
          final updatedUser = user.copyWith(
            locationStatus: 'unavailable',
            updatedAt: DateTime.now(),
          );
          await updateUser(updatedUser);
          return updatedUser;
        }
      }

      print('👤 UserRepository: getUserWithLocationTag 완료');
      return user;
    } catch (e) {
      print('👤 UserRepository: getUserWithLocationTag($uid) - 오류: $e');
      rethrow;
    }
  }

  /// 특정 LocationTag의 사용자들 조회
  Future<List<UserModel>> getUsersByLocationTagId(String locationTagId) async {
    try {
      print('👤 UserRepository: getUsersByLocationTagId($locationTagId) - 시작');

      final QuerySnapshot snapshot = await _usersCollection
          .where('locationTagId', isEqualTo: locationTagId)
          .where('locationStatus', isEqualTo: 'active')
          .get();

      final users =
          snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();

      print('👤 UserRepository: ${users.length}명의 사용자 조회 완료');
      return users;
    } catch (e) {
      print(
          '👤 UserRepository: getUsersByLocationTagId($locationTagId) - 오류: $e');
      throw Exception('해당 지역 사용자 목록을 불러오는데 실패했습니다: $e');
    }
  }

  // 🔍 지역 검증 및 업데이트 (핵심 기능)

  /// 사용자의 LocationTag 업데이트
  Future<void> updateUserLocationTag(
      String uid, String locationTagId, String locationTagName) async {
    try {
      print(
          '👤 UserRepository: updateUserLocationTag($uid, $locationTagId, $locationTagName) - 시작');

      // 사용자 존재 확인
      final user = await getUserById(uid);
      if (user == null) {
        throw UserNotFoundException('사용자를 찾을 수 없습니다: $uid');
      }

      // LocationTag 유효성 검증
      final locationTagRepo = _ref.read(locationTagRepositoryProvider);
      final locationTag =
          await locationTagRepo.getLocationTagById(locationTagId);

      if (locationTag == null || !locationTag.isActive) {
        throw LocationValidationException(
            '유효하지 않은 LocationTag입니다: $locationTagId');
      }

      // 사용자 정보 업데이트
      final updatedUser = user.copyWith(
        locationTagId: locationTagId,
        locationTagName: locationTagName,
        locationStatus: 'active',
        pendingLocationName: null, // 성공적으로 설정되었으므로 대기 정보 제거
        updatedAt: DateTime.now(),
      );

      await updateUser(updatedUser);
      print('👤 UserRepository: 사용자 LocationTag 업데이트 완료');
    } catch (e) {
      print(
          '👤 UserRepository: updateUserLocationTag($uid, $locationTagId, $locationTagName) - 오류: $e');
      rethrow;
    }
  }

  /// 사용자의 LocationTag ID 조회
  Future<String?> getUserLocationTagId(String uid) async {
    try {
      print('👤 UserRepository: getUserLocationTagId($uid) - 시작');

      final user = await getUserById(uid);

      if (user == null) {
        throw UserNotFoundException('사용자를 찾을 수 없습니다: $uid');
      }

      return user.hasActiveLocationTag ? user.locationTagId : null;
    } catch (e) {
      print('👤 UserRepository: getUserLocationTagId($uid) - 오류: $e');
      rethrow;
    }
  }

  /// 사용자의 지역 접근 권한 검증
  Future<bool> validateUserLocationAccess(
      String uid, String requestedLocationTagId) async {
    try {
      print(
          '👤 UserRepository: validateUserLocationAccess($uid, $requestedLocationTagId) - 시작');

      final userLocationTagId = await getUserLocationTagId(uid);

      if (userLocationTagId == null) {
        print('👤 UserRepository: 사용자의 LocationTag가 설정되지 않음');
        return false;
      }

      final hasAccess = userLocationTagId == requestedLocationTagId;
      print('👤 UserRepository: 지역 접근 권한: $hasAccess');

      return hasAccess;
    } catch (e) {
      print(
          '👤 UserRepository: validateUserLocationAccess($uid, $requestedLocationTagId) - 오류: $e');
      return false;
    }
  }

  // 📍 주소 인증 관련 (기존 로직 연동)

  /// 주소 검증 및 LocationTag 업데이트
  Future<void> validateAndUpdateAddress(String uid, String inputAddress,
      {Map<String, dynamic>? addressInfo}) async {
    try {
      print(
          '👤 UserRepository: validateAndUpdateAddress($uid, $inputAddress) - 시작');

      // addressInfo가 제공되지 않은 경우 주소 검증 로직 호출 (기존 구현 필요)
      final Map<String, dynamic> verifiedAddressInfo =
          addressInfo ?? await _validateAddress(inputAddress);

      final dongName = verifiedAddressInfo['region_3depth_name'] as String?;

      if (dongName == null) {
        throw UserAddressValidationException('주소에서 동 정보를 찾을 수 없습니다');
      }

      // LocationTag 매핑 및 검증
      final locationTagId = await _mapAndValidateLocationTag(dongName);

      if (locationTagId == null) {
        // LocationTag가 없는 경우 처리
        await handleLocationTagNotAvailable(uid, dongName);
        return;
      }

      // 사용자 정보 업데이트
      await updateUserLocationTag(uid, locationTagId, dongName);

      // 주소 정보도 함께 업데이트
      final user = await getUserById(uid);
      if (user != null) {
        final updatedUser = user.copyWith(
          roadNameAddress: verifiedAddressInfo['road_address_name'],
          locationAddress: verifiedAddressInfo['address_name'],
          updatedAt: DateTime.now(),
        );
        await updateUser(updatedUser);
      }

      print('👤 UserRepository: 주소 검증 및 LocationTag 업데이트 완료');
    } catch (e) {
      print(
          '👤 UserRepository: validateAndUpdateAddress($uid, $inputAddress) - 오류: $e');
      rethrow;
    }
  }

  // 🆕 LocationTag 없는 경우 처리

  /// LocationTag가 없는 경우 처리
  Future<void> handleLocationTagNotAvailable(
      String uid, String dongName) async {
    try {
      print(
          '👤 UserRepository: handleLocationTagNotAvailable($uid, $dongName) - 시작');

      final locationTagRepo = _ref.read(locationTagRepositoryProvider);

      // 지원 지역인지 확인
      final isSupported = await locationTagRepo.isSupportedRegion(dongName);

      if (isSupported) {
        // 지원 지역이지만 LocationTag가 없는 경우 - 대기 상태로 설정
        await setUserLocationPending(uid, dongName);
        print('👤 UserRepository: 지원 지역 대기 상태 설정 완료');
      } else {
        // 지원하지 않는 지역 - unavailable 상태로 설정
        await setUserLocationUnavailable(uid, dongName);
        print('👤 UserRepository: 지원하지 않는 지역 상태 설정 완료');
      }
    } catch (e) {
      print(
          '👤 UserRepository: handleLocationTagNotAvailable($uid, $dongName) - 오류: $e');
      rethrow;
    }
  }

  /// LocationTag 가용성 확인
  Future<bool> isLocationTagAvailable(String dongName) async {
    try {
      print('👤 UserRepository: isLocationTagAvailable($dongName) - 시작');

      final locationTagRepo = _ref.read(locationTagRepositoryProvider);
      return await locationTagRepo.isLocationTagAvailable(dongName);
    } catch (e) {
      print('👤 UserRepository: isLocationTagAvailable($dongName) - 오류: $e');
      return false;
    }
  }

  /// 사용자를 LocationTag 대기 상태로 설정
  Future<void> setUserLocationPending(String uid, String dongName) async {
    try {
      print('👤 UserRepository: setUserLocationPending($uid, $dongName) - 시작');

      final user = await getUserById(uid);
      if (user == null) {
        throw UserNotFoundException('사용자를 찾을 수 없습니다: $uid');
      }

      final updatedUser = user.copyWith(
        locationTagId: null,
        locationTagName: null,
        locationStatus: 'pending',
        pendingLocationName: dongName,
        updatedAt: DateTime.now(),
      );

      await updateUser(updatedUser);
      print('👤 UserRepository: 사용자 대기 상태 설정 완료');
    } catch (e) {
      print(
          '👤 UserRepository: setUserLocationPending($uid, $dongName) - 오류: $e');
      rethrow;
    }
  }

  /// 사용자를 LocationTag 지원하지 않는 상태로 설정
  Future<void> setUserLocationUnavailable(String uid, String dongName) async {
    try {
      print(
          '👤 UserRepository: setUserLocationUnavailable($uid, $dongName) - 시작');

      final user = await getUserById(uid);
      if (user == null) {
        throw UserNotFoundException('사용자를 찾을 수 없습니다: $uid');
      }

      final updatedUser = user.copyWith(
        locationTagId: null,
        locationTagName: null,
        locationStatus: 'unavailable',
        pendingLocationName: dongName, // 참고용으로 저장
        updatedAt: DateTime.now(),
      );

      await updateUser(updatedUser);
      print('👤 UserRepository: 사용자 지원하지 않는 지역 상태 설정 완료');
    } catch (e) {
      print(
          '👤 UserRepository: setUserLocationUnavailable($uid, $dongName) - 오류: $e');
      rethrow;
    }
  }

  // 🔧 헬퍼 메서드들

  /// 주소 검증 (기존 로직과 연동 - 구현 필요)
  Future<Map<String, dynamic>> _validateAddress(String inputAddress) async {
    // TODO: 기존 주소 검증 로직과 연동
    // 카카오맵 API + GPS 10km 이내 검증 로직
    // 임시로 더미 데이터 반환
    print(
        '👤 UserRepository: _validateAddress($inputAddress) - TODO: 기존 로직 연동 필요');

    throw UnimplementedError('주소 검증 로직은 기존 구현과 연동이 필요합니다');
  }

  /// 주소에서 LocationTag ID 매핑 및 검증
  Future<String?> _mapAndValidateLocationTag(String dongName) async {
    try {
      print('👤 UserRepository: _mapAndValidateLocationTag($dongName) - 시작');

      final locationTagRepo = _ref.read(locationTagRepositoryProvider);

      // 1. 지원 지역 확인
      if (!await locationTagRepo.isSupportedRegion(dongName)) {
        print('👤 UserRepository: "$dongName"은 지원하지 않는 지역');
        return null;
      }

      // 2. LocationTag 존재 여부 확인
      final locationTag = await locationTagRepo.getLocationTagByName(dongName);

      if (locationTag != null && locationTag.isActive) {
        print('👤 UserRepository: LocationTag "$dongName" 매핑 완료');
        return locationTag.id;
      }

      // 3. 지원 지역이지만 LocationTag가 없는 경우 처리
      print('👤 UserRepository: 지원 지역이지만 LocationTag 없음 - 자동 생성 시도');
      return await locationTagRepo.handleMissingLocationTag(dongName);
    } catch (e) {
      print(
          '👤 UserRepository: _mapAndValidateLocationTag($dongName) - 오류: $e');
      rethrow;
    }
  }

  // 🆕 마이그레이션 헬퍼 메서드들

  /// 기존 locationTag 문자열 데이터를 새로운 구조로 마이그레이션
  Future<void> migrateUserLocationTags() async {
    try {
      print('👤 UserRepository: migrateUserLocationTags() - 시작');

      // 기존 locationTag 필드가 있고 새로운 필드들이 없는 사용자들 조회
      final QuerySnapshot snapshot =
          await _usersCollection.where('locationTag', isNotEqualTo: null).get();

      int migratedCount = 0;
      final locationTagRepo = _ref.read(locationTagRepositoryProvider);

      for (final doc in snapshot.docs) {
        try {
          final user = UserModel.fromDocument(doc);

          // 이미 마이그레이션된 사용자는 건너뛰기
          if (user.locationTagId != null) continue;

          final oldLocationTag =
              (doc.data() as Map<String, dynamic>)['locationTag'] as String?;

          if (oldLocationTag != null) {
            // LocationTag ID 매핑
            final locationTagId =
                await _mapAndValidateLocationTag(oldLocationTag);

            if (locationTagId != null) {
              // 새로운 구조로 업데이트
              final updatedUser = user.copyWith(
                locationTagId: locationTagId,
                locationTagName: oldLocationTag,
                locationStatus: 'active',
                updatedAt: DateTime.now(),
              );

              await updateUser(updatedUser);
              migratedCount++;

              print('👤 UserRepository: 사용자 ${user.uid} 마이그레이션 완료');
            }
          }
        } catch (e) {
          print('👤 UserRepository: 사용자 ${doc.id} 마이그레이션 실패: $e');
        }
      }

      print('👤 UserRepository: 총 ${migratedCount}명의 사용자 마이그레이션 완료');
    } catch (e) {
      print('👤 UserRepository: migrateUserLocationTags() - 오류: $e');
      throw Exception('사용자 LocationTag 마이그레이션에 실패했습니다: $e');
    }
  }
}
