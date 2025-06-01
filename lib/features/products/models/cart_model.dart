// ------------------------------------------------------------
// 삭제 예정
// ------------------------------------------------------------

// import 'package:cloud_firestore/cloud_firestore.dart';

// class CartModel {
//   // 장바구니 고유 정보
//   final String id;
//   final String userId;
//   final int quantity; // 장바구니 상품 수량
//   final double priceSum; // 장바구니 상품 총 가격
//   final DateTime createdAt;
//   final DateTime? updatedAt;
//   // 장바구니 상품 정보
//   final String productId;
//   final String productName; // 상품 이름
//   final double productPrice; // 상품 가격
//   final String productOrderUnit; // 상품 주문 단위
//   final String? thumbnailUrl; // 상품 썸네일 이미지 url
//   final String productDeliveryType; // 상품 배송 방식
//   final String? productPickupInfo; // 상품 픽업 정보
//   final DateTime? productStartDate; // 상품 판매 시작 일자
//   final DateTime? productEndDate; // 상품 판매 종료 일자
//   // TODO: 판매 종료 일자 이후에는 장바구니에서 삭제 처리 필요

//   CartModel({
//     required this.id,
//     required this.userId,
//     required this.quantity,
//     required this.priceSum,
//     required this.createdAt,
//     this.updatedAt,
//     required this.productId,
//     required this.productName,
//     required this.productPrice,
//     required this.productOrderUnit,
//     this.thumbnailUrl,
//     required this.productDeliveryType,
//     this.productPickupInfo,
//     this.productStartDate,
//     this.productEndDate,
//   });

//   // From Firebase doc
//   factory CartModel.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;

//     return CartModel(
//       id: doc.id,
//       userId: data['userId'] ?? '',
//       quantity: data['quantity'] ?? 0,
//       priceSum: (data['priceSum'] ?? 0).toDouble(),
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//       updatedAt: data['updatedAt'] != null
//           ? (data['updatedAt'] as Timestamp).toDate()
//           : null,
//       productId: data['productId'] ?? '',
//       // 누락된 필수 파라미터들 추가
//       productName: data['productName'] ?? '',
//       productPrice: (data['productPrice'] ?? 0).toDouble(),
//       productOrderUnit: data['productOrderUnit'] ?? '',
//       // 필드명 일관성 확보 (toMap과 동일하게)
//       thumbnailUrl: data['productThumbnailUrl'],
//       productDeliveryType: data['productDeliveryType'] ?? '픽업',
//       productPickupInfo: data['productPickupInfo'], // String?로 처리
//       productStartDate: data['productStartDate'] != null
//           ? (data['productStartDate'] as Timestamp).toDate()
//           : null,
//       productEndDate: data['productEndDate'] != null
//           ? (data['productEndDate'] as Timestamp).toDate()
//           : null,
//     );
//   }

//   // To Map for Firebase
//   Map<String, dynamic> toMap() {
//     return {
//       'userId': userId,
//       'quantity': quantity,
//       'priceSum': priceSum,
//       'productId': productId,
//       'productName': productName,
//       'productPrice': productPrice,
//       'productOrderUnit': productOrderUnit,
//       'productThumbnailUrl': thumbnailUrl,
//       'productDeliveryType': productDeliveryType,
//       'productPickupInfo': productPickupInfo,
//       'productStartDate': productStartDate != null
//           ? Timestamp.fromDate(productStartDate!)
//           : null,
//       'productEndDate':
//           productEndDate != null ? Timestamp.fromDate(productEndDate!) : null,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
//     };
//   }
// }
