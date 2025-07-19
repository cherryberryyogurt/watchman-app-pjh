import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../exceptions/product_exceptions.dart';
// import '../../location/repositories/location_tag_repository.dart';
// import '../../../core/exceptions/location_exceptions.dart';

// ProductQueryResult 클래스 정의
class ProductQueryResult {
  final List<ProductModel> products;
  final DocumentSnapshot? lastDocument;

  ProductQueryResult({required this.products, this.lastDocument});
}

class ProductRepository {
  final FirebaseFirestore _firestore;
  // 🆕 LocationTag 의존성 주입
  // final LocationTagRepository _locationTagRepository;

  ProductRepository({
    FirebaseFirestore? firestore,
    // LocationTagRepository? locationTagRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  // _locationTagRepository =
  //     locationTagRepository ?? LocationTagRepository();

  // Get collection reference
  CollectionReference get _productsCollection =>
      _firestore.collection('products');

  // // 🌍 위치 기반 상품 조회 (핵심 기능) - LocationTag ID로
  // Future<List<ProductModel>> getProductsByLocationTagId(
  //     String locationTagId) async {
  //   try {
  //     final QuerySnapshot snapshot = await _productsCollection
  //         .where('locationTagId', isEqualTo: locationTagId)
  //         .where('isOnSale', isEqualTo: true)
  //         .where('isDeleted', isEqualTo: false)
  //         .orderBy('createdAt', descending: true)
  //         .get();

  //     final products = snapshot.docs
  //         .map((doc) => ProductModel.fromFirestore(doc))
  //         .where((product) {
  //       // Apply display rules
  //       if (!product.isOnSale || product.isDeleted) {
  //         return false;
  //       }
  //       if (product.endDate != null &&
  //           product.endDate!.isBefore(DateTime.now())) {
  //         return false;
  //       }
  //       return true;
  //     }).toList();

  //     return products;
  //   } catch (e) {
  //     throw ProductLocationMismatchException('해당 지역의 상품을 불러오는데 실패했습니다: $e');
  //   }
  // }

  // // 🌍 위치 기반 상품 조회 (핵심 기능) - LocationTag Name으로
  // Future<List<ProductModel>> getProductsByLocationTagName(
  //     String locationTagName) async {
  //   try {
  //     final QuerySnapshot snapshot = await _productsCollection
  //         .where('locationTagNames', arrayContains: locationTagName)
  //         .where('isOnSale', isEqualTo: true)
  //         .where('isDeleted', isEqualTo: false)
  //         .orderBy('createdAt', descending: true)
  //         .get();

  //     final products = snapshot.docs
  //         .map((doc) => ProductModel.fromFirestore(doc))
  //         .where((product) {
  //       // Apply display rules
  //       if (!product.isOnSale || product.isDeleted) {
  //         return false;
  //       }
  //       if (product.endDate != null &&
  //           product.endDate!.isBefore(DateTime.now())) {
  //         return false;
  //       }
  //       return true;
  //     }).toList();

  //     return products;
  //   } catch (e) {
  //     throw ProductLocationMismatchException('해당 지역의 상품을 불러오는데 실패했습니다: $e');
  //   }
  // }

  // // 🌍 위치 기반 상품 조회 with 페이지네이션 - LocationTag ID로
  // Future<ProductQueryResult> getProductsByLocationTagIdWithPagination(
  //     String locationTagId, DocumentSnapshot? lastDocument, int limit) async {
  //   try {
  //     Query query = _productsCollection
  //         .where('locationTagId', isEqualTo: locationTagId)
  //         .where('isOnSale', isEqualTo: true)
  //         .where('isDeleted', isEqualTo: false)
  //         .orderBy('createdAt', descending: true)
  //         .limit(limit);

  //     if (lastDocument != null) {
  //       query = query.startAfterDocument(lastDocument);
  //     }

  //     final QuerySnapshot snapshot = await query.get();

  //     final products = snapshot.docs
  //         .map((doc) => ProductModel.fromFirestore(doc))
  //         .where((product) {
  //       // Apply display rules
  //       if (!product.isOnSale || product.isDeleted) {
  //         return false;
  //       }
  //       if (product.endDate != null &&
  //           product.endDate!.isBefore(DateTime.now())) {
  //         return false;
  //       }
  //       return true;
  //     }).toList();

  //     return ProductQueryResult(
  //       products: products,
  //       lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
  //     );
  //   } catch (e) {
  //     throw ProductLocationMismatchException('해당 지역의 상품을 불러오는데 실패했습니다: $e');
  //   }
  // }

  // // 🌍 위치 기반 상품 조회 with 페이지네이션 - LocationTag Name으로
  // Future<ProductQueryResult> getProductsByLocationTagNameWithPagination(
  //     String locationTagName, DocumentSnapshot? lastDocument, int limit) async {
  //   try {
  //     Query query = _productsCollection
  //         .where('locationTagNames', arrayContains: locationTagName)
  //         .where('isOnSale', isEqualTo: true)
  //         .where('isDeleted', isEqualTo: false)
  //         .orderBy('createdAt', descending: true)
  //         .limit(limit);

  //     if (lastDocument != null) {
  //       query = query.startAfterDocument(lastDocument);
  //     }

  //     final QuerySnapshot snapshot = await query.get();

  //     final products = snapshot.docs
  //         .map((doc) => ProductModel.fromFirestore(doc))
  //         .where((product) {
  //       // Apply display rules
  //       if (!product.isOnSale || product.isDeleted) {
  //         return false;
  //       }
  //       if (product.endDate != null &&
  //           product.endDate!.isBefore(DateTime.now())) {
  //         return false;
  //       }
  //       return true;
  //     }).toList();

  //     return ProductQueryResult(
  //       products: products,
  //       lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
  //     );
  //   } catch (e) {
  //     throw ProductLocationMismatchException('해당 지역의 상품을 불러오는데 실패했습니다: $e');
  //   }
  // }

  // // 🔍 검색 (지역 필터링 포함)
  // Future<List<ProductModel>> searchProductsInLocation(
  //     String query, String locationTagId) async {
  //   try {
  //     // Firestore에서는 full-text search가 제한적이므로 name 필드로 검색
  //     final QuerySnapshot snapshot = await _productsCollection
  //         .where('locationTagId', isEqualTo: locationTagId)
  //         .where('isOnSale', isEqualTo: true)
  //         .where('isDeleted', isEqualTo: false)
  //         .orderBy('name')
  //         .startAt([query]).endAt([query + '\uf8ff']).get();

  //     final products = snapshot.docs
  //         .map((doc) => ProductModel.fromFirestore(doc))
  //         .where((product) {
  //       // Apply display rules first
  //       if (!product.isOnSale || product.isDeleted) {
  //         return false;
  //       }
  //       if (product.endDate != null &&
  //           product.endDate!.isBefore(DateTime.now())) {
  //         return false;
  //       }
  //       // Then apply search filter
  //       return product.name.toLowerCase().contains(query.toLowerCase()) ||
  //           product.description.toLowerCase().contains(query.toLowerCase());
  //     }).toList();

  //     return products;
  //   } catch (e) {
  //     throw ProductNotFoundException('상품 검색에 실패했습니다: $e');
  //   }
  // }

  // // 🏷️ 카테고리별 조회 (지역 + 카테고리)
  // Future<List<ProductModel>> getProductsByCategory(
  //     String category, String locationTagId) async {
  //   try {
  //     final QuerySnapshot snapshot = await _productsCollection
  //         .where('locationTagId', isEqualTo: locationTagId)
  //         .where('productCategory', isEqualTo: category)
  //         .where('isOnSale', isEqualTo: true)
  //         .where('isDeleted', isEqualTo: false)
  //         .orderBy('createdAt', descending: true)
  //         .get();

  //     final products =
  //         snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

  //     return products;
  //   } catch (e) {
  //     throw ProductNotFoundException('카테고리별 상품 조회에 실패했습니다: $e');
  //   }
  // }

  // 🏷️ 카테고리별 조회 with 페이지네이션 (locationTagNames 배열 지원)
  Future<ProductQueryResult> getProductsByLocationTagAndCategoryWithPagination(
    String locationTagName, // 🔄 locationTagId → locationTagName으로 변경
    String? category,
    DocumentSnapshot? lastDocument,
    int limit,
  ) async {
    try {
      // 🆕 모든 활성 상품을 조회 (locationTag 필터 제거)
      Query query = _productsCollection
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false);

      // 카테고리 필터 추가 (전체가 아닌 경우만)
      if (category != null && category != '전체') {
        query = query.where('productCategory', isEqualTo: category);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();
      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((product) {
        // Filter products based on display rules:
        // 1. isOnSale must be true
        // 2. isDeleted must be false
        // 3. endDate must be null or after current date/time
        if (!product.isOnSale || product.isDeleted) {
          return false;
        }
        if (product.endDate != null &&
            product.endDate!.isBefore(DateTime.now())) {
          return false;
        }

        // 🆕 deliveryType 기반 필터링 로직 추가
        // - 픽업(Pickup) 타입: 사용자의 locationTag와 상품의 locationTag가 일치해야 함
        // - 배송(Delivery/Shipping) 타입: locationTag와 관계없이 모든 사용자에게 표시
        if (product.deliveryType == '픽업' || product.deliveryType == 'Pickup') {
          // 픽업 상품은 사용자의 locationTag가 상품의 locationTagNames에 포함되어야만 표시
          return product.locationTagNames.contains(locationTagName);
        } else {
          // 배송 상품은 locationTag와 관계없이 모든 사용자에게 표시
          return true;
        }
      }).toList();

      return ProductQueryResult(
        products: products,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      throw ProductLocationMismatchException('카테고리별 상품 조회에 실패했습니다: $e');
    }
  }

  // // ⏰ 공구 기간 관리 - 현재 판매 중인 상품들
  // Future<List<ProductModel>> getActiveProducts(String locationTagId) async {
  //   try {
  //     final now = DateTime.now();
  //     final QuerySnapshot snapshot = await _productsCollection
  //         .where('locationTagId', isEqualTo: locationTagId)
  //         .where('isOnSale', isEqualTo: true)
  //         .where('isDeleted', isEqualTo: false)
  //         .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
  //         .orderBy('startDate')
  //         .orderBy('createdAt', descending: true)
  //         .get();

  //     // 종료일이 없거나 아직 지나지 않은 상품들만 필터링
  //     final products = snapshot.docs
  //         .map((doc) => ProductModel.fromFirestore(doc))
  //         .where((product) => product.isSaleActive)
  //         .toList();

  //     return products;
  //   } catch (e) {
  //     throw ProductNotFoundException('활성 상품 조회에 실패했습니다: $e');
  //   }
  // }

  // // ⏰ 공구 기간 관리 - 판매 예정 상품들
  // Future<List<ProductModel>> getUpcomingProducts(String locationTagId) async {
  //   try {
  //     final now = DateTime.now();
  //     final QuerySnapshot snapshot = await _productsCollection
  //         .where('locationTagId', isEqualTo: locationTagId)
  //         .where('isOnSale', isEqualTo: true)
  //         .where('isDeleted', isEqualTo: false)
  //         .where('startDate', isGreaterThan: Timestamp.fromDate(now))
  //         .orderBy('startDate')
  //         .get();

  //     final products =
  //         snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

  //     return products;
  //   } catch (e) {
  //     throw ProductNotFoundException('예정 상품 조회에 실패했습니다: $e');
  //   }
  // }

  // // Get all products
  // Future<List<ProductModel>> getAllProducts() async {
  //   try {
  //     final QuerySnapshot snapshot = await _productsCollection
  //         .where('isOnSale', isEqualTo: true)
  //         .where('isDeleted', isEqualTo: false)
  //         .orderBy('createdAt', descending: true)
  //         .get();

  //     final products =
  //         snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

  //     return products;
  //   } catch (e) {
  //     throw ProductNotFoundException('상품 목록을 불러오는데 실패했습니다: $e');
  //   }
  // }

  // // 🌍 LocationTag 기반 상품 조회 (이름 기반) - ProductState에서 호출
  // Future<ProductQueryResult> getProductsByLocationTag(
  //     String locationTagName, DocumentSnapshot? lastDocument, int limit) async {
  //   try {
  //     // 🆕 LocationTagRepository를 사용하여 이름을 ID로 변환
  //     final locationTagId = await _locationTagRepository
  //         .convertLocationTagNameToId(locationTagName);

  //     if (locationTagId == null) {
  //       throw ProductLocationMismatchException(
  //           'LocationTag "$locationTagName"을 찾을 수 없습니다');
  //     }

  //     // LocationTag ID 기반으로 상품 조회
  //     return await getProductsByLocationTagIdWithPagination(
  //         locationTagId, lastDocument, limit);
  //   } catch (e) {
  //     if (e is ProductLocationMismatchException) rethrow;
  //     throw ProductLocationMismatchException(
  //         'LocationTag 기반 상품 조회에 실패했습니다: $e');
  //   }
  // }

  // Get product by ID
  Future<ProductModel> getProductById(String productId) async {
    try {
      final DocumentSnapshot doc =
          await _productsCollection.doc(productId).get();

      if (!doc.exists) {
        throw ProductNotFoundException('상품을 찾을 수 없습니다: $productId');
      }

      final product = ProductModel.fromFirestore(doc);
      return product;
    } catch (e) {
      if (e is ProductNotFoundException) rethrow;
      throw ProductNotFoundException('상품 정보를 불러오는데 실패했습니다: $e');
    }
  }
}
