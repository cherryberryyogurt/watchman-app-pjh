import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name; // 상품 이름
  final String description; // 상품 설명
  final double price; // 가격 :: 1팩(200g) 당 가격
  final String orderUnit; // 주문 단위 :: 1팩(200g), 1박스(10kg), 1판(30구) 등 text로 관리
  final int stock; // 재고
  final String locationTag; // 위치 태그 :: 이 태그와 사용자 위치 태그를 비교하여 상품 노출('동' 기준)
  final String productCategory; // 상품 카테고리 :: 농산물, 축산물, 수산물, 기타
  final String? thumbnailUrl; // 썸네일 이미지 url :: firestore 저장
  final String deliveryType; // 배송 방식 :: 픽업 / 배송
  final List<String>? pickupInfo; // 픽업 정보 :: 픽업 장소 - 픽업 날짜 (1:1)
  final DateTime? startDate; // 판매 시작 일자
  final DateTime? endDate; // 판매 종료 일자
  final bool isOnSale; // 판매 여부 :: 수동으로 판매 중단하려고 할 때 사용할 플래그
  // TODO: 수동 판매 종료 진행시에는 유저들 장바구니 싹다 뒤져서 판매 종료 상품 삭제 처리 필요 (이것도 수동으로 쿼리 보내야 할듯)
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.orderUnit,
    required this.stock,
    required this.locationTag,
    required this.productCategory,
    this.thumbnailUrl,
    required this.deliveryType,
    this.pickupInfo,
    this.startDate, // default: now
    this.endDate,
    this.isOnSale = true, // default: true
    required this.createdAt, // default: now
    this.updatedAt,
  });

  // From Firebase doc
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      orderUnit: data['orderUnit'] ?? '',
      stock: data['stock'] ?? 0,
      locationTag: data['locationTag'] ?? '',
      productCategory: data['productCategory'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      deliveryType: data['deliveryType'] ?? '픽업',
      pickupInfo: data['pickupInfo'] != null
          ? List<String>.from(data['pickupInfo'])
          : null,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      isOnSale: data['isOnSale'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // To Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'orderUnit': orderUnit,
      'stock': stock,
      'locationTag': locationTag,
      'productCategory': productCategory,
      'thumbnailUrl': thumbnailUrl,
      'deliveryType': deliveryType,
      'pickupInfo': pickupInfo,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isOnSale': isOnSale,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
