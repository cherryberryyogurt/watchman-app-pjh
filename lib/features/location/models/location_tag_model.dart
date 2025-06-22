import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// LocationTag의 지역 정보를 나타내는 모델
class LocationTagRegion extends Equatable {
  final String sido; // "서울특별시"
  final String sigungu; // "강남구"
  final String dong; // "강남동"

  const LocationTagRegion({
    required this.sido,
    required this.sigungu,
    required this.dong,
  });

  /// Firestore 문서에서 LocationTagRegion 생성
  factory LocationTagRegion.fromMap(Map<String, dynamic> map) {
    return LocationTagRegion(
      sido: map['sido'] ?? '',
      sigungu: map['sigungu'] ?? '',
      dong: map['dong'] ?? '',
    );
  }

  /// Firestore 저장용 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'sido': sido,
      'sigungu': sigungu,
      'dong': dong,
    };
  }

  /// 전체 주소 문자열 반환
  String get fullAddress => '$sido $sigungu $dong';

  /// 간단한 주소 문자열 반환 (구 + 동)
  String get shortAddress => '$sigungu $dong';

  @override
  List<Object?> get props => [sido, sigungu, dong];

  LocationTagRegion copyWith({
    String? sido,
    String? sigungu,
    String? dong,
  }) {
    return LocationTagRegion(
      sido: sido ?? this.sido,
      sigungu: sigungu ?? this.sigungu,
      dong: dong ?? this.dong,
    );
  }
}

/// LocationTag의 좌표 정보를 나타내는 모델
class LocationTagCoordinate extends Equatable {
  final double latitude;
  final double longitude;
  final double radius; // 반경 (km)

  const LocationTagCoordinate({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  /// Firestore GeoPoint에서 변환
  factory LocationTagCoordinate.fromGeoPoint(GeoPoint geoPoint, double radius) {
    return LocationTagCoordinate(
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      radius: radius,
    );
  }

  /// Firestore Map에서 변환
  factory LocationTagCoordinate.fromMap(Map<String, dynamic> map) {
    final GeoPoint center = map['center'] as GeoPoint;
    return LocationTagCoordinate(
      latitude: center.latitude,
      longitude: center.longitude,
      radius: (map['radius'] as num?)?.toDouble() ?? 2.0,
    );
  }

  /// Firestore 저장용 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'center': GeoPoint(latitude, longitude),
      'radius': radius,
    };
  }

  /// GeoPoint 변환
  GeoPoint get geoPoint => GeoPoint(latitude, longitude);

  @override
  List<Object?> get props => [latitude, longitude, radius];

  LocationTagCoordinate copyWith({
    double? latitude,
    double? longitude,
    double? radius,
  }) {
    return LocationTagCoordinate(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
    );
  }
}

/// LocationTag 모델
class LocationTagModel extends Equatable {
  final String id; // "uuid"
  final String name; // "강남동"
  final String description; // 지역 설명
  final bool isActive; // 활성화 여부
  final bool isDeleted; // 삭제 여부
  final DateTime createdAt;
  final DateTime updatedAt;

  const LocationTagModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore 문서에서 LocationTagModel 생성
  factory LocationTagModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LocationTagModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore 문서 생성용 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        isActive,
        isDeleted,
        createdAt,
        updatedAt,
      ];

  LocationTagModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationTagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LocationTagModel(id: $id, name: $name, isActive: $isActive, isDeleted: $isDeleted)';
  }
}
