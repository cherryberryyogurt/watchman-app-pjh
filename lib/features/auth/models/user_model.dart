import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Equatable {
  final String uid;
  final String name; // 이름
  final String? phoneNumber; // 전화번호
  final String? roadNameAddress; // 도로명 주소
  final String? locationAddress; // 지번 주소
  final String? locationTag; // 위치 태그 (예: OO동)
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.name,
    this.phoneNumber,
    this.roadNameAddress,
    this.locationAddress,
    this.locationTag,
    required this.createdAt,
    required this.updatedAt,
  });

  // Empty user
  static UserModel get empty => UserModel(
        uid: '',
        name: '',
        phoneNumber: null,
        roadNameAddress: null,
        locationAddress: null,
        locationTag: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // Check if user is empty
  bool get isEmpty => this == UserModel.empty;
  bool get isNotEmpty => this != UserModel.empty;

  // Copy with method
  UserModel copyWith({
    String? uid,
    String? name,
    String? phoneNumber,
    String? roadNameAddress,
    String? locationAddress,
    String? locationTag,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roadNameAddress: roadNameAddress ?? this.roadNameAddress,
      locationAddress: locationAddress ?? this.locationAddress,
      locationTag: locationTag ?? this.locationTag,
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
      'locationAddress': locationAddress,
      'locationTag': locationTag,
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
      locationAddress: map['locationAddress'],
      locationTag: map['locationTag'],
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

  @override
  List<Object?> get props => [
        uid,
        name,
        phoneNumber,
        roadNameAddress,
        locationAddress,
        locationTag,
        createdAt,
        updatedAt,
      ];
}
