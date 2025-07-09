import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 픽업 정보 모델
/// LocationTag의 subcollection으로 저장됩니다.
/// Path: location_tags/{locationTagId}/pickupPoints/{id}
class PickupPointModel extends Equatable {
  /// 픽업 정보 ID
  final String id;

  /// 픽업 장소명
  final String placeName;

  /// 픽업 장소 주소
  final String address;

  /// 픽업지 연락처
  final String? contact;

  /// 운영 시간 정보 (예: "평일 09:00-18:00")
  final String operatingHours;

  /// 안내사항
  final String? instructions;

  /// 활성화 여부
  final bool isActive;

  /// 생성 시각
  final DateTime createdAt;

  /// 수정 시각
  final DateTime updatedAt;

  const PickupPointModel({
    required this.id,
    required this.placeName,
    required this.address,
    this.contact,
    required this.operatingHours,
    this.instructions,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore 문서로부터 생성
  factory PickupPointModel.fromFirestore(
    DocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return PickupPointModel.fromMap(data, doc.id);
  }

  /// Map으로부터 생성
  factory PickupPointModel.fromMap(Map<String, dynamic> map, String id) {
    return PickupPointModel(
      id: id,
      placeName: map['placeName'] as String,
      address: map['address'] as String,
      contact: map['contact'] as String?,
      operatingHours: map['operatingHours'] as String,
      instructions: map['instructions'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'placeName': placeName,
      'address': address,
      'contact': contact,
      'operatingHours': operatingHours,
      'instructions': instructions,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Map으로 변환 (ID 포함)
  Map<String, dynamic> toMap() {
    final map = toFirestore();
    map['id'] = id;
    return map;
  }

  /// 연락처 정보 존재 여부
  bool get hasContact => contact != null && contact!.isNotEmpty;

  /// 안내사항 존재 여부
  bool get hasInstructions => instructions != null && instructions!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        placeName,
        address,
        contact,
        operatingHours,
        instructions,
        isActive,
        createdAt,
        updatedAt,
      ];

  PickupPointModel copyWith({
    String? id,
    String? placeName,
    String? address,
    String? contact,
    String? operatingHours,
    String? instructions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PickupPointModel(
      id: id ?? this.id,
      placeName: placeName ?? this.placeName,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      operatingHours: operatingHours ?? this.operatingHours,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
