import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/location_tag_repository.dart';
import '../models/location_tag_model.dart';
import '../exceptions/location_tag_exceptions.dart';

/// 🏷️ LocationTag Repository 사용 예시
class LocationTagUsageExample {
  final LocationTagRepository _locationTagRepository;

  LocationTagUsageExample(this._locationTagRepository);

  /// 🔍 기본 조회 기능 예시
  Future<void> basicQueryExamples() async {
    try {
      print('🏷️ === 기본 조회 기능 예시 ===');

      // 1. ID로 LocationTag 조회
      final locationTagById =
          await _locationTagRepository.getLocationTagById('gangnam_dong');
      if (locationTagById != null) {
        print(
            '✅ ID 조회 성공: ${locationTagById.name} (${locationTagById.description})');
      } else {
        print('❌ ID "gangnam_dong"에 해당하는 LocationTag를 찾을 수 없음');
      }

      // 2. 이름으로 LocationTag 조회
      final locationTagByName =
          await _locationTagRepository.getLocationTagByName('강남동');
      if (locationTagByName != null) {
        print(
            '✅ 이름 조회 성공: ${locationTagByName.name} (${locationTagByName.description})');
      } else {
        print('❌ "강남동"에 해당하는 LocationTag를 찾을 수 없음');
      }

      // 3. 지원되는 모든 지역 조회
      final allRegions = await _locationTagRepository.getSupportedRegions();
      print('✅ 지원 지역 총 ${allRegions.length}개:');
      for (final region in allRegions) {
        print('   - ${region.name} (${region.description})');
      }
    } catch (e) {
      print('❌ 기본 조회 예시 실행 중 오류: $e');
    }
  }

  /// 🗺️ 주소 기반 검색 예시
  Future<void> addressBasedSearchExamples() async {
    try {
      print('\n🏷️ === 주소 기반 검색 예시 ===');

      // 주소로 LocationTag 찾기
      final addressExamples = [
        '서울특별시 강남구 강남동 123-45',
        '서초구 서초동',
        '송파구 송파동 456번지',
        '영등포구 영등포동',
        '강서구 강서동',
        '마포구 홍대입구역', // 지원하지 않는 지역
      ];

      for (final address in addressExamples) {
        final locationTag =
            await _locationTagRepository.findLocationTagByAddress(address);
        if (locationTag != null) {
          print('✅ 주소 "$address" -> LocationTag: ${locationTag.name}');
        } else {
          print('❌ 주소 "$address" -> 지원하지 않는 지역');
        }
      }
    } catch (e) {
      print('❌ 주소 기반 검색 예시 실행 중 오류: $e');
    }
  }

  /// ✅ 검증 기능 예시
  Future<void> validationExamples() async {
    try {
      print('\n🏷️ === 검증 기능 예시 ===');

      // 1. LocationTag ID 유효성 검증
      final idExamples = ['gangnam_dong', 'seocho_dong', 'invalid_id'];
      for (final id in idExamples) {
        final isValid = await _locationTagRepository.isValidLocationTagId(id);
        print('${isValid ? '✅' : '❌'} LocationTag ID "$id" 유효성: $isValid');
      }

      // 2. LocationTag 이름 유효성 검증
      final nameExamples = ['강남동', '서초동', '홍대입구'];
      for (final name in nameExamples) {
        final isValid =
            await _locationTagRepository.isValidLocationTagName(name);
        print('${isValid ? '✅' : '❌'} LocationTag 이름 "$name" 유효성: $isValid');
      }
    } catch (e) {
      print('❌ 검증 기능 예시 실행 중 오류: $e');
    }
  }

  /// 🔄 변환 기능 예시
  Future<void> conversionExamples() async {
    try {
      print('\n🏷️ === 변환 기능 예시 ===');

      // 1. 이름 -> ID 변환
      final nameToIdExamples = ['강남동', '서초동', '송파동'];
      for (final name in nameToIdExamples) {
        final id =
            await _locationTagRepository.convertLocationTagNameToId(name);
        if (id != null) {
          print('✅ 이름 "$name" -> ID: "$id"');
        } else {
          print('❌ 이름 "$name" -> 변환 실패');
        }
      }

      // 2. ID -> 이름 변환
      final idToNameExamples = ['gangnam_dong', 'seocho_dong', 'songpa_dong'];
      for (final id in idToNameExamples) {
        final name =
            await _locationTagRepository.convertLocationTagIdToName(id);
        if (name != null) {
          print('✅ ID "$id" -> 이름: "$name"');
        } else {
          print('❌ ID "$id" -> 변환 실패');
        }
      }
    } catch (e) {
      print('❌ 변환 기능 예시 실행 중 오류: $e');
    }
  }

  /// 🔧 개발용 기능 예시
  Future<void> developmentExamples() async {
    try {
      print('\n🏷️ === 개발용 기능 예시 ===');

      // 더미 데이터 추가 (개발 환경에서만)
      if (kDebugMode) {
        await _locationTagRepository.addDummyLocationTags();
        print('✅ 더미 LocationTag 데이터 추가 완료');
      }

      // 캐시 지우기
      _locationTagRepository.clearCache();
      print('✅ LocationTag 캐시 지우기 완료');
    } catch (e) {
      print('❌ 개발용 기능 예시 실행 중 오류: $e');
    }
  }

  /// 🎯 실제 사용 시나리오 예시
  Future<void> realWorldScenarioExamples() async {
    try {
      print('\n🏷️ === 실제 사용 시나리오 예시 ===');

      // 시나리오 1: 사용자 회원가입 시 주소 검증
      print('\n📝 시나리오 1: 사용자 회원가입 시 주소 검증');
      final userAddress = '서울특별시 강남구 강남동 123-45';
      final locationTag =
          await _locationTagRepository.findLocationTagByAddress(userAddress);

      if (locationTag != null) {
        print('✅ 회원가입 가능 지역: ${locationTag.name}');
        print('   - LocationTag ID: ${locationTag.id}');
        print('   - 서비스 설명: ${locationTag.description}');
      } else {
        print('❌ 서비스 지원하지 않는 지역입니다');
      }

      // 시나리오 2: 관리자 페이지에서 지원 지역 목록 표시
      print('\n🔧 시나리오 2: 관리자 페이지에서 지원 지역 목록 표시');
      final supportedRegions =
          await _locationTagRepository.getSupportedRegions();
      print('✅ 현재 서비스 지원 지역 (${supportedRegions.length}개):');

      for (final region in supportedRegions) {
        print('   - ${region.name}');
        print('     설명: ${region.description}');
        print('     활성화: ${region.isActive}');
        print('     생성일: ${region.createdAt}');
      }
    } catch (e) {
      print('❌ 실제 사용 시나리오 예시 실행 중 오류: $e');
    }
  }

  /// 🚀 모든 예시 실행
  Future<void> runAllExamples() async {
    print('🎉 LocationTag Repository 사용 예시 시작\n');

    await basicQueryExamples();
    await addressBasedSearchExamples();
    await validationExamples();
    await conversionExamples();
    await developmentExamples();
    await realWorldScenarioExamples();

    print('\n🎉 LocationTag Repository 사용 예시 완료');
  }
}
