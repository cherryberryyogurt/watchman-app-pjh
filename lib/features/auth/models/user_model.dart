import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? roadNameAddress;
  final String? locationAddress;
  final String? locationTag;
  final bool isPhoneVerified;
  final bool isAddressVerified;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.roadNameAddress,
    this.locationAddress,
    this.locationTag,
    this.isPhoneVerified = false,
    this.isAddressVerified = false,
    this.isEmailVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Empty user
  static UserModel get empty => UserModel(
        uid: '',
        email: '',
        name: '',
        phoneNumber: null,
        roadNameAddress: null,
        locationAddress: null,
        locationTag: null,
        isPhoneVerified: false,
        isAddressVerified: false,
        isEmailVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // Check if user is empty
  bool get isEmpty => this == UserModel.empty;
  bool get isNotEmpty => this != UserModel.empty;

  // Copy with method
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phoneNumber,
    String? roadNameAddress,
    String? locationAddress,
    String? locationTag,
    bool? isPhoneVerified,
    bool? isAddressVerified,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roadNameAddress: roadNameAddress ?? this.roadNameAddress,
      locationAddress: locationAddress ?? this.locationAddress,
      locationTag: locationTag ?? this.locationTag,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isAddressVerified: isAddressVerified ?? this.isAddressVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'roadNameAddress': roadNameAddress,
      'locationAddress': locationAddress,
      'locationTag': locationTag,
      'isPhoneVerified': isPhoneVerified,
      'isAddressVerified': isAddressVerified,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Timestamp를 DateTime으로 안전하게 변환하는 함수
    DateTime _parseDateTime(dynamic value) {
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
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'],
      roadNameAddress: map['roadNameAddress'],
      locationAddress: map['locationAddress'],
      locationTag: map['locationTag'],
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      isAddressVerified: map['isAddressVerified'] ?? false,
      isEmailVerified: map['isEmailVerified'] ?? false,
      createdAt: _parseDateTime(map['createdAt'] ?? DateTime.now()),
      updatedAt: _parseDateTime(map['updatedAt'] ?? DateTime.now()),
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
        email,
        name,
        phoneNumber,
        roadNameAddress,
        locationAddress,
        locationTag,
        isPhoneVerified,
        isAddressVerified,
        isEmailVerified,
        createdAt,
        updatedAt,
      ];
} 