import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? address;
  final String? locationTag;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.address,
    this.locationTag,
    this.isPhoneVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Empty user
  static UserModel get empty => UserModel(
        uid: '',
        email: '',
        name: '',
        isPhoneVerified: false,
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
    String? address,
    String? locationTag,
    bool? isPhoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      locationTag: locationTag ?? this.locationTag,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
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
      'address': address,
      'locationTag': locationTag,
      'isPhoneVerified': isPhoneVerified,
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
      address: map['address'],
      locationTag: map['locationTag'],
      isPhoneVerified: map['isPhoneVerified'] ?? false,
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
        address,
        locationTag,
        isPhoneVerified,
        createdAt,
        updatedAt,
      ];
} 