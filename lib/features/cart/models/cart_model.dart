import 'package:cloud_firestore/cloud_firestore.dart';

class CartModel {
  // 장바구니 고유 정보
  final String id;
  final String userId;
  final int quantity; // 장바구니 상품 수량
  final double priceSum; // 장바구니 상품 총 가격
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSelected; // 결제를 위한 선택 여부
  final bool isDeleted; // 삭제 여부 (소프트 딜리트)
  
  // 장바구니 상품 정보
  final String productId;
  final String productName; // 상품 이름
  final double productPrice; // 상품 가격
  final String productOrderUnit; // 상품 주문 단위
  final String? thumbnailUrl; // 상품 썸네일 이미지 url
  final String productDeliveryType; // 상품 배송 방식
  final List<String>? productPickupInfo; // 상품 픽업 정보
  final DateTime? productStartDate; // 상품 판매 시작 일자
  final DateTime? productEndDate; // 상품 판매 종료 일자
  
  CartModel({
    required this.id,
    required this.userId,
    required this.quantity,
    required this.priceSum,
    required this.createdAt,
    this.updatedAt,
    this.isSelected = false,
    this.isDeleted = false,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productOrderUnit,
    this.thumbnailUrl,
    required this.productDeliveryType,
    this.productPickupInfo,
    this.productStartDate,
    this.productEndDate,
  });
  
  // From Firebase doc
  factory CartModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CartModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      quantity: data['quantity'] ?? 0,
      priceSum: (data['priceSum'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      isSelected: data['isSelected'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productPrice: (data['productPrice'] ?? 0).toDouble(),
      productOrderUnit: data['productOrderUnit'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      productDeliveryType: data['productDeliveryType'] ?? '픽업',
      productPickupInfo: data['productPickupInfo'] != null 
          ? List<String>.from(data['productPickupInfo']) 
          : null,
      productStartDate: data['productStartDate'] != null 
          ? (data['productStartDate'] as Timestamp).toDate() 
          : null,
      productEndDate: data['productEndDate'] != null 
          ? (data['productEndDate'] as Timestamp).toDate() 
          : null,
    );
  }

  // To Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'quantity': quantity,
      'priceSum': priceSum,
      'isSelected': isSelected,
      'isDeleted': isDeleted,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productOrderUnit': productOrderUnit,
      'thumbnailUrl': thumbnailUrl,
      'productDeliveryType': productDeliveryType,
      'productPickupInfo': productPickupInfo,
      'productStartDate': productStartDate != null ? Timestamp.fromDate(productStartDate!) : null,
      'productEndDate': productEndDate != null ? Timestamp.fromDate(productEndDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
  
  // CopyWith method for creating a new instance with updated values
  CartModel copyWith({
    String? id,
    String? userId,
    int? quantity,
    double? priceSum,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSelected,
    bool? isDeleted,
    String? productId,
    String? productName,
    double? productPrice,
    String? productOrderUnit,
    String? thumbnailUrl,
    String? productDeliveryType,
    List<String>? productPickupInfo,
    DateTime? productStartDate,
    DateTime? productEndDate,
  }) {
    return CartModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      quantity: quantity ?? this.quantity,
      priceSum: priceSum ?? this.priceSum,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSelected: isSelected ?? this.isSelected,
      isDeleted: isDeleted ?? this.isDeleted,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productOrderUnit: productOrderUnit ?? this.productOrderUnit,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      productDeliveryType: productDeliveryType ?? this.productDeliveryType,
      productPickupInfo: productPickupInfo ?? this.productPickupInfo,
      productStartDate: productStartDate ?? this.productStartDate,
      productEndDate: productEndDate ?? this.productEndDate,
    );
  }
} 