import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryAddressModel extends Equatable {
  final String id;
  final String recipientName;
  final String recipientContact;
  final String postalCode;
  final String recipientAddress;
  final String recipientAddressDetail;
  final String? buildingName;
  final String? requestMemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeliveryAddressModel({
    required this.id,
    required this.recipientName,
    required this.recipientContact,
    required this.postalCode,
    required this.recipientAddress,
    required this.recipientAddressDetail,
    this.buildingName,
    this.requestMemo,
    required this.createdAt,
    required this.updatedAt,
  });

  // Empty delivery address
  static DeliveryAddressModel get empty => DeliveryAddressModel(
        id: '',
        recipientName: '',
        recipientContact: '',
        postalCode: '',
        recipientAddress: '',
        recipientAddressDetail: '',
        buildingName: null,
        requestMemo: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // Check if delivery address is empty
  bool get isEmpty => this == DeliveryAddressModel.empty;
  bool get isNotEmpty => this != DeliveryAddressModel.empty;

  // Copy with method
  DeliveryAddressModel copyWith({
    String? id,
    String? recipientName,
    String? recipientContact,
    String? postalCode,
    String? recipientAddress,
    String? recipientAddressDetail,
    String? buildingName,
    String? requestMemo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryAddressModel(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      recipientContact: recipientContact ?? this.recipientContact,
      postalCode: postalCode ?? this.postalCode,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      recipientAddressDetail: recipientAddressDetail ?? this.recipientAddressDetail,
      buildingName: buildingName ?? this.buildingName,
      requestMemo: requestMemo ?? this.requestMemo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipientName': recipientName,
      'recipientContact': recipientContact,
      'postalCode': postalCode,
      'recipientAddress': recipientAddress,
      'recipientAddressDetail': recipientAddressDetail,
      'buildingName': buildingName,
      'requestMemo': requestMemo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create from Map
  factory DeliveryAddressModel.fromMap(Map<String, dynamic> map) {
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

    return DeliveryAddressModel(
      id: map['id'] ?? '',
      recipientName: map['recipientName'] ?? '',
      recipientContact: map['recipientContact'] ?? '',
      postalCode: map['postalCode'] ?? '',
      recipientAddress: map['recipientAddress'] ?? '',
      recipientAddressDetail: map['recipientAddressDetail'] ?? '',
      buildingName: map['buildingName'],
      requestMemo: map['requestMemo'],
      createdAt: parseDateTime(map['createdAt'] ?? DateTime.now()),
      updatedAt: parseDateTime(map['updatedAt'] ?? DateTime.now()),
    );
  }

  // Create from Firestore document
  factory DeliveryAddressModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryAddressModel.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  @override
  List<Object?> get props => [
        id,
        recipientName,
        recipientContact,
        postalCode,
        recipientAddress,
        recipientAddressDetail,
        buildingName,
        requestMemo,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'DeliveryAddressModel(id: $id, recipientName: $recipientName, recipientAddress: $recipientAddress)';
  }
}