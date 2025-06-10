import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 픽업 정보 모델
/// LocationTag의 subcollection으로 저장됩니다.
/// Path: location_tags/{locationTagId}/pickup_info/{id}
class PickupInfoModel extends Equatable {
  /// 픽업 정보 ID
  final String id;

  /// 픽업 장소명
  final String placeName;

  /// 픽업 장소 주소
  final String address;

  /// 상세 주소 (동/호수 등)
  final String? detailAddress;

  /// 픽업 담당자 이름
  final String? contactName;

  /// 픽업 담당자 연락처
  final String? contactPhone;

  /// 운영 시간 정보 (예: "평일 09:00-18:00")
  final List<String> operatingHours;

  /// 픽업 가능 요일 (0: 일요일, 1: 월요일, ..., 6: 토요일)
  final List<int> availableDays;

  /// 특별 안내사항
  final String? specialInstructions;

  /// 픽업 장소 위도
  final double? latitude;

  /// 픽업 장소 경도
  final double? longitude;

  /// 활성화 여부
  final bool isActive;

  /// 생성 시각
  final DateTime createdAt;

  /// 수정 시각
  final DateTime updatedAt;

  const PickupInfoModel({
    required this.id,
    required this.placeName,
    required this.address,
    this.detailAddress,
    this.contactName,
    this.contactPhone,
    required this.operatingHours,
    required this.availableDays,
    this.specialInstructions,
    this.latitude,
    this.longitude,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore 문서로부터 생성
  factory PickupInfoModel.fromFirestore(
    DocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return PickupInfoModel.fromMap(data, doc.id);
  }

  /// Map으로부터 생성
  factory PickupInfoModel.fromMap(Map<String, dynamic> map, String id) {
    return PickupInfoModel(
      id: id,
      placeName: map['placeName'] as String,
      address: map['address'] as String,
      detailAddress: map['detailAddress'] as String?,
      contactName: map['contactName'] as String?,
      contactPhone: map['contactPhone'] as String?,
      operatingHours: List<String>.from(map['operatingHours'] ?? []),
      availableDays: List<int>.from(map['availableDays'] ?? []),
      specialInstructions: map['specialInstructions'] as String?,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
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
      'detailAddress': detailAddress,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'operatingHours': operatingHours,
      'availableDays': availableDays,
      'specialInstructions': specialInstructions,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// 전체 주소 반환
  String get fullAddress {
    if (detailAddress != null && detailAddress!.isNotEmpty) {
      return '$address $detailAddress';
    }
    return address;
  }

  /// 요일 이름 반환
  List<String> get availableDayNames {
    const dayNames = ['일', '월', '화', '수', '목', '금', '토'];
    return availableDays.map((day) => dayNames[day]).toList();
  }

  /// 오늘 픽업 가능 여부
  bool get isAvailableToday {
    final today = DateTime.now().weekday % 7; // DateTime.weekday는 1(월)~7(일)
    return availableDays.contains(today);
  }

  /// 연락처 포맷팅
  String get formattedContactInfo {
    if (contactName != null && contactPhone != null) {
      return '$contactName ($contactPhone)';
    } else if (contactName != null) {
      return contactName!;
    } else if (contactPhone != null) {
      return contactPhone!;
    }
    return '담당자 정보 없음';
  }

  @override
  List<Object?> get props => [
        id,
        placeName,
        address,
        detailAddress,
        contactName,
        contactPhone,
        operatingHours,
        availableDays,
        specialInstructions,
        latitude,
        longitude,
        isActive,
        createdAt,
        updatedAt,
      ];

  PickupInfoModel copyWith({
    String? id,
    String? placeName,
    String? address,
    String? detailAddress,
    String? contactName,
    String? contactPhone,
    List<String>? operatingHours,
    List<int>? availableDays,
    String? specialInstructions,
    double? latitude,
    double? longitude,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PickupInfoModel(
      id: id ?? this.id,
      placeName: placeName ?? this.placeName,
      address: address ?? this.address,
      detailAddress: detailAddress ?? this.detailAddress,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      operatingHours: operatingHours ?? this.operatingHours,
      availableDays: availableDays ?? this.availableDays,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
