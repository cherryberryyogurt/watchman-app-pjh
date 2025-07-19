import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/location_tag_model.dart';
import '../models/pickup_point_model.dart';
import '../exceptions/location_tag_exceptions.dart';

class LocationTagRepository {
  final FirebaseFirestore _firestore;

  // 🚀 성능 최적화를 위한 메모리 캐시
  final Map<String, LocationTagModel> _idCache = {};
  final Map<String, LocationTagModel> _nameCache = {};
  List<LocationTagModel>? _allLocationTags;
  DateTime? _cacheTimestamp;

  // 캐시 만료 시간 (5분)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  LocationTagRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore collection reference
  CollectionReference get _locationTagCollection =>
      _firestore.collection('locationTag');

  // 🔍 이름으로 LocationTag 조회
  Future<LocationTagModel?> getLocationTagByName(String name) async {
    try {
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: getLocationTagByName($name) - 시작');
      }

      // 캐시에서 먼저 확인
      if (_nameCache.containsKey(name) && _isCacheValid()) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: 캐시에서 조회 완료');
        }
        return _nameCache[name];
      }

      final QuerySnapshot snapshot = await _locationTagCollection
          .where('name', isEqualTo: name)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: LocationTag "$name"을 찾을 수 없음');
        }
        return null;
      }

      final locationTag = LocationTagModel.fromFirestore(snapshot.docs.first);

      // 캐시에 저장
      _nameCache[name] = locationTag;
      _idCache[locationTag.id] = locationTag;

      if (kDebugMode) {
        print('🏷️ LocationTagRepository: LocationTag "$name" 조회 완료');
      }

      return locationTag;
    } catch (e) {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: getLocationTagByName($name) - 오류: $e');
      }
      throw LocationTagNotFoundException('LocationTag 조회에 실패했습니다: $e');
    }
  }

  // 🔍 ID로 LocationTag 조회
  Future<LocationTagModel?> getLocationTagById(String id) async {
    try {
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: getLocationTagById($id) - 시작');
      }

      // 캐시에서 먼저 확인
      if (_idCache.containsKey(id) && _isCacheValid()) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: 캐시에서 조회 완료');
        }
        return _idCache[id];
      }

      final DocumentSnapshot doc = await _locationTagCollection.doc(id).get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: LocationTag "$id"를 찾을 수 없음');
        }
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;

      // 비활성화된 LocationTag 체크
      if (data['isActive'] == false) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: LocationTag "$id"는 비활성화됨');
        }
        return null;
      }

      final locationTag = LocationTagModel.fromFirestore(doc);

      // 캐시에 저장
      _idCache[id] = locationTag;
      _nameCache[locationTag.name] = locationTag;

      if (kDebugMode) {
        print('🏷️ LocationTagRepository: LocationTag "$id" 조회 완료');
      }

      return locationTag;
    } catch (e) {
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: getLocationTagById($id) - 오류: $e');
      }
      throw LocationTagNotFoundException('LocationTag 조회에 실패했습니다: $e');
    }
  }

  // 🌍 지원되는 모든 지역 조회
  Future<List<LocationTagModel>> getSupportedRegions() async {
    try {
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: getSupportedRegions() - 시작');
      }

      // 캐시에서 먼저 확인
      if (_allLocationTags != null && _isCacheValid()) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: 캐시에서 조회 완료');
        }
        return _allLocationTags!;
      }

      final QuerySnapshot snapshot = await _locationTagCollection
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final locationTags = snapshot.docs
          .map((doc) => LocationTagModel.fromFirestore(doc))
          .toList();

      // 전체 캐시 업데이트
      _allLocationTags = locationTags;
      _cacheTimestamp = DateTime.now();

      // 개별 캐시도 업데이트
      for (final tag in locationTags) {
        _idCache[tag.id] = tag;
        _nameCache[tag.name] = tag;
      }

      if (kDebugMode) {
        print('🏷️ LocationTagRepository: ${locationTags.length}개 지역 조회 완료');
      }

      return locationTags;
    } catch (e) {
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: getSupportedRegions() - 오류: $e');
      }
      throw LocationTagException('지원 지역 조회에 실패했습니다: $e');
    }
  }

  // ✅ 유효한 LocationTag ID인지 확인
  Future<bool> isValidLocationTagId(String id) async {
    try {
      final locationTag = await getLocationTagById(id);
      return locationTag != null;
    } catch (e) {
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: isValidLocationTagId($id) - 오류: $e');
      }
      return false;
    }
  }

  // ✅ 유효한 LocationTag 이름인지 확인
  Future<bool> isValidLocationTagName(String name) async {
    try {
      final locationTag = await getLocationTagByName(name);
      return locationTag != null;
    } catch (e) {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: isValidLocationTagName($name) - 오류: $e');
      }
      return false;
    }
  }

  // 🗺️ 주소에서 LocationTag 추출 (동 이름 기반)
  Future<LocationTagModel?> findLocationTagByAddress(String address) async {
    try {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: findLocationTagByAddress($address) - 시작');
      }

      if (address.trim().isEmpty) {
        throw AddressParsingException('주소가 비어있습니다');
      }

      // 1단계: 주소에서 '동' 이름 추출
      final dongName = _extractDongFromAddress(address);

      if (dongName.isEmpty) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: 주소에서 동 이름을 추출할 수 없음: $address');
        }
        return null;
      }

      if (kDebugMode) {
        print('🏷️ LocationTagRepository: 추출된 동 이름: $dongName');
      }

      // 2단계: 추출된 동 이름으로 LocationTag 조회
      final locationTag = await getLocationTagByName(dongName);

      if (locationTag != null) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: 주소 매칭 성공: ${locationTag.name}');
        }
        return locationTag;
      }

      if (kDebugMode) {
        print('🏷️ LocationTagRepository: 주소에서 LocationTag를 찾을 수 없음');
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: findLocationTagByAddress($address) - 오류: $e');
      }
      throw AddressParsingException('주소 분석에 실패했습니다: $e');
    }
  }

  // 🏠 주소에서 '동' 이름 추출 헬퍼 메소드
  String _extractDongFromAddress(String address) {
    try {
      if (kDebugMode) {
        print(
            '🏠 LocationTagRepository: _extractDongFromAddress($address) - 시작');
      }

      // 동 이름 추출 정규식 패턴들
      // 예: "강남동", "역삼1동", "청담동" 등
      final dongPatterns = [
        RegExp(r'([가-힣]+\d*동)'), // 기본 동 패턴 (숫자 포함 가능)
        RegExp(r'([가-힣]+동)'), // 단순 동 패턴
      ];

      for (final pattern in dongPatterns) {
        final match = pattern.firstMatch(address);
        if (match != null) {
          final dongName = match.group(1)!;
          if (kDebugMode) {
            print('🏠 LocationTagRepository: 동 이름 추출 성공: $dongName');
          }
          return dongName;
        }
      }

      // 동이 없는 경우 구 이름이라도 추출 시도
      // final guPattern = RegExp(r'([가-힣]+구)');
      // final guMatch = guPattern.firstMatch(address);
      // if (guMatch != null) {
      //   final guName = guMatch.group(1)!;
      //   if (kDebugMode) {
      //     print('🏠 LocationTagRepository: 동을 찾을 수 없어 구 이름 반환: $guName');
      //   }
      //   return guName;
      // }

      if (kDebugMode) {
        print('🏠 LocationTagRepository: 주소에서 동 이름을 추출할 수 없음');
      }

      return '';
    } catch (e) {
      if (kDebugMode) {
        print('🏠 LocationTagRepository: _extractDongFromAddress - 오류: $e');
      }
      return '';
    }
  }

  // 🗺️ 좌표 기반 검색은 더 이상 지원하지 않습니다
  // 주소 기반 검색(findLocationTagByAddress)을 사용해주세요
  Future<LocationTagModel?> findLocationTagByCoordinates(
      GeoPoint location) async {
    if (kDebugMode) {
      print(
          '🏷️ LocationTagRepository: findLocationTagByCoordinates() - 더 이상 지원하지 않는 기능');
      print(
          '🏷️ LocationTagRepository: 주소 기반 검색(findLocationTagByAddress)을 사용하세요');
    }
    return null;
  }

  // 🔄 LocationTag 이름을 ID로 변환
  Future<String?> convertLocationTagNameToId(String locationTagName) async {
    try {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: convertLocationTagNameToId($locationTagName) - 시작');
      }

      final locationTag = await getLocationTagByName(locationTagName);

      if (locationTag != null) {
        if (kDebugMode) {
          print(
              '🏷️ LocationTagRepository: 변환 완료: $locationTagName -> ${locationTag.id}');
        }
        return locationTag.id;
      }

      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: LocationTag를 찾을 수 없음: $locationTagName');
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: convertLocationTagNameToId($locationTagName) - 오류: $e');
      }
      throw LocationTagNotFoundException('LocationTag 이름 변환에 실패했습니다: $e');
    }
  }

  // 🔄 LocationTag ID를 이름으로 변환
  Future<String?> convertLocationTagIdToName(String locationTagId) async {
    try {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: convertLocationTagIdToName($locationTagId) - 시작');
      }

      final locationTag = await getLocationTagById(locationTagId);

      if (locationTag != null) {
        if (kDebugMode) {
          print(
              '🏷️ LocationTagRepository: 변환 완료: $locationTagId -> ${locationTag.name}');
        }
        return locationTag.name;
      }

      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: LocationTag를 찾을 수 없음: $locationTagId');
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: convertLocationTagIdToName($locationTagId) - 오류: $e');
      }
      throw LocationTagNotFoundException('LocationTag ID 변환에 실패했습니다: $e');
    }
  }

  // 🧹 캐시 지우기
  void clearCache() {
    if (kDebugMode) {
      print('🏷️ LocationTagRepository: 캐시 지우기');
    }

    _idCache.clear();
    _nameCache.clear();
    _allLocationTags = null;
    _cacheTimestamp = null;
  }

  // ⏰ 캐시가 유효한지 확인
  bool _isCacheValid() {
    if (_cacheTimestamp == null) return false;

    final now = DateTime.now();
    final difference = now.difference(_cacheTimestamp!);

    return difference < _cacheExpiration;
  }

  // 🔍 지원 지역 여부 확인 (호환성 메소드)
  Future<bool> isSupportedRegion(String dongName) async {
    try {
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: isSupportedRegion($dongName) - 시작');
      }

      final locationTag = await getLocationTagByName(dongName);
      final isSupported = locationTag != null;

      if (kDebugMode) {
        print('🏷️ LocationTagRepository: $dongName 지원 여부: $isSupported');
      }

      return isSupported;
    } catch (e) {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: isSupportedRegion($dongName) - 오류: $e');
      }
      return false;
    }
  }

  // 🔍 LocationTag 가용성 확인
  Future<bool> isLocationTagAvailable(String dongName) async {
    try {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: isLocationTagAvailable($dongName) - 시작');
      }

      final locationTag = await getLocationTagByName(dongName);
      final isAvailable = locationTag != null && locationTag.isActive;

      if (kDebugMode) {
        print('🏷️ LocationTagRepository: $dongName 가용성: $isAvailable');
      }

      return isAvailable;
    } catch (e) {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: isLocationTagAvailable($dongName) - 오류: $e');
      }
      return false;
    }
  }

  /// 📍 픽업 정보 조회
  /// LocationTag의 subcollection인 pickup_points에서 데이터 조회
  Future<List<PickupPointModel>> getPickupInfoByLocationTag(
      String locationTagId) async {
    try {
      final querySnapshot = await _firestore
          .collection('location_tags')
          .doc(locationTagId)
          .collection('pickup_points')
          .where('isActive', isEqualTo: true)
          .orderBy('placeName')
          .get();

      final pickupInfoList = querySnapshot.docs
          .map((doc) => PickupPointModel.fromFirestore(doc))
          .toList();

      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: 픽업 정보 조회 완료: ${pickupInfoList.length}개');
      }
      return pickupInfoList;
    } catch (e) {
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: 픽업 정보 조회 실패: $e');
      }
      throw LocationTagException('픽업 정보를 가져오는데 실패했습니다: $e');
    }
  }

  /// 📍 특정 픽업 정보 조회
  Future<PickupPointModel?> getPickupInfoById(
      String locationTagId, String pickupInfoId) async {
    try {
      final doc = await _firestore
          .collection('location_tags')
          .doc(locationTagId)
          .collection('pickup_points')
          .doc(pickupInfoId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return PickupPointModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: 픽업 정보 조회 실패: $e');
      }
      throw LocationTagException('픽업 정보를 가져오는데 실패했습니다: $e');
    }
  }

  // 🔍 기타(Others) LocationTag 조회
  Future<LocationTagModel?> getOthersLocationTag() async {
    try {
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: getOthersLocationTag() - 시작');
      }

      // "기타" 이름의 LocationTag 조회
      final othersTag = await getLocationTagByName('기타');
      
      if (othersTag != null) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: "기타" LocationTag 발견 - ID: ${othersTag.id}');
        }
        return othersTag;
      }

      if (kDebugMode) {
        print('🏷️ LocationTagRepository: "기타" LocationTag를 찾을 수 없음');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: getOthersLocationTag() - 오류: $e');
      }
      return null;
    }
  }

  // 🔄 누락된 LocationTag 처리 (기타 태그 할당)
  Future<String?> handleMissingLocationTag(String dongName) async {
    try {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: handleMissingLocationTag($dongName) - 시작');
      }

      // 이미 존재하는지 확인
      final existingTag = await getLocationTagByName(dongName);
      if (existingTag != null) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: $dongName 이미 존재함');
        }
        return existingTag.id;
      }

      // 존재하지 않으면 '기타' LocationTag 찾기
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: $dongName 존재하지 않음, "기타" 태그 조회');
      }
      
      final othersTag = await getOthersLocationTag();
      if (othersTag != null) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: "기타" 태그 할당 - ID: ${othersTag.id}');
        }
        return othersTag.id;
      }

      if (kDebugMode) {
        print('🏷️ LocationTagRepository: "기타" 태그를 찾을 수 없음');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: handleMissingLocationTag($dongName) - 오류: $e');
      }
      return null;
    }
  }

  // 🔧 개발용: LocationTag 더미 데이터 추가
  Future<void> addDummyLocationTags() async {
    if (kDebugMode) {
      print('🏷️ LocationTagRepository: addDummyLocationTags() - 시작');
    }

    final List<Map<String, dynamic>> dummyLocationTags = [
      {
        'name': '옥수동',
        'description': '서울 성동구 옥수동',
        'isActive': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': '후암동',
        'description': '서울 용산구 후암동',
        'isActive': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': '역삼동',
        'description': '서울 강남구 역삼동',
        'isActive': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
    ];

    try {
      // 기존 데이터가 있는지 확인
      final existingSnapshot = await _locationTagCollection.limit(1).get();

      if (existingSnapshot.docs.isNotEmpty) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: 기존 데이터가 존재함, 더미 데이터 추가 생략');
        }
        return;
      }

      // 더미 데이터 추가
      for (int i = 0; i < dummyLocationTags.length; i++) {
        final locationTagData = dummyLocationTags[i];
        final docId = [
          'oksu_dong',
          'huam_dong',
          'yeoksam_dong',
        ][i];

        await _locationTagCollection.doc(docId).set(locationTagData);
      }

      // 캐시 지우기 (새 데이터 반영)
      clearCache();

      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: ${dummyLocationTags.length}개 더미 LocationTag 추가 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🏷️ LocationTagRepository: addDummyLocationTags() - 오류: $e');
      }
      throw LocationTagException('더미 LocationTag 추가에 실패했습니다: $e');
    }
  }

  // 📍 픽업 포인트 목록 조회
  Future<List<PickupPointModel>> getPickupPoints(String locationTagId) async {
    try {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: getPickupPoints($locationTagId) - 시작');
      }

      final snapshot = await _locationTagCollection
          .doc(locationTagId)
          .collection('pickupPoints')
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('🏷️ LocationTagRepository: 픽업 포인트를 찾을 수 없음');
        }
        return [];
      }

      final pickupPoints = snapshot.docs
          .map((doc) => PickupPointModel.fromFirestore(doc))
          .toList();

      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: ${pickupPoints.length}개 픽업 포인트 조회 완료');
      }
      return pickupPoints;
    } catch (e) {
      if (kDebugMode) {
        print(
            '🏷️ LocationTagRepository: getPickupPoints($locationTagId) - 오류: $e');
      }
      throw LocationTagException('픽업 포인트 조회에 실패했습니다: $e');
    }
  }
}
