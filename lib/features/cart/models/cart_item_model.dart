import 'package:cloud_firestore/cloud_firestore.dart';
import '../../location/models/pickup_point_model.dart';
import '../../location/repositories/location_tag_repository.dart';

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

  // 🔄 픽업 정보 개선: 단순 텍스트 리스트에서 ID 참조로 변경
  final String? locationTagId; // 픽업 지역 태그 ID
  final String? pickupInfoId; // 픽업 정보 ID (locationTagId의 subcollection)

  final DateTime? productStartDate; // 공구 시작일 (상품 정보에서 가져옴)
  final DateTime? productEndDate; // 공구 종료일 (상품 정보에서 가져옴)
  final bool isSelected; // 선택 여부
  final bool isDeleted; // 삭제 여부
  final bool isTaxFree; // 면세 여부 (상품 정보에서 가져옴)

  // 계산된 속성
  double get priceSum => productPrice * quantity;

  // 픽업 상품 여부 확인
  bool get isPickupItem => productDeliveryType == '픽업';

  // 픽업 정보 존재 여부 확인
  bool get hasPickupInfo =>
      isPickupItem && locationTagId != null && pickupInfoId != null;

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
    this.locationTagId,
    this.pickupInfoId,
    this.productStartDate,
    this.productEndDate,
    this.isSelected = false,
    this.isDeleted = false,
    this.isTaxFree = false,
  });

  // 🔄 픽업 정보 조회 메서드
  Future<PickupPointModel?> getPickupInfo(
      LocationTagRepository repository) async {
    if (!hasPickupInfo) return null;

    try {
      return await repository.getPickupInfoById(locationTagId!, pickupInfoId!);
    } catch (e) {
      print('픽업 정보 조회 실패: $e');
      return null;
    }
  }

  // 🔄 해당 지역의 모든 픽업 정보 조회 메서드
  Future<List<PickupPointModel>> getAvailablePickupInfos(
      LocationTagRepository repository) async {
    if (!isPickupItem || locationTagId == null) return [];

    try {
      return await repository.getPickupInfoByLocationTag(locationTagId!);
    } catch (e) {
      print('지역 픽업 정보 조회 실패: $e');
      return [];
    }
  }

  // 🔧 JSON 직렬화를 위한 메서드 (오프라인 저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'productPrice': productPrice,
      'thumbnailUrl': thumbnailUrl,
      'productOrderUnit': productOrderUnit,
      'addedAt':
          addedAt.toDate().toIso8601String(), // Timestamp를 ISO 8601 문자열로 변환
      'productDeliveryType': productDeliveryType,
      'locationTagId': locationTagId,
      'pickupInfoId': pickupInfoId,
      'productStartDate':
          productStartDate?.toIso8601String(), // DateTime을 ISO 8601 문자열로 변환
      'productEndDate':
          productEndDate?.toIso8601String(), // DateTime을 ISO 8601 문자열로 변환
      'isSelected': isSelected,
      'isDeleted': isDeleted,
      'isTaxFree': isTaxFree,
    };
  }

  // Firestore 문서로부터 CartItemModel 객체 생성
  factory CartItemModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CartItemModel(
      id: id,
      productId: data['productId'] as String,
      productName: data['productName'] as String,
      quantity: data['quantity'] as int,
      productPrice: (data['productPrice'] as num).toDouble(),
      thumbnailUrl: data['thumbnailUrl'] as String?,
      productOrderUnit: data['productOrderUnit'] as String,
      addedAt: data['addedAt'] as Timestamp,
      productDeliveryType: data['productDeliveryType'] as String? ?? '배송',
      locationTagId: data['locationTagId'] as String?,
      pickupInfoId: data['pickupInfoId'] as String?,
      productStartDate: data['productStartDate'] != null
          ? (data['productStartDate'] as Timestamp).toDate()
          : null,
      productEndDate: data['productEndDate'] != null
          ? (data['productEndDate'] as Timestamp).toDate()
          : null,
      isSelected: data['isSelected'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
      isTaxFree: data['isTaxFree'] as bool? ?? false,
    );
  }

  // 🔧 JSON으로부터 CartItemModel 객체 생성 (오프라인 로드용)
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      productPrice: (json['productPrice'] as num).toDouble(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      productOrderUnit: json['productOrderUnit'] as String,
      addedAt: Timestamp.fromDate(DateTime.parse(
          json['addedAt'] as String)), // ISO 8601 문자열을 Timestamp로 변환
      productDeliveryType: json['productDeliveryType'] as String? ?? '배송',
      locationTagId: json['locationTagId'] as String?,
      pickupInfoId: json['pickupInfoId'] as String?,
      productStartDate: json['productStartDate'] != null
          ? DateTime.parse(json['productStartDate'] as String)
          : null, // ISO 8601 문자열을 DateTime으로 변환
      productEndDate: json['productEndDate'] != null
          ? DateTime.parse(json['productEndDate'] as String)
          : null, // ISO 8601 문자열을 DateTime으로 변환
      isSelected: json['isSelected'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      isTaxFree: json['isTaxFree'] as bool? ?? false,
    );
  }

  // Firestore 문서로부터 CartItemModel 객체 생성
  // factory CartItemModel.fromFirestore(
  //     Map<String, dynamic> data, String documentId) {
  //   return CartItemModel(
  //     id: documentId,
  //     productId: data['productId'] as String,
  //     productName: data['productName'] as String,
  //     quantity: data['quantity'] as int,
  //     productPrice: (data['productPrice'] as num).toDouble(),
  //     thumbnailUrl: data['thumbnailUrl'] as String?,
  //     productOrderUnit: data['productOrderUnit'] as String,
  //     addedAt: data['addedAt'] as Timestamp,
  //     productDeliveryType:
  //         data['productDeliveryType'] as String? ?? '배송', // 기본값 설정
  //     locationTagId: data['locationTagId'] as String?,
  //     pickupInfoId: data['pickupInfoId'] as String?,
  //     productStartDate: (data['productStartDate'] as Timestamp?)?.toDate(),
  //     productEndDate: (data['productEndDate'] as Timestamp?)?.toDate(),
  //     isSelected: data['isSelected'] as bool? ?? false, // 기본값은 false
  //     isDeleted: data['isDeleted'] as bool? ?? false, // 기본값은 false
  //   );
  // }

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
      'locationTagId': locationTagId,
      'pickupInfoId': pickupInfoId,
      'productStartDate': productStartDate != null
          ? Timestamp.fromDate(productStartDate!)
          : null,
      'productEndDate':
          productEndDate != null ? Timestamp.fromDate(productEndDate!) : null,
      'isSelected': isSelected,
      'isDeleted': isDeleted,
      'isTaxFree': isTaxFree,
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
    String? locationTagId,
    String? pickupInfoId,
    DateTime? productStartDate,
    DateTime? productEndDate,
    bool? isSelected,
    bool? isDeleted,
    bool? isTaxFree,
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
      locationTagId: locationTagId ?? this.locationTagId,
      pickupInfoId: pickupInfoId ?? this.pickupInfoId,
      productStartDate: productStartDate ?? this.productStartDate,
      productEndDate: productEndDate ?? this.productEndDate,
      isSelected: isSelected ?? this.isSelected,
      isDeleted: isDeleted ?? this.isDeleted,
      isTaxFree: isTaxFree ?? this.isTaxFree,
    );
  }

  @override
  String toString() {
    return 'CartItemModel(id: $id, productName: $productName, quantity: $quantity, priceSum: $priceSum, isDeleted: $isDeleted, isSelected: $isSelected, pickupInfo: ${hasPickupInfo ? 'locationTagId=$locationTagId, pickupInfoId=$pickupInfoId' : 'none'})';
  }
}
