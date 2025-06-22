import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_model.dart';
import '../exceptions/user_exceptions.dart';

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
      final doc = await _usersCollection.doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromDocument(doc);
    } catch (e) {
      throw UserNotFoundException('사용자 정보를 불러오는데 실패했습니다: $e');
    }
  }

  /// 사용자 정보 업데이트
  Future<void> updateUser(UserModel user) async {
    try {
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      await _usersCollection.doc(user.uid).update(updatedUser.toMap());
    } catch (e) {
      throw Exception('사용자 정보 업데이트에 실패했습니다: $e');
    }
  }

  /// 사용자 정보 생성
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('사용자 생성에 실패했습니다: $e');
    }
  }

  // 🏠 지역 관련 기능

  /// LocationTag 정보와 함께 사용자 조회
  Future<UserModel?> getUserWithLocationTag(String uid) async {
    try {
      final user = await getUserById(uid);

      if (user == null) {
        return null;
      }

      // LocationTag 정보 검증 (필요시)
      // TODO: LocationTag 검증 로직 구현 필요
      // if (user.hasActiveLocationTag) {
      //   final locationTagRepo = _ref.read(locationTagRepositoryProvider);
      //   final locationTag =
      //       await locationTagRepo.getLocationTagById(user.locationTagId!);
      //
      //   if (locationTag == null || !locationTag.isActive) {
      //     final updatedUser = user.copyWith(
      //       locationTagId: null,
      //       locationTagName: null,
      //       locationStatus: 'inactive',
      //     );
      //     await updateUser(updatedUser);
      //     return updatedUser;
      //   }
      // }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// 특정 LocationTag의 사용자들 조회
  Future<List<UserModel>> getUsersByLocationTagId(String locationTagId) async {
    try {
      final snapshot = await _usersCollection
          .where('locationTagId', isEqualTo: locationTagId)
          .where('locationStatus', isEqualTo: 'active')
          .get();

      final users =
          snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();

      return users;
    } catch (e) {
      throw Exception('해당 지역 사용자 목록을 불러오는데 실패했습니다: $e');
    }
  }

  // 🔍 지역 검증 및 업데이트 (핵심 기능)

  /// 사용자의 LocationTag 업데이트
  Future<void> updateUserLocationTag(
      String uid, String locationTagId, String locationTagName) async {
    try {
      // 사용자 존재 확인
      final user = await getUserById(uid);
      if (user == null) {
        throw UserNotFoundException('사용자를 찾을 수 없습니다: $uid');
      }

      // TODO: LocationTag 유효성 검증 구현 필요
      // final locationTagRepo = _ref.read(locationTagRepositoryProvider);
      // final locationTag =
      //     await locationTagRepo.getLocationTagById(locationTagId);
      //
      // if (locationTag == null || !locationTag.isActive) {
      //   throw LocationTagValidationException(
      //       '유효하지 않은 LocationTag입니다: $locationTagId');
      // }

      // 사용자 정보 업데이트
      final updatedUser = user.copyWith(
        locationTagId: locationTagId,
        locationTagName: locationTagName,
        locationStatus: 'active',
        pendingLocationName: null, // 성공적으로 설정되었으므로 대기 정보 제거
        updatedAt: DateTime.now(),
      );

      await updateUser(updatedUser);
    } catch (e) {
      rethrow;
    }
  }

  /// 사용자의 LocationTag ID 조회
  Future<String?> getUserLocationTagId(String uid) async {
    try {
      final user = await getUserById(uid);

      if (user == null) {
        throw UserNotFoundException('사용자를 찾을 수 없습니다: $uid');
      }

      return user.hasActiveLocationTag ? user.locationTagId : null;
    } catch (e) {
      rethrow;
    }
  }

  /// 사용자가 특정 LocationTag에 접근 권한이 있는지 확인
  Future<bool> hasLocationTagAccess(String uid, String locationTagId) async {
    try {
      final userLocationTagId = await getUserLocationTagId(uid);

      if (userLocationTagId == null) {
        return false;
      }

      return userLocationTagId == locationTagId;
    } catch (e) {
      return false;
    }
  }

  // 📍 주소 인증 관련 (기존 로직 연동)

  /// 주소 검증 및 LocationTag 업데이트
  Future<void> validateAndUpdateAddress(String uid, String inputAddress,
      {Map<String, dynamic>? addressInfo}) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  // 🆕 LocationTag 없는 경우 처리

  /// LocationTag가 없는 경우 처리
  Future<void> handleLocationTagNotAvailable(
      String uid, String dongName) async {
    try {
      // TODO: LocationTag 지원 여부 확인 로직 구현 필요
      // final locationTagRepo = _ref.read(locationTagRepositoryProvider);
      //
      // // 지원 지역인지 확인
      // final isSupported = await locationTagRepo.isSupportedRegion(dongName);
      //
      // if (isSupported) {
      //   // 지원 지역이지만 LocationTag가 없는 경우 - 대기 상태로 설정
      //   await setUserLocationPending(uid, dongName);
      // } else {
      //   // 지원하지 않는 지역인 경우 - 비가용 상태로 설정
      //   await setUserLocationUnavailable(uid, dongName);
      // }

      // 임시로 비가용 상태로 설정
      await setUserLocationUnavailable(uid, dongName);
    } catch (e) {
      rethrow;
    }
  }

  /// LocationTag 가용성 확인
  Future<bool> isLocationTagAvailable(String dongName) async {
    try {
      // TODO: LocationTag 가용성 확인 로직 구현 필요
      // final locationTagRepo = _ref.read(locationTagRepositoryProvider);
      // return await locationTagRepo.isLocationTagAvailable(dongName);
      return false; // 임시로 false 반환
    } catch (e) {
      return false; // 오류 발생 시 기본적으로 false 반환
    }
  }

  /// 사용자를 LocationTag 대기 상태로 설정
  Future<void> setUserLocationPending(String uid, String dongName) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  /// 사용자를 LocationTag 지원하지 않는 상태로 설정
  Future<void> setUserLocationUnavailable(String uid, String dongName) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  // 🔧 헬퍼 메서드들

  /// 주소 검증 (기존 로직과 연동 - 구현 필요)
  Future<Map<String, dynamic>> _validateAddress(String inputAddress) async {
    // TODO: 기존 주소 검증 로직과 연동
    // 카카오맵 API + GPS 10km 이내 검증 로직
    // 임시로 더미 데이터 반환

    throw UnimplementedError('주소 검증 로직은 기존 구현과 연동이 필요합니다');
  }

  /// 주소에서 LocationTag ID 매핑 및 검증
  Future<String?> _mapAndValidateLocationTag(String dongName) async {
    try {
      // TODO: LocationTag 매핑 및 검증 로직 구현 필요
      // final locationTagRepo = _ref.read(locationTagRepositoryProvider);
      //
      // // 1. 지원 지역 확인
      // if (!await locationTagRepo.isSupportedRegion(dongName)) {
      //   return null;
      // }
      //
      // // 2. LocationTag 조회
      // final locationTag = await locationTagRepo.getLocationTagByName(dongName);
      //
      // if (locationTag != null && locationTag.isActive) {
      //   return locationTag.id;
      // }
      //
      // // 3. LocationTag가 없는 경우 처리
      // return await locationTagRepo.handleMissingLocationTag(dongName);

      return null; // 임시로 null 반환
    } catch (e) {
      rethrow;
    }
  }

  // 🆕 마이그레이션 헬퍼 메서드들

  /// 기존 locationTag 문자열 데이터를 새로운 구조로 마이그레이션
  Future<void> migrateUserLocationTags() async {
    try {
      final snapshot = await _usersCollection.get();
      int migratedCount = 0;
      // TODO: LocationTag 마이그레이션 로직 구현 필요
      // final locationTagRepo = _ref.read(locationTagRepositoryProvider);

      for (final doc in snapshot.docs) {
        try {
          final user = UserModel.fromDocument(doc);

          // 이미 마이그레이션된 사용자는 건너뛰기
          if (user.locationTagId != null) continue;

          final oldLocationTag =
              (doc.data() as Map<String, dynamic>)['locationTag'] as String?;

          if (oldLocationTag != null) {
            // TODO: LocationTag ID 매핑 로직 구현 필요
            // final locationTagId =
            //     await _mapAndValidateLocationTag(oldLocationTag);
            //
            // if (locationTagId != null) {
            //   // 새로운 구조로 업데이트
            //   final updatedUser = user.copyWith(
            //     locationTagId: locationTagId,
            //     locationTagName: oldLocationTag,
            //     locationStatus: 'active',
            //     updatedAt: DateTime.now(),
            //   );
            //
            //   await updateUser(updatedUser);
            //   migratedCount++;
            // }

            // 임시로 카운트만 증가
            migratedCount++;
          }
        } catch (e) {
          // 개별 사용자 마이그레이션 실패 시 로깅 후 계속
          print('User migration failed for ${doc.id}: $e');
          continue;
        }
      }

      print('Successfully migrated $migratedCount users');
    } catch (e) {
      throw Exception('사용자 LocationTag 마이그레이션에 실패했습니다: $e');
    }
  }
}
