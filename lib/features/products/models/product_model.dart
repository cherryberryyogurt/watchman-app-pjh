import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name; // 상품 이름
  final String description; // 상품 설명
  final double price; // 가격 :: 1팩(200g) 당 가격
  final String orderUnit; // 주문 단위 :: 1팩(200g), 1박스(10kg), 1판(30구) 등 text로 관리
  final int stock; // 재고
  final String locationTagId; // 위치 태그 ID :: 참조용
  final String locationTagName; // 위치 태그 이름 :: 성능을 위한 중복 저장
  final String productCategory; // 상품 카테고리 :: 농산물, 축산물, 수산물, 기타
  final String? thumbnailUrl; // 썸네일 이미지 url :: firestore 저장
  final String deliveryType; // 배송 방식 :: 픽업 / 배송
  final List<String>? pickupInfo; // 픽업 정보 :: 픽업 장소 - 픽업 날짜 (1:1)
  final DateTime? startDate; // 판매 시작 일자
  final DateTime? endDate; // 판매 종료 일자
  final bool isOnSale; // 판매 여부 :: 수동으로 판매 중단하려고 할 때 사용할 플래그
  final bool isDeleted; // 삭제 여부 :: 소프트 삭제
  final bool isTaxFree; // 세금 면제 여부 :: 세금 면제 상품 여부
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
    required this.locationTagId,
    required this.locationTagName,
    required this.productCategory,
    this.thumbnailUrl,
    required this.deliveryType,
    this.pickupInfo,
    this.startDate, // default: now
    this.endDate,
    this.isOnSale = true, // default: true
    this.isDeleted = false, // default: false
    this.isTaxFree = false, // default: false
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
      locationTagId: data['locationTagId'] ?? data['locationTag'] ?? '',
      locationTagName: data['locationTagName'] ?? data['locationTag'] ?? '',
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
      isDeleted: data['isDeleted'] ?? false,
      isTaxFree: data['isTaxFree'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
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
      'locationTagId': locationTagId,
      'locationTagName': locationTagName,
      'productCategory': productCategory,
      'thumbnailUrl': thumbnailUrl,
      'deliveryType': deliveryType,
      'pickupInfo': pickupInfo,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isOnSale': isOnSale,
      'isDeleted': isDeleted,
      'isTaxFree': isTaxFree,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // 🆕 copyWith 메소드 추가
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? orderUnit,
    int? stock,
    String? locationTagId,
    String? locationTagName,
    String? productCategory,
    String? thumbnailUrl,
    String? deliveryType,
    List<String>? pickupInfo,
    DateTime? startDate,
    DateTime? endDate,
    bool? isOnSale,
    bool? isDeleted,
    bool? isTaxFree,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      orderUnit: orderUnit ?? this.orderUnit,
      stock: stock ?? this.stock,
      locationTagId: locationTagId ?? this.locationTagId,
      locationTagName: locationTagName ?? this.locationTagName,
      productCategory: productCategory ?? this.productCategory,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      deliveryType: deliveryType ?? this.deliveryType,
      pickupInfo: pickupInfo ?? this.pickupInfo,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isOnSale: isOnSale ?? this.isOnSale,
      isDeleted: isDeleted ?? this.isDeleted,
      isTaxFree: isTaxFree ?? this.isTaxFree,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 🆕 공구 상태 확인 헬퍼 메서드들
  bool get isActiveProduct {
    return isOnSale && !isDeleted && stock > 0;
  }

  bool get isSaleActive {
    final now = DateTime.now();

    // 시작일이 없으면 언제나 판매 가능
    if (startDate == null) return isActiveProduct;

    // 시작일이 있으면 시작일 이후인지 확인
    if (now.isBefore(startDate!)) return false;

    // 종료일이 있으면 종료일 전인지 확인
    if (endDate != null && now.isAfter(endDate!)) return false;

    return isActiveProduct;
  }

  bool get isUpcoming {
    if (startDate == null) return false;
    final now = DateTime.now();
    return now.isBefore(startDate!) && isActiveProduct;
  }

  bool get isExpired {
    if (endDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(endDate!) || !isActiveProduct;
  }

  /// 공구 상태 문자열 반환
  String get saleStatusText {
    if (isDeleted) return '삭제됨';
    if (!isOnSale) return '판매중지';
    if (stock <= 0) return '품절';
    if (isUpcoming) return '판매예정';
    if (isExpired) return '판매종료';
    if (isSaleActive) return '판매중';
    return '상태확인필요';
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, locationTagId: $locationTagId, locationTagName: $locationTagName, price: $price, stock: $stock)';
  }
}
