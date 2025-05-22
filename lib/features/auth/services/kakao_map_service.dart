import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../../core/config/env_config.dart';

/// 주소 정보를 담는 클래스
class AddressInfo {
  final String roadNameAddress; // 도로명 주소
  final String locationAddress; // 지번 주소
  final String locationTag;     // 행정구역 (예: 서울특별시 강남구)

  AddressInfo({
    required this.roadNameAddress,
    required this.locationAddress,
    required this.locationTag,
  });
}

/// 카카오맵 API를 이용한 위치 서비스
class KakaoMapService {
  // 카카오맵 REST API 키
  final String apiKey = EnvConfig.kakaoMapApiKey;

  /// 현재 위치 권한 요청 및 위치 가져오기
  Future<Position> getCurrentPosition() async {
    // 위치 서비스 활성화 상태 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('위치 서비스가 비활성화되어 있습니다. 설정에서 위치 서비스를 활성화해주세요.');
    }

    // 위치 권한 확인
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 거부되었습니다.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
    }

    // 현재 위치 가져오기
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('현재 위치를 가져오는 중 오류 발생: $e');
      throw Exception('현재 위치를 가져오는 중 오류가 발생했습니다.');
    }
  }

  /// 좌표를 주소로 변환 (카카오맵 API 사용)
  Future<AddressInfo> getAddressFromCoords({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$longitude&y=$latitude&input_coord=WGS84'
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'KakaoAK $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['documents'] == null || data['documents'].isEmpty) {
          throw Exception('주소 변환 결과가 없습니다.');
        }

        final document = data['documents'][0];
        final address = document['address'];
        final roadAddress = document['road_address'];

        // 지번 주소
        final locationAddress = address != null
            ? '${address['region_1depth_name']} ${address['region_2depth_name']} ${address['region_3depth_name']} ${address['main_address_no'] ?? ''}'
            : '주소를 찾을 수 없습니다';

        // 도로명 주소
        final roadNameAddress = roadAddress != null
            ? '${roadAddress['address_name']}'
            : '도로명 주소를 찾을 수 없습니다';

        // 위치 태그 (시/도 + 구/군)
        final locationTag = address != null
            ? '${address['region_1depth_name']} ${address['region_2depth_name']}'
            : '위치 정보를 찾을 수 없습니다';

        return AddressInfo(
          roadNameAddress: roadNameAddress,
          locationAddress: locationAddress,
          locationTag: locationTag,
        );
      } else {
        throw Exception('주소 변환 API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('주소 변환 중 오류 발생: $e');
      throw Exception('주소 변환 중 오류가 발생했습니다: $e');
    }
  }

  /// 주소로 좌표 검색 (카카오맵 API 사용)
  Future<Map<String, double>> getCoordsFromAddress(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/address.json?query=$encodedAddress'
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'KakaoAK $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['documents'] == null || data['documents'].isEmpty) {
          throw Exception('검색 결과가 없습니다.');
        }

        final document = data['documents'][0];
        final x = double.parse(document['x']);
        final y = double.parse(document['y']);

        return {
          'longitude': x,
          'latitude': y,
        };
      } else {
        throw Exception('좌표 검색 API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('좌표 검색 중 오류 발생: $e');
      throw Exception('좌표 검색 중 오류가 발생했습니다: $e');
    }
  }
} 