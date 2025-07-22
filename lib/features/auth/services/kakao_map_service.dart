import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../../core/config/env_config.dart';
import '../../../core/constants/error_messages.dart';

/// 주소 정보를 담는 클래스
class AddressInfo {
  final String roadNameAddress; // 도로명 주소
  final String locationAddress; // 지번 주소
  final String locationTag; // 행정구역 (예: 서울특별시 강남구)

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

  /// 생성자: 초기화 시 환경 설정 상태 확인
  KakaoMapService() {
    print('🗺️ KakaoMapService 생성자 호출');

    // .env 파일 로드 상태 확인
    try {
      EnvConfig.printEnvStatus();
      print('🗺️ 최종 API 키 상태: ${isApiKeyValid ? "유효" : "무효"}');

      if (apiKey.isEmpty) {
        print('❌ KakaoMapService: API 키가 비어있습니다. .env 파일이 로드되지 않았을 가능성이 있습니다.');
        throw Exception('카카오 API 키가 설정되지 않았습니다. 앱을 재시작해주세요.');
      }
    } catch (e) {
      print('❌ KakaoMapService: 초기화 중 오류 발생: $e');
      // NotInitializedError나 기타 초기화 오류를 더 명확하게 처리
      if (e.toString().contains('NotInitializedError') ||
          e.toString().contains('dotenv') ||
          e.toString().contains('env')) {
        throw Exception('앱 환경 설정이 아직 초기화되지 않았습니다. 잠시 후 다시 시도해주세요.');
      }
      rethrow;
    }
  }

  /// API 키 유효성 검증
  bool get isApiKeyValid {
    // 카카오 API 키는 32자의 영숫자 문자열입니다
    if (apiKey.isEmpty) return false;

    // 기본값들 체크
    final defaultKeys = [
      'your-kakao-api-key-here',
      'YOUR_KAKAO_MAP_API_KEY',
      'your_kakao_map_api_key_here'
    ];

    if (defaultKeys.contains(apiKey)) return false;

    // 카카오 API 키 형식 체크 (32자 영숫자)
    final RegExp kakaoKeyPattern = RegExp(r'^[a-zA-Z0-9]{32}$');
    return kakaoKeyPattern.hasMatch(apiKey);
  }

  /// 네이티브 앱 키 전용 공통 헤더 생성
  Map<String, String> get _commonHeaders {
    final kaHeader = _getKAHeader();
    print('🗺️ Using Native App Key');
    print(
        '🗺️ Platform: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Unknown"}');
    print('🗺️ KA Header: $kaHeader');
    print(
        '🗺️ API Key (마지막 4자리): ${apiKey.length >= 4 ? apiKey.substring(apiKey.length - 4) : apiKey}');

    return {
      'Authorization': 'KakaoAK $apiKey',
      'Content-Type': 'application/json',
      'KA': kaHeader,
    };
  }

  /// 플랫폼별 KA Header 생성 (네이티브 앱 키 전용)
  String _getKAHeader() {
    if (kIsWeb) {
      return 'sdk/flutter os/web app/gonggoo-app';
    } else if (Platform.isAndroid) {
      return 'sdk/flutter os/android app/gonggoo-app';
    } else if (Platform.isIOS) {
      return 'sdk/flutter os/ios app/gonggoo-app';
    } else {
      // 기타 플랫폼 (웹, 데스크톱 등)
      return 'sdk/flutter os/mobile app/gonggoo-app';
    }
  }

  /// 대안 KA Header 형식들 (실패 시 순서대로 시도)
  List<String> _getAlternativeKAHeaders() {
    if (kIsWeb) {
      return [
        'sdk/flutter os/web app/gonggoo-app', // 우선순위 1: 기본 형식
        'os/web app/gonggoo-app', // 우선순위 2: 단순화된 형식
        'os/web', // 우선순위 3: 플랫폼 정보만
        'app/gonggoo-app', // 우선순위 4: 앱 정보만
      ];
    } else if (Platform.isAndroid) {
      return [
        'sdk/flutter os/android app/gonggoo-app', // 우선순위 1: 기본 형식
        'os/android app/gonggoo-app', // 우선순위 2: 단순화된 형식
        'os/android', // 우선순위 3: 플랫폼 정보만
        'app/gonggoo-app', // 우선순위 4: 앱 정보만
      ];
    } else if (Platform.isIOS) {
      return [
        'sdk/flutter os/ios app/gonggoo-app', // 우선순위 1: 기본 형식
        'os/ios app/gonggoo-app', // 우선순위 2: 단순화된 형식
        'os/ios', // 우선순위 3: 플랫폼 정보만
        'app/gonggoo-app', // 우선순위 4: 앱 정보만
      ];
    } else {
      return [
        'sdk/flutter os/mobile app/gonggoo-app',
        'os/mobile app/gonggoo-app',
        'app/gonggoo-app',
      ];
    }
  }

  /// 특정 KA Header로 헤더 생성
  Map<String, String> _getHeadersWithKA(String kaHeader) {
    return {
      'Authorization': 'KakaoAK $apiKey',
      'Content-Type': 'application/json',
      'KA': kaHeader,
    };
  }

  /// 현재 위치 권한 요청 및 위치 가져오기
  Future<Position> getCurrentPosition() async {
    print('🗺️ KakaoMapService.getCurrentPosition() 시작');

    // 위치 서비스 활성화 상태 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('🗺️ 위치 서비스 활성화: $serviceEnabled');

    if (!serviceEnabled) {
      throw Exception('위치 서비스가 비활성화되어 있습니다. 설정에서 위치 서비스를 활성화해주세요.');
    }

    // 위치 권한 확인
    LocationPermission permission = await Geolocator.checkPermission();
    print('🗺️ 위치 권한 상태: $permission');

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print('🗺️ 권한 요청 후 상태: $permission');

      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
    }

    // 현재 위치 가져오기
    try {
      print('🗺️ 현재 위치 요청 중...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      print('🗺️ 현재 위치 획득 성공: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('🗺️ ❌ 현재 위치 가져오기 실패: $e');
      debugPrint('현재 위치를 가져오는 중 오류 발생: $e');
      throw Exception('현재 위치를 가져오는 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 좌표를 주소로 변환 (카카오맵 API 사용)
  Future<AddressInfo> getAddressFromCoords({
    required double latitude,
    required double longitude,
  }) async {
    print('🗺️ getAddressFromCoords() 시작');
    print('🗺️ 좌표: $latitude, $longitude');

    if (apiKey.isEmpty || apiKey == 'your-kakao-api-key-here') {
      print('🗺️ ❌ API 키가 유효하지 않음');
      throw Exception('카카오 API 키가 설정되지 않았거나 유효하지 않습니다.');
    }

    // if (!isApiKeyValid) {
    //   print('🗺️ ❌ API 키가 유효하지 않음');
    //   throw Exception('카카오 API 키가 설정되지 않았거나 유효하지 않습니다.');
    // }

    final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$longitude&y=$latitude&input_coord=WGS84');
    print('🗺️ 요청 URL: $url');

    try {
      print('🗺️ HTTP 요청 시작...');
      final response = await http.get(
        url,
        headers: _commonHeaders,
      );

      print('🗺️ HTTP 응답 상태: ${response.statusCode}');
      print('🗺️ HTTP 응답 본문: ${response.body}');

      // 실제 API 응답으로 유효성 판단
      if (response.statusCode == 401) {
        throw Exception('카카오 API 키가 유효하지 않습니다. 개발자 콘솔에서 확인해주세요.');
      }

      if (response.statusCode == 403) {
        throw Exception('카카오 API 호출 권한이 없습니다. 앱 설정을 확인해주세요.');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🗺️ 파싱된 데이터: $data');

        if (data['documents'] == null || data['documents'].isEmpty) {
          print('🗺️ ❌ 주소 변환 결과 없음');
          throw Exception('주소 변환 결과가 없습니다.');
        }

        final document = data['documents'][0];
        final address = document['address'];
        final roadAddress = document['road_address'];

        print('🗺️ address: $address');
        print('🗺️ roadAddress: $roadAddress');

        // 지번 주소
        final locationAddress = address != null
            ? [
                address['region_1depth_name'] ?? '',
                address['region_2depth_name'] ?? '',
                address['region_3depth_name'] ?? '',
                address['main_address_no'] ?? '',
              ].where((s) => s.isNotEmpty).join(' ')
            : '주소를 찾을 수 없습니다';

        // 도로명 주소
        final roadNameAddress = roadAddress != null
            ? '${roadAddress['address_name']}'
            : '도로명 주소를 찾을 수 없습니다';

        // 위치 태그 (시/도 + 구/군)
        final locationTag = address != null
            ? '${address['region_1depth_name']} ${address['region_2depth_name']}'
            : '위치 정보를 찾을 수 없습니다';

        print('🗺️ ✅ 주소 변환 성공');
        print('🗺️ 도로명: $roadNameAddress');
        print('🗺️ 지번: $locationAddress');
        print('🗺️ 태그: $locationTag');

        return AddressInfo(
          roadNameAddress: roadNameAddress,
          locationAddress: locationAddress,
          locationTag: locationTag,
        );
      } else {
        print('🗺️ ❌ API 호출 실패: ${response.statusCode}');
        throw Exception('주소 변환 API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('🗺️ ❌ 예외 발생: $e');
      print('🗺️ 예외 타입: ${e.runtimeType}');
      debugPrint('주소 변환 중 오류 발생: $e');

      // NotInitializedError 특별 처리
      if (e.toString().contains('NotInitializedError')) {
        throw Exception('앱 초기화가 완료되지 않았습니다. 앱을 재시작해주세요.');
      }

      throw Exception('주소 변환 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 주소로 좌표 검색 (카카오맵 API 사용)
  Future<Map<String, double>> getCoordsFromAddress(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/address.json?query=$encodedAddress');

    try {
      final response = await http.get(
        url,
        headers: _commonHeaders,
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

  /// 도로명 주소 검색 및 상세 정보 조회 (카카오맵 API 사용)
  Future<Map<String, dynamic>?> searchAddressDetails(String query) async {
    print('🗺️ searchAddressDetails() 시작');
    print('🗺️ 검색어: $query');

    if (!isApiKeyValid) {
      print('🗺️ ❌ API 키가 유효하지 않음');
      throw Exception(AddressErrorMessages.kakaoApi);
    }

    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/address.json?query=$encodedQuery');
    print('🗺️ 요청 URL: $url');

    // 대안 KA Header 형식들을 순서대로 시도
    final alternativeHeaders = _getAlternativeKAHeaders();

    for (int i = 0; i < alternativeHeaders.length; i++) {
      final kaHeader = alternativeHeaders[i];
      final headers = _getHeadersWithKA(kaHeader);

      print(
          '🗺️ 시도 ${i + 1}/${alternativeHeaders.length} - KA Header: $kaHeader');

      try {
        print('🗺️ HTTP 요청 시작...');
        final response = await http.get(url, headers: headers);

        print('🗺️ HTTP 응답 상태: ${response.statusCode}');
        print('🗺️ HTTP 응답 본문: ${response.body}');

        // 401 에러인 경우 다음 형식 시도
        if (response.statusCode == 401) {
          print('🗺️ ❌ KA Header 형식 실패, 다음 형식 시도...');
          if (i < alternativeHeaders.length - 1) {
            continue; // 다음 형식 시도
          } else {
            throw Exception(AddressErrorMessages.kakaoApi);
          }
        }

        if (response.statusCode == 403) {
          throw Exception(AddressErrorMessages.kakaoApi);
        }

        if (response.statusCode != 200) {
          throw Exception(AddressErrorMessages.kakaoApi);
        }

        // 성공한 경우
        print('🗺️ ✅ 성공한 KA Header 형식: $kaHeader');

        final data = jsonDecode(response.body);
        print('🗺️ 파싱된 데이터: $data');

        if (data['documents'] == null || data['documents'].isEmpty) {
          print('🗺️ ❌ 주소 검색 결과 없음');
          return null; // 검색 결과가 없으면 null 반환
        }

        final document = data['documents'][0];
        final address = document['address'];
        final roadAddress = document['road_address'];

        print('🗺️ address: $address');
        print('🗺️ roadAddress: $roadAddress');

        // 좌표 정보
        final longitude = double.parse(document['x']);
        final latitude = double.parse(document['y']);

        // 지번 주소
        final locationAddress = address != null
            ? [
                address['region_1depth_name'] ?? '',
                address['region_2depth_name'] ?? '',
                address['region_3depth_name'] ?? '',
                address['main_address_no'] ?? '',
              ].where((s) => s.isNotEmpty).join(' ')
            : '주소를 찾을 수 없습니다';

        // 도로명 주소
        final roadNameAddress = roadAddress != null
            ? '${roadAddress['address_name']}'
            : address != null
                ? locationAddress
                : '도로명 주소를 찾을 수 없습니다';

        // 위치 태그 (region_3depth_name - 동 정보)
        final locationTag = address != null
            ? (address['region_3depth_name'] ?? '알 수 없는 지역')
            : '알 수 없는 지역';

        // 건물명 추출
        final buildingName = roadAddress != null 
            ? (roadAddress['building_name'] ?? '')
            : '';

        print('🗺️ ✅ 주소 검색 성공');
        print('🗺️ 도로명: $roadNameAddress');
        print('🗺️ 지번: $locationAddress');
        print('🗺️ 태그: $locationTag');
        print('🗺️ 건물명: $buildingName');
        print('🗺️ 좌표: $latitude, $longitude');

        return {
          'roadNameAddress': roadNameAddress,
          'locationAddress': locationAddress,
          'locationTag': locationTag,
          'buildingName': buildingName,
          'latitude': latitude,
          'longitude': longitude,
        };
      } catch (e) {
        print('🗺️ ❌ 시도 ${i + 1} 예외 발생: $e');
        print('🗺️ 예외 타입: ${e.runtimeType}');

        // 네트워크 관련 에러인 경우 재시도하지 않고 즉시 종료
        if (e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException')) {
          throw Exception(AddressErrorMessages.network);
        }

        // 마지막 시도였다면 에러 발생
        if (i == alternativeHeaders.length - 1) {
          debugPrint('주소 검색 중 오류 발생: $e');
          throw Exception(AddressErrorMessages.kakaoApi);
        }
      }
    }

    // 모든 시도 실패
    throw Exception(AddressErrorMessages.kakaoApi);
  }

  /// 두 좌표 간 거리 계산 (km) - Haversine 공식 사용
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    print('🗺️ calculateDistance() 시작');
    print('🗺️ 좌표1: $lat1, $lon1');
    print('🗺️ 좌표2: $lat2, $lon2');

    const double earthRadius = 6371; // 지구 반지름 (km)

    // 위도와 경도를 라디안으로 변환
    final double lat1Rad = lat1 * pi / 180;
    final double lon1Rad = lon1 * pi / 180;
    final double lat2Rad = lat2 * pi / 180;
    final double lon2Rad = lon2 * pi / 180;

    // 위도와 경도의 차이
    final double deltaLat = lat2Rad - lat1Rad;
    final double deltaLon = lon2Rad - lon1Rad;

    // Haversine 공식
    final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    print('🗺️ ✅ 거리 계산 결과: ${distance.toStringAsFixed(2)}km');
    return distance;
  }
}
