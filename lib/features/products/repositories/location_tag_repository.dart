import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/location_tag_model.dart';
import '../models/pickup_info_model.dart';
import '../exceptions/location_exceptions.dart';

part 'location_tag_repository.g.dart';

/// LocationTagRepository 인스턴스를 제공하는 Provider입니다.
@riverpod
LocationTagRepository locationTagRepository(Ref ref) {
  return LocationTagRepository(
    FirebaseFirestore.instance,
    ref,
  );
}

/// 지역 태그(LocationTag) 관리를 담당하는 Repository 클래스입니다.
///
/// 주요 기능:
/// - 지원 지역 조회 (강남동, 서초동, 송파동, 영등포동, 강서동)
/// - LocationTag CRUD 작업
/// - 픽업 정보 관리
/// - 지역 지원 여부 확인
class LocationTagRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  LocationTagRepository(this._firestore, this._ref);

  /// LocationTags 컬렉션 참조
  CollectionReference get _locationTagsCollection =>
      _firestore.collection('locationTags');

  /// 🏠 지원 지역 목록 상수
  static const List<String> supportedRegions = [
    '강남동',
    '서초동',
    '송파동',
    '영등포동',
    '강서동'
  ];

  /// 🏠 지원 지역 조회 (강남동, 서초동, 송파동, 영등포동, 강서동)
  Future<List<LocationTagModel>> getSupportedLocationTags() async {
    try {
      print('🏠 LocationTagRepository: getSupportedLocationTags() - 시작');

      final QuerySnapshot snapshot = await _locationTagsCollection
          .where('isActive', isEqualTo: true)
          .where('name', whereIn: supportedRegions)
          .get();

      final locationTags = snapshot.docs
          .map((doc) => LocationTagModel.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      print('🏠 LocationTagRepository: ${locationTags.length}개 지역 조회 완료');
      return locationTags;
    } catch (e) {
      print('🏠 LocationTagRepository: getSupportedLocationTags() - 오류: $e');
      throw LocationTagNotFoundException('지원 지역 목록을 불러오는데 실패했습니다: $e');
    }
  }

  /// 📍 특정 LocationTag 조회 (ID로)
  Future<LocationTagModel?> getLocationTagById(String id) async {
    try {
      print('🏠 LocationTagRepository: getLocationTagById($id) - 시작');

      final DocumentSnapshot doc = await _locationTagsCollection.doc(id).get();

      if (!doc.exists) {
        print('🏠 LocationTagRepository: LocationTag ID "$id"를 찾을 수 없음');
        return null;
      }

      final locationTag = LocationTagModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);

      print('🏠 LocationTagRepository: LocationTag "$id" 조회 완료');
      return locationTag;
    } catch (e) {
      print('🏠 LocationTagRepository: getLocationTagById($id) - 오류: $e');
      throw LocationTagNotFoundException('지역 정보를 불러오는데 실패했습니다: $e');
    }
  }

  /// 📍 특정 LocationTag 조회 (이름으로)
  Future<LocationTagModel?> getLocationTagByName(String name) async {
    try {
      print('🏠 LocationTagRepository: getLocationTagByName($name) - 시작');

      final QuerySnapshot snapshot = await _locationTagsCollection
          .where('name', isEqualTo: name)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('🏠 LocationTagRepository: LocationTag "$name"를 찾을 수 없음');
        return null;
      }

      final locationTag = LocationTagModel.fromFirestore(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id);

      print('🏠 LocationTagRepository: LocationTag "$name" 조회 완료');
      return locationTag;
    } catch (e) {
      print('🏠 LocationTagRepository: getLocationTagByName($name) - 오류: $e');
      throw LocationTagNotFoundException('지역 정보를 불러오는데 실패했습니다: $e');
    }
  }

  /// 🕐 특정 지역의 픽업 정보 조회
  Future<List<PickupInfoModel>> getPickupInfosByLocationTagId(
      String locationTagId) async {
    try {
      print(
          '🏠 LocationTagRepository: getPickupInfosByLocationTagId($locationTagId) - 시작');

      final locationTag = await getLocationTagById(locationTagId);

      if (locationTag == null) {
        throw LocationTagNotFoundException('지역 정보를 찾을 수 없습니다: $locationTagId');
      }

      final activePickups = locationTag.activePickupInfos;
      print('🏠 LocationTagRepository: ${activePickups.length}개 픽업 정보 조회 완료');

      return activePickups;
    } catch (e) {
      print(
          '🏠 LocationTagRepository: getPickupInfosByLocationTagId($locationTagId) - 오류: $e');
      throw PickupInfoNotFoundException('픽업 정보를 불러오는데 실패했습니다: $e');
    }
  }

  /// 🆕 지역 지원 여부 확인 (동 이름으로)
  Future<bool> isSupportedRegion(String dongName) async {
    print('🏠 LocationTagRepository: isSupportedRegion($dongName) - 확인');
    return supportedRegions.contains(dongName);
  }

  /// 🆕 LocationTag 가용성 확인 (지원 지역이면서 실제 존재하는지)
  Future<bool> isLocationTagAvailable(String dongName) async {
    try {
      print('🏠 LocationTagRepository: isLocationTagAvailable($dongName) - 시작');

      // 1. 지원 지역인지 확인
      if (!await isSupportedRegion(dongName)) {
        print('🏠 LocationTagRepository: "$dongName"은 지원하지 않는 지역');
        return false;
      }

      // 2. 실제 LocationTag가 존재하는지 확인
      final locationTag = await getLocationTagByName(dongName);
      final available = locationTag != null && locationTag.isActive;

      print('🏠 LocationTagRepository: "$dongName" 가용성: $available');
      return available;
    } catch (e) {
      print(
          '🏠 LocationTagRepository: isLocationTagAvailable($dongName) - 오류: $e');
      return false;
    }
  }

  /// 🆕 신규 LocationTag 생성 (관리자 기능 또는 자동 생성)
  Future<LocationTagModel> createLocationTagForRegion(String dongName) async {
    try {
      print(
          '🏠 LocationTagRepository: createLocationTagForRegion($dongName) - 시작');

      // 지원 지역인지 확인
      if (!await isSupportedRegion(dongName)) {
        throw UnsupportedLocationException('$dongName은 지원하지 않는 지역입니다.');
      }

      // 이미 존재하는지 확인
      final existing = await getLocationTagByName(dongName);
      if (existing != null) {
        print('🏠 LocationTagRepository: "$dongName" LocationTag가 이미 존재함');
        return existing;
      }

      // 새로운 LocationTag 생성
      final now = DateTime.now();
      final locationTagId = _generateLocationTagId(dongName);

      final newLocationTag = LocationTagModel(
        id: locationTagId,
        name: dongName,
        description: _generateDescription(dongName),
        region: _generateRegion(dongName),
        pickupInfos: [], // 초기에는 픽업 정보 없음
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Firestore에 저장
      await _locationTagsCollection
          .doc(locationTagId)
          .set(newLocationTag.toFirestore());

      print('🏠 LocationTagRepository: "$dongName" LocationTag 생성 완료');
      return newLocationTag;
    } catch (e) {
      print(
          '🏠 LocationTagRepository: createLocationTagForRegion($dongName) - 오류: $e');
      rethrow;
    }
  }

  /// 🆕 LocationTag 없는 지역 처리 전략
  Future<String?> handleMissingLocationTag(String dongName) async {
    try {
      print(
          '🏠 LocationTagRepository: handleMissingLocationTag($dongName) - 시작');

      // 전략: 지원 지역이면 자동 생성, 아니면 null 반환
      if (await isSupportedRegion(dongName)) {
        final newLocationTag = await createLocationTagForRegion(dongName);
        print('🏠 LocationTagRepository: "$dongName" 자동 생성 완료');
        return newLocationTag.id;
      } else {
        print('🏠 LocationTagRepository: "$dongName"은 지원하지 않는 지역 - null 반환');
        return null;
      }
    } catch (e) {
      print(
          '🏠 LocationTagRepository: handleMissingLocationTag($dongName) - 오류: $e');
      return null;
    }
  }

  /// 🔧 LocationTag 생성 (관리자용)
  Future<void> createLocationTag(LocationTagModel locationTag) async {
    try {
      print(
          '🏠 LocationTagRepository: createLocationTag(${locationTag.name}) - 시작');

      await _locationTagsCollection
          .doc(locationTag.id)
          .set(locationTag.toFirestore());

      print(
          '🏠 LocationTagRepository: LocationTag "${locationTag.name}" 생성 완료');
    } catch (e) {
      print(
          '🏠 LocationTagRepository: createLocationTag(${locationTag.name}) - 오류: $e');
      throw Exception('LocationTag 생성에 실패했습니다: $e');
    }
  }

  /// 🔧 LocationTag 업데이트 (관리자용)
  Future<void> updateLocationTag(LocationTagModel locationTag) async {
    try {
      print(
          '🏠 LocationTagRepository: updateLocationTag(${locationTag.name}) - 시작');

      final updatedLocationTag =
          locationTag.copyWith(updatedAt: DateTime.now());
      await _locationTagsCollection
          .doc(locationTag.id)
          .update(updatedLocationTag.toFirestore());

      print(
          '🏠 LocationTagRepository: LocationTag "${locationTag.name}" 업데이트 완료');
    } catch (e) {
      print(
          '🏠 LocationTagRepository: updateLocationTag(${locationTag.name}) - 오류: $e');
      throw Exception('LocationTag 업데이트에 실패했습니다: $e');
    }
  }

  /// 🔧 LocationTag 삭제 (소프트 삭제 - isActive를 false로)
  Future<void> deleteLocationTag(String locationTagId) async {
    try {
      print('🏠 LocationTagRepository: deleteLocationTag($locationTagId) - 시작');

      await _locationTagsCollection.doc(locationTagId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('🏠 LocationTagRepository: LocationTag "$locationTagId" 삭제 완료');
    } catch (e) {
      print(
          '🏠 LocationTagRepository: deleteLocationTag($locationTagId) - 오류: $e');
      throw Exception('LocationTag 삭제에 실패했습니다: $e');
    }
  }

  // 🔧 헬퍼 메서드들

  /// 동 이름에서 LocationTag ID 생성
  String _generateLocationTagId(String dongName) {
    final locationTagMapping = {
      '강남동': 'gangnam_dong',
      '서초동': 'seocho_dong',
      '송파동': 'songpa_dong',
      '영등포동': 'yeongdeungpo_dong',
      '강서동': 'gangseo_dong',
    };

    return locationTagMapping[dongName] ??
        dongName.toLowerCase().replaceAll('동', '_dong');
  }

  /// 동 이름에서 설명 생성
  String _generateDescription(String dongName) {
    final regionMapping = {
      '강남동': '강남구 강남동 지역',
      '서초동': '서초구 서초동 지역',
      '송파동': '송파구 송파동 지역',
      '영등포동': '영등포구 영등포동 지역',
      '강서동': '강서구 강서동 지역',
    };

    return regionMapping[dongName] ?? '$dongName 지역';
  }

  /// 동 이름에서 지역 정보 생성
  LocationTagRegion _generateRegion(String dongName) {
    final regionMapping = {
      '강남동': LocationTagRegion(sido: '서울특별시', sigungu: '강남구', dong: '강남동'),
      '서초동': LocationTagRegion(sido: '서울특별시', sigungu: '서초구', dong: '서초동'),
      '송파동': LocationTagRegion(sido: '서울특별시', sigungu: '송파구', dong: '송파동'),
      '영등포동': LocationTagRegion(sido: '서울특별시', sigungu: '영등포구', dong: '영등포동'),
      '강서동': LocationTagRegion(sido: '서울특별시', sigungu: '강서구', dong: '강서동'),
    };

    return regionMapping[dongName] ??
        LocationTagRegion(sido: '서울특별시', sigungu: '기타구', dong: dongName);
  }
}
