import 'package:cloud_firestore/cloud_firestore.dart';

class PickupInfoModel {
  final String id;
  final String spotName; // 픽업 장소명
  final String address; // 픽업 장소 주소
  final List<DateTime> pickupTimes; // 픽업 가능 시간들
  final bool isActive; // 활성화 여부
  final DateTime createdAt;
  final DateTime updatedAt;

  PickupInfoModel({
    required this.id,
    required this.spotName,
    required this.address,
    required this.pickupTimes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore 문서로부터 PickupInfoModel 객체 생성
  factory PickupInfoModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return PickupInfoModel(
      id: documentId,
      spotName: data['spotName'] as String,
      address: data['address'] as String,
      pickupTimes: (data['pickupTimes'] as List<dynamic>)
          .map((timestamp) => (timestamp as Timestamp).toDate())
          .toList(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// PickupInfoModel 객체를 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'spotName': spotName,
      'address': address,
      'pickupTimes':
          pickupTimes.map((dateTime) => Timestamp.fromDate(dateTime)).toList(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// copyWith 메소드 (상태 업데이트 시 유용)
  PickupInfoModel copyWith({
    String? id,
    String? spotName,
    String? address,
    List<DateTime>? pickupTimes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PickupInfoModel(
      id: id ?? this.id,
      spotName: spotName ?? this.spotName,
      address: address ?? this.address,
      pickupTimes: pickupTimes ?? this.pickupTimes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 픽업 시간 포맷팅 (한국 시간 기준)
  List<String> get formattedPickupTimes {
    return pickupTimes.map((dateTime) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }).toList();
  }

  /// 오늘 픽업 가능한지 확인
  bool get isAvailableToday {
    if (!isActive) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return pickupTimes.any((pickupTime) {
      final pickupDate =
          DateTime(pickupTime.year, pickupTime.month, pickupTime.day);
      return pickupDate.isAtSameMomentAs(today) && pickupTime.isAfter(now);
    });
  }

  @override
  String toString() {
    return 'PickupInfoModel(id: $id, spotName: $spotName, address: $address, pickupTimes: $pickupTimes, isActive: $isActive)';
  }
}
