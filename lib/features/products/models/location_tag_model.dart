import 'package:cloud_firestore/cloud_firestore.dart';
import 'pickup_info_model.dart';

class LocationTagModel {
  final String id; // "gangnam_dong"
  final String name; // "강남동"
  final String description; // "강남구 강남동 지역"
  final LocationTagRegion region; // 시도, 시군구, 동 정보
  final List<PickupInfoModel> pickupInfos; // 픽업 정보들
  final bool isActive; // 활성화 여부
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationTagModel({
    required this.id,
    required this.name,
    required this.description,
    required this.region,
    required this.pickupInfos,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore 문서로부터 LocationTagModel 객체 생성
  factory LocationTagModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return LocationTagModel(
      id: documentId,
      name: data['name'] as String,
      description: data['description'] as String,
      region: LocationTagRegion.fromMap(data['region'] as Map<String, dynamic>),
      pickupInfos: (data['pickupInfos'] as List<dynamic>?)
              ?.map((pickupData) => PickupInfoModel.fromFirestore(
                  pickupData as Map<String, dynamic>,
                  pickupData['id'] as String))
              .toList() ??
          [],
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// LocationTagModel 객체를 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'region': region.toMap(),
      'pickupInfos': pickupInfos.map((pickup) => pickup.toFirestore()).toList(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// copyWith 메소드 (상태 업데이트 시 유용)
  LocationTagModel copyWith({
    String? id,
    String? name,
    String? description,
    LocationTagRegion? region,
    List<PickupInfoModel>? pickupInfos,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationTagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      region: region ?? this.region,
      pickupInfos: pickupInfos ?? this.pickupInfos,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 활성화된 픽업 정보만 필터링
  List<PickupInfoModel> get activePickupInfos {
    return pickupInfos.where((pickup) => pickup.isActive).toList();
  }

  /// 오늘 픽업 가능한 정보들
  List<PickupInfoModel> get todayAvailablePickups {
    return activePickupInfos
        .where((pickup) => pickup.isAvailableToday)
        .toList();
  }

  /// 픽업 서비스 가능 여부
  bool get hasPickupService {
    return activePickupInfos.isNotEmpty;
  }

  /// 완전한 위치 주소 (시도 + 시군구 + 동)
  String get fullAddress {
    return '${region.sido} ${region.sigungu} ${region.dong}';
  }

  @override
  String toString() {
    return 'LocationTagModel(id: $id, name: $name, region: $region, pickupInfos: ${pickupInfos.length}, isActive: $isActive)';
  }
}

/// 지역 정보 클래스
class LocationTagRegion {
  final String sido; // 시도 (서울특별시)
  final String sigungu; // 시군구 (강남구)
  final String dong; // 동 (강남동)

  LocationTagRegion({
    required this.sido,
    required this.sigungu,
    required this.dong,
  });

  /// Map에서 LocationTagRegion 생성
  factory LocationTagRegion.fromMap(Map<String, dynamic> map) {
    return LocationTagRegion(
      sido: map['sido'] as String,
      sigungu: map['sigungu'] as String,
      dong: map['dong'] as String,
    );
  }

  /// LocationTagRegion을 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'sido': sido,
      'sigungu': sigungu,
      'dong': dong,
    };
  }

  @override
  String toString() {
    return 'LocationTagRegion(sido: $sido, sigungu: $sigungu, dong: $dong)';
  }
}
