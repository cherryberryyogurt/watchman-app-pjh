import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gonggoo_app/features/order/models/order_unit_model.dart';
import 'package:gonggoo_app/features/location/models/pickup_point_model.dart';

class ProductModel {
  final String id;
  final String name; // 상품 이름
  final String description; // 상품 설명
  final List<OrderUnitModel>
      orderUnits; // 주문 단위들 :: [{"price": 2790, "quantity": "1개"}, ...]
  final int stock; // 재고
  // final List<LocationTagInfo> locationTags; // 🔄 위치 태그 리스트 (간소화된 정보)
  final List<String> locationTagNames; // 🆕 위치 태그 이름 배열 (쿼리 최적화용)
  final String productCategory; // 상품 카테고리 :: 농산물, 축산물, 수산물, 기타
  final List<String> thumbnailUrls; // 썸네일 이미지 url 리스트 :: 여러 이미지 지원
  final String deliveryType; // 배송 방식 :: 픽업 / 배송
  // final List<String>? pickupPointIds; // 픽업 포인트 ID 리스트 :: PickupPoint 참조
  // @Deprecated('Use pickupPointIds instead. Will be removed in future versions.')
  // final List<String>? pickupInfo; // 픽업 정보 :: 레거시 필드 (호환성 유지)
  final String? pickupDate; // 픽업 날짜 :: 픽업 배송 타입일 때만 사용
  final String? deliveryDate; // 택배 발송 날짜 :: 택배 배송 타입일 때만 사용
  final DateTime? startDate; // 판매 시작 일자
  final DateTime? endDate; // 판매 종료 일자
  final bool isOnSale; // 판매 여부 :: 수동으로 판매 중단하려고 할 때 사용할 플래그
  final bool isDeleted; // 삭제 여부 :: 소프트 삭제
  final bool isTaxFree; // 세금 면제 여부 :: 세금 면제 상품 여부
  // TODO: 수동 판매 종료 진행시에는 유저들 장바구니 싹다 뒤져서 판매 종료 상품 삭제 처리 필요 (이것도 수동으로 쿼리 보내야 할듯)
  // -> 판매 종료된 상품은 재고가 없다고 주문 단계에서 쳐내야 함. 그니까 주문 단계에서 cart에 담긴 item들을 검사하는 로직을 구성해둬야함.(stock 개수 검사할떄 같이)
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.orderUnits,
    required this.stock,
    // required this.locationTags,
    required this.locationTagNames,
    required this.productCategory,
    required this.thumbnailUrls,
    required this.deliveryType,
    // this.pickupPointIds,
    // @Deprecated('Use pickupPointIds instead') this.pickupInfo,
    this.pickupDate,
    this.deliveryDate,
    this.startDate, // default: now
    this.endDate,
    this.isOnSale = true, // default: true
    this.isDeleted = false, // default: false
    this.isTaxFree = false, // default: false
    required this.createdAt, // default: now
    this.updatedAt,
  });

  // 🔄 기존 코드 호환성을 위한 헬퍼 메서드들
  OrderUnitModel get defaultOrderUnit {
    return orderUnits.isNotEmpty
        ? orderUnits[0]
        : OrderUnitModel(price: 0, quantity: '');
  }

  double get price => defaultOrderUnit.price; // 기본 가격
  String get orderUnit => defaultOrderUnit.quantity; // 기본 수량

  String get defaultLocationTagName {
    return locationTagNames.isNotEmpty ? locationTagNames[0] : '';
  }

  // String get locationTagId => defaultLocationTag.id; // 기본 위치 ID
  // String get locationTagName => defaultLocationTag.name; // 기본 위치 이름

  String? get mainImageUrl =>
      thumbnailUrls.isNotEmpty ? thumbnailUrls[0] : null;

  /// 모든 이미지 URL 리스트 반환
  List<String> getAllImageUrls() {
    return thumbnailUrls;
  }

  /// 이미지가 있는지 확인
  bool get hasImage {
    return thumbnailUrls.isNotEmpty;
  }

  // 🆕 PickupPoint 관련 헬퍼 메서드들

  // /// 픽업 포인트 ID 목록 반환 (우선순위: pickupPointIds > pickupInfo)
  // List<String> get availablePickupPointIds {
  //   // if (pickupPointIds != null && pickupPointIds!.isNotEmpty) {
  //   //   return pickupPointIds!;
  //   // }
  //   // 레거시 호환성: pickupInfo를 pickupPointIds로 처리
  //   // if (pickupInfo != null && pickupInfo!.isNotEmpty) {
  //   //   return pickupInfo!;
  //   // }
  //   return [];
  // }

  // /// 픽업 포인트가 설정되어 있는지 확인
  // bool get hasPickupPoints {
  //   return availablePickupPointIds.isNotEmpty;
  // }

  // /// 특정 픽업 포인트 ID가 사용 가능한지 확인
  // bool isPickupPointAvailable(String pickupPointId) {
  //   return availablePickupPointIds.contains(pickupPointId);
  // }

  /// 픽업 배송 타입인지 확인
  bool get isPickupDelivery {
    return deliveryType == '픽업';
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // // 🔄 locationTags 파싱 (기존 형식과 새로운 형식 모두 지원)
    // List<LocationTagInfo> parsedLocationTags = [];
    List<String> parsedLocationTagNames = [];

    // final locationTagsData = data['locationTags'] as List<dynamic>?;
    // if (locationTagsData != null) {
    //   for (final tagData in locationTagsData) {
    //     if (tagData is Map<String, dynamic>) {
    //       // 새로운 형식: {id: "xxx", name: "yyy"}
    //       final tagInfo = LocationTagInfo.fromMap(tagData);
    //       parsedLocationTags.add(tagInfo);
    //       parsedLocationTagNames.add(tagInfo.name);
    //     } else if (tagData is DocumentSnapshot) {
    //       // 기존 형식: LocationTagModel DocumentSnapshot
    //       final locationTagModel = LocationTagModel.fromFirestore(tagData);
    //       final tagInfo =
    //           LocationTagInfo.fromLocationTagModel(locationTagModel);
    //       parsedLocationTags.add(tagInfo);
    //       parsedLocationTagNames.add(tagInfo.name);
    //     }
    //   }
    // }

    // locationTagNames가 별도로 저장되어 있는 경우 사용
    final storedLocationTagNames = data['locationTagNames'] as List<dynamic>?;
    if (storedLocationTagNames != null && storedLocationTagNames.isNotEmpty) {
      parsedLocationTagNames =
          storedLocationTagNames.map((name) => name.toString()).toList();
    }

    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      // ✅ 새로운 구조 파싱
      orderUnits: (data['orderUnits'] as List<dynamic>?)
              ?.map((unit) =>
                  OrderUnitModel.fromMap(unit as Map<String, dynamic>))
              .toList() ??
          [],
      // locationTags: parsedLocationTags,
      locationTagNames: parsedLocationTagNames,
      thumbnailUrls: (data['thumbnailUrls'] as List<dynamic>?)
              ?.map((url) => url.toString())
              .toList() ??
          [],
      stock: data['stock'] ?? 0,
      productCategory: data['productCategory'] ?? '',
      deliveryType: data['deliveryType'] ?? '픽업',
      // 🆕 pickupPointIds 우선, 없으면 pickupInfo에서 변환
      // pickupPointIds: (data['pickupPointIds'] as List<dynamic>?)
      //         ?.map((id) => id.toString())
      //         .toList() ??
      //     [],
      // (data['pickupInfo'] as List<dynamic>?)
      //     ?.map((info) => info.toString())
      //     .toList(),
      // 🔄 레거시 호환성을 위해 pickupInfo도 유지
      // pickupInfo: (data['pickupInfo'] as List<dynamic>?)
      // ?.map((info) => info.toString())
      // .toList(),
      pickupDate:
          data['pickupDate'] != null ? (data['pickupDate'] as String?) : null,
      deliveryDate: data['deliveryDate'] != null
          ? (data['deliveryDate'] as String?)
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'orderUnits': orderUnits.map((unit) => unit.toMap()).toList(),
      // 'locationTags': locationTags.map((tag) => tag.toMap()).toList(),
      'locationTagNames': locationTagNames,
      'thumbnailUrls': thumbnailUrls,
      'stock': stock,
      'productCategory': productCategory,
      'deliveryType': deliveryType,
      // 'pickupPointIds': pickupPointIds,
      // 'pickupInfo': pickupInfo,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isOnSale': isOnSale,
      'isDeleted': isDeleted,
      'isTaxFree': isTaxFree,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // 🆕 copyWith 메소드 추가
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    List<OrderUnitModel>? orderUnits,
    int? stock,
    List<LocationTagInfo>? locationTags,
    List<String>? locationTagNames,
    String? productCategory,
    String? thumbnailUrl,
    List<String>? thumbnailUrls,
    String? deliveryType,
    // List<String>? pickupPointIds,
    // List<String>? pickupInfo,
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
      orderUnits: orderUnits ?? this.orderUnits,
      stock: stock ?? this.stock,
      // locationTags: locationTags ?? this.locationTags,
      locationTagNames: locationTagNames ?? this.locationTagNames,
      productCategory: productCategory ?? this.productCategory,
      thumbnailUrls: thumbnailUrls ?? this.thumbnailUrls,
      deliveryType: deliveryType ?? this.deliveryType,
      // pickupPointIds: pickupPointIds ?? this.pickupPointIds,
      // pickupInfo: pickupInfo ?? this.pickupInfo,
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
    return 'ProductModel(id: $id, name: $name, locationTagNames: $locationTagNames, orderUnits: $orderUnits, stock: $stock)';
  }
}

/// 상품에서 사용하는 간소화된 위치 태그 정보
class LocationTagInfo {
  final String id;
  final String name;

  const LocationTagInfo({
    required this.id,
    required this.name,
  });

  /// Map에서 LocationTagInfo 생성
  factory LocationTagInfo.fromMap(Map<String, dynamic> map) {
    return LocationTagInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  // /// LocationTagModel에서 LocationTagInfo 생성
  // factory LocationTagInfo.fromLocationTagModel(LocationTagModel model) {
  //   return LocationTagInfo(
  //     id: model.id,
  //     name: model.name,
  //   );
  // }

  /// Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() => 'LocationTagInfo(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationTagInfo && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
