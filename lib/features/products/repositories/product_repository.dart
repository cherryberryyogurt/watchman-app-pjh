import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../exceptions/product_exceptions.dart';
import '../../location/repositories/location_tag_repository.dart';
import '../../../core/exceptions/location_exceptions.dart';

// ProductQueryResult 클래스 정의
class ProductQueryResult {
  final List<ProductModel> products;
  final DocumentSnapshot? lastDocument;

  ProductQueryResult({required this.products, this.lastDocument});
}

class ProductRepository {
  final FirebaseFirestore _firestore;
  // 🆕 LocationTag 의존성 주입
  final LocationTagRepository _locationTagRepository;

  ProductRepository({
    FirebaseFirestore? firestore,
    LocationTagRepository? locationTagRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _locationTagRepository =
            locationTagRepository ?? LocationTagRepository();

  // Get collection reference
  CollectionReference get _productsCollection =>
      _firestore.collection('products');

  // 🌍 위치 기반 상품 조회 (핵심 기능) - LocationTag ID로
  Future<List<ProductModel>> getProductsByLocationTagId(
      String locationTagId) async {
    try {
      final QuerySnapshot snapshot = await _productsCollection
          .where('locationTagId', isEqualTo: locationTagId)
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      return products;
    } catch (e) {
      throw ProductLocationMismatchException('해당 지역의 상품을 불러오는데 실패했습니다: $e');
    }
  }

  // 🌍 위치 기반 상품 조회 (핵심 기능) - LocationTag Name으로
  Future<List<ProductModel>> getProductsByLocationTagName(
      String locationTagName) async {
    try {
      final QuerySnapshot snapshot = await _productsCollection
          .where('locationTagNames', arrayContains: locationTagName)
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      return products;
    } catch (e) {
      throw ProductLocationMismatchException('해당 지역의 상품을 불러오는데 실패했습니다: $e');
    }
  }

  // 🌍 위치 기반 상품 조회 with 페이지네이션 - LocationTag ID로
  Future<ProductQueryResult> getProductsByLocationTagIdWithPagination(
      String locationTagId, DocumentSnapshot? lastDocument, int limit) async {
    try {
      Query query = _productsCollection
          .where('locationTagId', isEqualTo: locationTagId)
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      return ProductQueryResult(
        products: products,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      throw ProductLocationMismatchException('해당 지역의 상품을 불러오는데 실패했습니다: $e');
    }
  }

  // 🌍 위치 기반 상품 조회 with 페이지네이션 - LocationTag Name으로
  Future<ProductQueryResult> getProductsByLocationTagNameWithPagination(
      String locationTagName, DocumentSnapshot? lastDocument, int limit) async {
    try {
      Query query = _productsCollection
          .where('locationTagNames', arrayContains: locationTagName)
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      return ProductQueryResult(
        products: products,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      throw ProductLocationMismatchException('해당 지역의 상품을 불러오는데 실패했습니다: $e');
    }
  }

  // 🔍 검색 (지역 필터링 포함)
  Future<List<ProductModel>> searchProductsInLocation(
      String query, String locationTagId) async {
    try {
      // Firestore에서는 full-text search가 제한적이므로 name 필드로 검색
      final QuerySnapshot snapshot = await _productsCollection
          .where('locationTagId', isEqualTo: locationTagId)
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('name')
          .startAt([query]).endAt([query + '\uf8ff']).get();

      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.description.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return products;
    } catch (e) {
      throw ProductNotFoundException('상품 검색에 실패했습니다: $e');
    }
  }

  // 🏷️ 카테고리별 조회 (지역 + 카테고리)
  Future<List<ProductModel>> getProductsByCategory(
      String category, String locationTagId) async {
    try {
      final QuerySnapshot snapshot = await _productsCollection
          .where('locationTagId', isEqualTo: locationTagId)
          .where('productCategory', isEqualTo: category)
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      return products;
    } catch (e) {
      throw ProductNotFoundException('카테고리별 상품 조회에 실패했습니다: $e');
    }
  }

  // 🏷️ 카테고리별 조회 with 페이지네이션 (locationTagNames 배열 지원)
  Future<ProductQueryResult> getProductsByLocationTagAndCategoryWithPagination(
    String locationTagName, // 🔄 locationTagId → locationTagName으로 변경
    String? category,
    DocumentSnapshot? lastDocument,
    int limit,
  ) async {
    try {
      // 🆕 locationTagNames 배열에서 해당 locationTagName을 포함하는 상품 조회
      Query query = _productsCollection
          .where('locationTagNames', arrayContains: locationTagName)
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
      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      return ProductQueryResult(
        products: products,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      throw ProductLocationMismatchException('카테고리별 상품 조회에 실패했습니다: $e');
    }
  }

  // ⏰ 공구 기간 관리 - 현재 판매 중인 상품들
  Future<List<ProductModel>> getActiveProducts(String locationTagId) async {
    try {
      final now = DateTime.now();
      final QuerySnapshot snapshot = await _productsCollection
          .where('locationTagId', isEqualTo: locationTagId)
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('startDate')
          .orderBy('createdAt', descending: true)
          .get();

      // 종료일이 없거나 아직 지나지 않은 상품들만 필터링
      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((product) => product.isSaleActive)
          .toList();

      return products;
    } catch (e) {
      throw ProductNotFoundException('활성 상품 조회에 실패했습니다: $e');
    }
  }

  // ⏰ 공구 기간 관리 - 판매 예정 상품들
  Future<List<ProductModel>> getUpcomingProducts(String locationTagId) async {
    try {
      final now = DateTime.now();
      final QuerySnapshot snapshot = await _productsCollection
          .where('locationTagId', isEqualTo: locationTagId)
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .where('startDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('startDate')
          .get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      return products;
    } catch (e) {
      throw ProductNotFoundException('예정 상품 조회에 실패했습니다: $e');
    }
  }

  // Get all products (기존 메서드 유지)
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final QuerySnapshot snapshot = await _productsCollection
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      return products;
    } catch (e) {
      throw ProductNotFoundException('상품 목록을 불러오는데 실패했습니다: $e');
    }
  }

  // // 🌍 위치 기반 상품 조회 (좌표 기반) - ProductState에서 호출
  // Future<ProductQueryResult> getProductsByLocation(GeoPoint location,
  //     double radius, DocumentSnapshot? lastDocument, int limit) async {
  //   try {
  //     // LocationTag 좌표 기반 조회
  //     final locationTag =
  //         await _locationTagRepository.findLocationTagByCoordinates(location);

  //     if (locationTag == null) {
  //       throw ProductLocationMismatchException(
  //           '해당 위치에서 이용 가능한 LocationTag를 찾을 수 없습니다');
  //     }

  //     // LocationTag 기반으로 상품 조회
  //     return await getProductsByLocationTagIdWithPagination(
  //         locationTag.id, lastDocument, limit);
  //   } catch (e) {
  //     throw ProductLocationMismatchException('좌표 기반 상품 조회에 실패했습니다: $e');
  //   }
  // }

  // 🌍 LocationTag 기반 상품 조회 (이름 기반) - ProductState에서 호출
  Future<ProductQueryResult> getProductsByLocationTag(
      String locationTagName, DocumentSnapshot? lastDocument, int limit) async {
    try {
      // 🆕 LocationTagRepository를 사용하여 이름을 ID로 변환
      final locationTagId = await _locationTagRepository
          .convertLocationTagNameToId(locationTagName);

      if (locationTagId == null) {
        throw ProductLocationMismatchException(
            'LocationTag "$locationTagName"을 찾을 수 없습니다');
      }

      // LocationTag ID 기반으로 상품 조회
      return await getProductsByLocationTagIdWithPagination(
          locationTagId, lastDocument, limit);
    } catch (e) {
      if (e is ProductLocationMismatchException) rethrow;
      throw ProductLocationMismatchException(
          'LocationTag 기반 상품 조회에 실패했습니다: $e');
    }
  }

  // 🔴 제거됨: 하드코딩된 헬퍼 메서드들이 LocationTagRepository로 대체됨
  // _getLocationTagIdFromCoordinates -> LocationTagRepository.findLocationTagByCoordinates
  // _convertLocationTagNameToId -> LocationTagRepository.convertLocationTagNameToId

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

  // 🆕 상품 생성
  Future<void> createProduct(ProductModel product) async {
    try {
      _validateProductData(product);
      await _productsCollection.add(product.toMap());
    } catch (e) {
      throw Exception('상품 생성에 실패했습니다: $e');
    }
  }

  // 🆕 상품 업데이트
  Future<void> updateProduct(ProductModel product) async {
    try {
      _validateProductData(product);
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      await _productsCollection.doc(product.id).update(updatedProduct.toMap());
    } catch (e) {
      throw Exception('상품 업데이트에 실패했습니다: $e');
    }
  }

  // 🆕 상품 소프트 삭제
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).update({
        'isDeleted': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('상품 삭제에 실패했습니다: $e');
    }
  }

  // 🆕 재고 업데이트
  Future<void> updateStock(String productId, int newStock) async {
    try {
      if (newStock < 0) {
        throw ProductOutOfStockException('재고는 0 이상이어야 합니다');
      }

      await _productsCollection.doc(productId).update({
        'stock': newStock,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      if (e is ProductOutOfStockException) rethrow;
      throw Exception('재고 업데이트에 실패했습니다: $e');
    }
  }

  // 🔧 데이터 검증 헬퍼 메서드
  void _validateProductData(ProductModel product) {
    if (product.name.trim().isEmpty) {
      throw Exception('상품명은 필수 입력 항목입니다');
    }

    if (product.price <= 0) {
      throw Exception('상품 가격은 0보다 커야 합니다');
    }

    if (product.stock < 0) {
      throw ProductOutOfStockException('재고는 0 이상이어야 합니다');
    }

    if (product.locationTagId.trim().isEmpty) {
      throw LocationTagValidationException('LocationTag ID는 필수 입력 항목입니다');
    }

    if (product.locationTagName.trim().isEmpty) {
      throw LocationTagValidationException('LocationTag 이름은 필수 입력 항목입니다');
    }

    // 공구 기간 검증
    if (product.startDate != null && product.endDate != null) {
      if (product.endDate!.isBefore(product.startDate!)) {
        throw ProductSaleEndedException('공구 종료일은 시작일보다 늦어야 합니다');
      }
    }
  }
}
