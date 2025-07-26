import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Equatable {
  final String uid;
  final String name; // 이름
  final String? phoneNumber; // 전화번호
  final String? roadNameAddress; // 도로명 주소
  final String? detailedAddress; // 상세 주소 (동/호수 등)
  final String? locationAddress; // 지번 주소
  final String? postalCode; // 우편번호

  // 🔄 수정된 부분: locationTag -> locationTagId + locationTagName
  final String? locationTagId; // 위치 태그 ID :: 참조용
  final String? locationTagName; // 위치 태그 이름 :: 성능을 위한 중복 저장

  // 🆕 LocationTag 상태 관리 필드들
  final String locationStatus; // "active" | "pending" | "unavailable" | "none"
  final String? pendingLocationName; // LocationTag가 없는 지역인 경우 임시 저장

  // 🆕 배송 주소 관리 필드
  final List<String> deliveryAddressIds; // 배송 주소 ID 리스트 :: DeliveryAddress 참조

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.name,
    this.phoneNumber,
    this.roadNameAddress,
    this.detailedAddress,
    this.locationAddress,
    this.postalCode,
    this.locationTagId, // 🔄 수정
    this.locationTagName, // 🔄 추가
    this.locationStatus = 'none', // 🆕 기본값
    this.pendingLocationName, // 🆕 추가
    this.deliveryAddressIds = const [], // 🆕 배송 주소 ID 리스트
    required this.createdAt,
    required this.updatedAt,
  });

  // Empty user
  static UserModel get empty => UserModel(
        uid: '',
        name: '',
        phoneNumber: null,
        roadNameAddress: null,
        detailedAddress: null,
        locationAddress: null,
        postalCode: null,
        locationTagId: null, // 🔄 수정
        locationTagName: null, // 🔄 추가
        locationStatus: 'none', // 🆕 추가
        pendingLocationName: null, // 🆕 추가
        deliveryAddressIds: const [], // 🆕 추가
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // Check if user is empty
  bool get isEmpty => this == UserModel.empty;
  bool get isNotEmpty => this != UserModel.empty;

  // 🆕 LocationTag 상태 확인 헬퍼 메서드들
  bool get hasActiveLocationTag =>
      locationStatus == 'active' && locationTagId != null;
  bool get isLocationPending => locationStatus == 'pending';
  bool get isLocationUnavailable => locationStatus == 'unavailable';
  bool get hasNoLocation => locationStatus == 'none';

  /// 주소 인증 완료 여부
  bool get isAddressVerified => hasActiveLocationTag;

  /// 위치 상태 메시지
  String get locationStatusMessage {
    switch (locationStatus) {
      case 'active':
        return '위치 인증 완료';
      case 'pending':
        return '서비스 준비중인 지역';
      case 'unavailable':
        return '서비스 지원하지 않는 지역';
      case 'none':
      default:
        return '위치 미설정';
    }
  }

  // Copy with method
  UserModel copyWith({
    String? uid,
    String? name,
    String? phoneNumber,
    String? roadNameAddress,
    String? detailedAddress,
    String? locationAddress,
    String? postalCode,
    String? locationTagId, // 🔄 수정
    String? locationTagName, // 🔄 추가
    String? locationStatus, // 🆕 추가
    String? pendingLocationName, // 🆕 추가
    List<String>? deliveryAddressIds, // 🆕 추가
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roadNameAddress: roadNameAddress ?? this.roadNameAddress,
      detailedAddress: detailedAddress ?? this.detailedAddress,
      locationAddress: locationAddress ?? this.locationAddress,
      postalCode: postalCode ?? this.postalCode,
      locationTagId: locationTagId ?? this.locationTagId, // 🔄 수정
      locationTagName: locationTagName ?? this.locationTagName, // 🔄 추가
      locationStatus: locationStatus ?? this.locationStatus, // 🆕 추가
      pendingLocationName:
          pendingLocationName ?? this.pendingLocationName, // 🆕 추가
      deliveryAddressIds: deliveryAddressIds ?? this.deliveryAddressIds, // 🆕 추가
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'roadNameAddress': roadNameAddress,
      'detailedAddress': detailedAddress,
      'locationAddress': locationAddress,
      'postalCode': postalCode,
      'locationTagId': locationTagId, // 🔄 수정
      'locationTagName': locationTagName, // 🔄 추가
      'locationStatus': locationStatus, // 🆕 추가
      'pendingLocationName': pendingLocationName, // 🆕 추가
      'deliveryAddressIds': deliveryAddressIds, // 🆕 추가
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Timestamp를 DateTime으로 안전하게 변환하는 함수
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is DateTime) {
        return value;
      } else if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      } else {
        return DateTime.now();
      }
    }

    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'],
      roadNameAddress: map['roadNameAddress'],
      detailedAddress: map['detailedAddress'],
      locationAddress: map['locationAddress'],
      postalCode: map['postalCode'],
      // 🔄 마이그레이션 고려: 기존 locationTag 데이터 처리
      locationTagId: map['locationTagId'] ??
          (map['locationTag'] != null
              ? _convertLocationTagToId(map['locationTag'])
              : null),
      locationTagName: map['locationTagName'] ?? map['locationTag'], // 🔄 추가
      locationStatus: map['locationStatus'] ??
          (map['locationTag'] != null ? 'active' : 'none'), // 🆕 마이그레이션 처리
      pendingLocationName: map['pendingLocationName'], // 🆕 추가
      deliveryAddressIds: List<String>.from(map['deliveryAddressIds'] ?? []), // 🆕 추가
      createdAt: parseDateTime(map['createdAt'] ?? DateTime.now()),
      updatedAt: parseDateTime(map['updatedAt'] ?? DateTime.now()),
    );
  }

  // Create from Firestore document
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap({
      'uid': doc.id,
      ...data,
    });
  }

  // 🔄 기존 locationTag 문자열을 locationTagId로 변환하는 헬퍼 메서드
  static String _convertLocationTagToId(String locationTag) {
    const locationTagMapping = {
      '강남동': 'gangnam_dong',
      '서초동': 'seocho_dong',
      '송파동': 'songpa_dong',
      '영등포동': 'yeongdeungpo_dong',
      '강서동': 'gangseo_dong',
    };

    return locationTagMapping[locationTag] ??
        locationTag.toLowerCase().replaceAll('동', '_dong');
  }

  @override
  List<Object?> get props => [
        uid,
        name,
        phoneNumber,
        roadNameAddress,
        detailedAddress,
        locationAddress,
        postalCode,
        locationTagId, // 🔄 수정
        locationTagName, // 🔄 추가
        locationStatus, // 🆕 추가
        pendingLocationName, // 🆕 추가
        deliveryAddressIds, // 🆕 추가
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, locationTagId: $locationTagId, locationTagName: $locationTagName, locationStatus: $locationStatus)';
  }
}
