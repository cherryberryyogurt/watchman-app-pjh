import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String id; // Firestore 문서 ID
  final String productId;
  final String productName;
  final int quantity;
  final double productPrice; // 개당 가격
  final String? thumbnailUrl;
  final String productOrderUnit; // 예: "1팩(500g)", "1개"
  final Timestamp addedAt; // 장바구니 추가 시각
  final String productDeliveryType; // 상품의 배송 유형 (예: "픽업", "배송")
  final List<String>? productPickupInfo; // 픽업 정보 (픽업 상품인 경우)
  final DateTime? productStartDate; // 공구 시작일 (상품 정보에서 가져옴)
  final DateTime? productEndDate; // 공구 종료일 (상품 정보에서 가져옴)
  final bool isSelected; // 선택 여부
  final bool isDeleted; // 삭제 여부

  // 계산된 속성
  double get priceSum => productPrice * quantity;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.productPrice,
    this.thumbnailUrl,
    required this.productOrderUnit,
    required this.addedAt,
    required this.productDeliveryType,
    this.productPickupInfo,
    this.productStartDate,
    this.productEndDate,
    this.isSelected = false,
    this.isDeleted = false,
  });

  // Firestore 문서로부터 CartItemModel 객체 생성
  factory CartItemModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return CartItemModel(
      id: documentId,
      productId: data['productId'] as String,
      productName: data['productName'] as String,
      quantity: data['quantity'] as int,
      productPrice: (data['productPrice'] as num).toDouble(),
      thumbnailUrl: data['thumbnailUrl'] as String?,
      productOrderUnit: data['productOrderUnit'] as String,
      addedAt: data['addedAt'] as Timestamp,
      productDeliveryType:
          data['productDeliveryType'] as String? ?? '배송', // 기본값 설정
      productPickupInfo: (data['productPickupInfo'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      productStartDate: (data['productStartDate'] as Timestamp?)?.toDate(),
      productEndDate: (data['productEndDate'] as Timestamp?)?.toDate(),
      isSelected: data['isSelected'] as bool? ?? false, // 기본값은 false
      isDeleted: data['isDeleted'] as bool? ?? false, // 기본값은 false
    );
  }

  // CartItemModel 객체를 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'productPrice': productPrice,
      'thumbnailUrl': thumbnailUrl,
      'productOrderUnit': productOrderUnit,
      'addedAt': addedAt,
      'productDeliveryType': productDeliveryType,
      'productPickupInfo': productPickupInfo,
      'productStartDate': productStartDate != null
          ? Timestamp.fromDate(productStartDate!)
          : null,
      'productEndDate':
          productEndDate != null ? Timestamp.fromDate(productEndDate!) : null,
      'isSelected': isSelected,
      'isDeleted': isDeleted,
    };
  }

  // copyWith 메소드 (상태 업데이트 시 유용)
  CartItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? productPrice,
    String? thumbnailUrl,
    String? productOrderUnit,
    Timestamp? addedAt,
    String? productDeliveryType,
    List<String>? productPickupInfo,
    DateTime? productStartDate,
    DateTime? productEndDate,
    bool? isSelected,
    bool? isDeleted,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      productPrice: productPrice ?? this.productPrice,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      productOrderUnit: productOrderUnit ?? this.productOrderUnit,
      addedAt: addedAt ?? this.addedAt,
      productDeliveryType: productDeliveryType ?? this.productDeliveryType,
      productPickupInfo: productPickupInfo ?? this.productPickupInfo,
      productStartDate: productStartDate ?? this.productStartDate,
      productEndDate: productEndDate ?? this.productEndDate,
      isSelected: isSelected ?? this.isSelected,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'CartItemModel(id: $id, productName: $productName, quantity: $quantity, priceSum: $priceSum, isDeleted: $isDeleted, isSelected: $isSelected)';
  }
}
