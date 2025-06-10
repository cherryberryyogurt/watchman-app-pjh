import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../exceptions/product_exceptions.dart';
import '../exceptions/location_exceptions.dart';
import 'dart:math';
// 🆕 LocationTag 관련 추가
import '../../location/repositories/location_tag_repository.dart';
import '../../location/exceptions/location_tag_exceptions.dart';

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
      print(
          '🛍️ ProductRepository: getProductsByLocationTagId($locationTagId) - 시작');

      final QuerySnapshot snapshot = await _productsCollection
          .where('locationTagId', isEqualTo: locationTagId)
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      print('🛍️ ProductRepository: ${products.length}개 상품 조회 완료');
      return products;
    } catch (e) {
      print(
          '🛍️ ProductRepository: getProductsByLocationTagId($locationTagId) - 오류: $e');
      throw ProductLocationMismatchException('해당 지역의 상품을 불러오는데 실패했습니다: $e');
    }
  }

  // 🌍 위치 기반 상품 조회 (핵심 기능) - LocationTag Name으로
  Future<List<ProductModel>> getProductsByLocationTagName(
      String locationTagName) async {
    try {
      print(
          '🛍️ ProductRepository: getProductsByLocationTagName($locationTagName) - 시작');

      final QuerySnapshot snapshot = await _productsCollection
          .where('locationTagName', isEqualTo: locationTagName)
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      print('🛍️ ProductRepository: ${products.length}개 상품 조회 완료');
      return products;
    } catch (e) {
      print(
          '🛍️ ProductRepository: getProductsByLocationTagName($locationTagName) - 오류: $e');
      throw ProductLocationMismatchException('해당 지역의 상품을 불러오는데 실패했습니다: $e');
    }
  }

  // 🌍 위치 기반 상품 조회 with 페이지네이션 - LocationTag ID로
  Future<ProductQueryResult> getProductsByLocationTagIdWithPagination(
      String locationTagId, DocumentSnapshot? lastDocument, int limit) async {
    try {
      print(
          '🛍️ ProductRepository: getProductsByLocationTagIdWithPagination($locationTagId) - 시작');

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

      print('🛍️ ProductRepository: ${products.length}개 상품 조회 완료 (페이지네이션)');
      return ProductQueryResult(
        products: products,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      print(
          '🛍️ ProductRepository: getProductsByLocationTagIdWithPagination($locationTagId) - 오류: $e');
      throw ProductLocationMismatchException('해당 지역의 상품을 불러오는데 실패했습니다: $e');
    }
  }

  // 🔍 검색 (지역 필터링 포함)
  Future<List<ProductModel>> searchProductsInLocation(
      String query, String locationTagId) async {
    try {
      print(
          '🛍️ ProductRepository: searchProductsInLocation($query, $locationTagId) - 시작');

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

      print('🛍️ ProductRepository: ${products.length}개 검색 결과');
      return products;
    } catch (e) {
      print(
          '🛍️ ProductRepository: searchProductsInLocation($query, $locationTagId) - 오류: $e');
      throw ProductNotFoundException('상품 검색에 실패했습니다: $e');
    }
  }

  // 🏷️ 카테고리별 조회 (지역 + 카테고리)
  Future<List<ProductModel>> getProductsByCategory(
      String category, String locationTagId) async {
    try {
      print(
          '🛍️ ProductRepository: getProductsByCategory($category, $locationTagId) - 시작');

      final QuerySnapshot snapshot = await _productsCollection
          .where('locationTagId', isEqualTo: locationTagId)
          .where('productCategory', isEqualTo: category)
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      print('🛍️ ProductRepository: ${products.length}개 카테고리별 상품 조회 완료');
      return products;
    } catch (e) {
      print(
          '🛍️ ProductRepository: getProductsByCategory($category, $locationTagId) - 오류: $e');
      throw ProductNotFoundException('카테고리별 상품 조회에 실패했습니다: $e');
    }
  }

  // 🏷️ 카테고리별 조회 with 페이지네이션 (locationTagId + category)
  Future<ProductQueryResult> getProductsByLocationTagAndCategoryWithPagination(
    String locationTagId,
    String? category,
    DocumentSnapshot? lastDocument,
    int limit,
  ) async {
    try {
      print(
          '🛍️ ProductRepository: getProductsByLocationTagAndCategoryWithPagination($locationTagId, $category) - 시작');

      Query query = _productsCollection
          .where('locationTagId', isEqualTo: locationTagId)
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

      print(
          '🛍️ ProductRepository: ${products.length}개 카테고리별 상품 조회 완료 (페이지네이션)');
      return ProductQueryResult(
        products: products,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      print(
          '🛍️ ProductRepository: getProductsByLocationTagAndCategoryWithPagination($locationTagId, $category) - 오류: $e');
      throw ProductLocationMismatchException('카테고리별 상품 조회에 실패했습니다: $e');
    }
  }

  // ⏰ 공구 기간 관리 - 현재 판매 중인 상품들
  Future<List<ProductModel>> getActiveProducts(String locationTagId) async {
    try {
      print('🛍️ ProductRepository: getActiveProducts($locationTagId) - 시작');

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

      print('🛍️ ProductRepository: ${products.length}개 활성 상품 조회 완료');
      return products;
    } catch (e) {
      print(
          '🛍️ ProductRepository: getActiveProducts($locationTagId) - 오류: $e');
      throw ProductNotFoundException('활성 상품 조회에 실패했습니다: $e');
    }
  }

  // ⏰ 공구 기간 관리 - 판매 예정 상품들
  Future<List<ProductModel>> getUpcomingProducts(String locationTagId) async {
    try {
      print('🛍️ ProductRepository: getUpcomingProducts($locationTagId) - 시작');

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

      print('🛍️ ProductRepository: ${products.length}개 예정 상품 조회 완료');
      return products;
    } catch (e) {
      print(
          '🛍️ ProductRepository: getUpcomingProducts($locationTagId) - 오류: $e');
      throw ProductNotFoundException('예정 상품 조회에 실패했습니다: $e');
    }
  }

  // Get all products (기존 메서드 유지)
  Future<List<ProductModel>> getAllProducts() async {
    try {
      print('🛍️ ProductRepository: getAllProducts() - 시작');

      final QuerySnapshot snapshot = await _productsCollection
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      print('🛍️ ProductRepository: ${products.length}개 전체 상품 조회 완료');
      return products;
    } catch (e) {
      print('🛍️ ProductRepository: getAllProducts() - 오류: $e');
      throw ProductNotFoundException('상품 목록을 불러오는데 실패했습니다: $e');
    }
  }

  // 🌍 위치 기반 상품 조회 (좌표 기반) - ProductState에서 호출
  Future<ProductQueryResult> getProductsByLocation(GeoPoint location,
      double radius, DocumentSnapshot? lastDocument, int limit) async {
    try {
      print('🛍️ ProductRepository: getProductsByLocation() - 시작');

      // 🆕 LocationTagRepository를 사용하여 좌표 기반으로 가장 가까운 LocationTag 결정
      final locationTag =
          await _locationTagRepository.findLocationTagByCoordinates(location);

      if (locationTag == null) {
        throw ProductLocationMismatchException(
            '해당 위치에서 이용 가능한 LocationTag를 찾을 수 없습니다');
      }

      // LocationTag 기반으로 상품 조회
      return await getProductsByLocationTagIdWithPagination(
          locationTag.id, lastDocument, limit);
    } catch (e) {
      print('🛍️ ProductRepository: getProductsByLocation() - 오류: $e');
      throw ProductLocationMismatchException('위치 기반 상품 조회에 실패했습니다: $e');
    }
  }

  // 🌍 LocationTag 기반 상품 조회 (이름 기반) - ProductState에서 호출
  Future<ProductQueryResult> getProductsByLocationTag(
      String locationTagName, DocumentSnapshot? lastDocument, int limit) async {
    try {
      print(
          '🛍️ ProductRepository: getProductsByLocationTag($locationTagName) - 시작');

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
      print(
          '🛍️ ProductRepository: getProductsByLocationTag($locationTagName) - 오류: $e');
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
      print('🛍️ ProductRepository: getProductById($productId) - 시작');

      final DocumentSnapshot doc =
          await _productsCollection.doc(productId).get();

      if (!doc.exists) {
        throw ProductNotFoundException('상품을 찾을 수 없습니다: $productId');
      }

      final product = ProductModel.fromFirestore(doc);
      print('🛍️ ProductRepository: 상품 "$productId" 조회 완료');
      return product;
    } catch (e) {
      print('🛍️ ProductRepository: getProductById($productId) - 오류: $e');
      if (e is ProductNotFoundException) rethrow;
      throw ProductNotFoundException('상품 정보를 불러오는데 실패했습니다: $e');
    }
  }

  // 🆕 상품 생성
  Future<void> createProduct(ProductModel product) async {
    try {
      print('🛍️ ProductRepository: createProduct(${product.name}) - 시작');

      // 상품 데이터 검증
      _validateProductData(product);

      await _productsCollection.add(product.toMap());

      print('🛍️ ProductRepository: 상품 "${product.name}" 생성 완료');
    } catch (e) {
      print('🛍️ ProductRepository: createProduct(${product.name}) - 오류: $e');
      throw Exception('상품 생성에 실패했습니다: $e');
    }
  }

  // 🆕 상품 업데이트
  Future<void> updateProduct(ProductModel product) async {
    try {
      print('🛍️ ProductRepository: updateProduct(${product.name}) - 시작');

      // 상품 데이터 검증
      _validateProductData(product);

      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      await _productsCollection.doc(product.id).update(updatedProduct.toMap());

      print('🛍️ ProductRepository: 상품 "${product.name}" 업데이트 완료');
    } catch (e) {
      print('🛍️ ProductRepository: updateProduct(${product.name}) - 오류: $e');
      throw Exception('상품 업데이트에 실패했습니다: $e');
    }
  }

  // 🆕 상품 소프트 삭제
  Future<void> deleteProduct(String productId) async {
    try {
      print('🛍️ ProductRepository: deleteProduct($productId) - 시작');

      await _productsCollection.doc(productId).update({
        'isDeleted': true,
        'isOnSale': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('🛍️ ProductRepository: 상품 "$productId" 삭제 완료');
    } catch (e) {
      print('🛍️ ProductRepository: deleteProduct($productId) - 오류: $e');
      throw Exception('상품 삭제에 실패했습니다: $e');
    }
  }

  // 🆕 재고 업데이트
  Future<void> updateStock(String productId, int newStock) async {
    try {
      print('🛍️ ProductRepository: updateStock($productId, $newStock) - 시작');

      if (newStock < 0) {
        throw ProductOutOfStockException('재고는 0 이상이어야 합니다');
      }

      await _productsCollection.doc(productId).update({
        'stock': newStock,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('🛍️ ProductRepository: 상품 "$productId" 재고 업데이트 완료');
    } catch (e) {
      print(
          '🛍️ ProductRepository: updateStock($productId, $newStock) - 오류: $e');
      rethrow;
    }
  }

  // Add dummy products for testing (only for development)
  Future<void> addDummyProducts() async {
    print('🛍️ ProductRepository: addDummyProducts() - 시작');

    // Sample product data with new LocationTag structure
    final List<Map<String, dynamic>> dummyProducts = [
      {
        'name': '당일 수확 유기농 방울토마토',
        'description':
            '# 당일 수확한 유기농 방울토마토\n\n**맛있고 신선한 방울토마토**\n\n* 중량: 500g/팩\n* 생산지: 강남농장\n* 특징: 무농약, 유기농법으로 재배\n\n직접 수확하여 판매합니다. 무항생제, 무항균제, 무잔류농약 검사 완료했습니다.',
        'price': 8900,
        'orderUnit': '1팩(500g)',
        'stock': 20,
        'locationTagId': 'huam_dong', // 🔄 새로운 구조
        'locationTagName': '후암동', // 🔄 새로운 구조
        'productCategory': '농산물',
        'thumbnailUrl':
            'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Ftomato.jpg?alt=media',
        'deliveryType': '픽업',
        'pickupInfo': ['강남역 2번 출구', '오후 6시 ~ 7시'],
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
        'isOnSale': true,
        'isDeleted': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': '친환경 유기농 달걀',
        'description':
            '# 무항생제 유정란\n\n**자연 방목으로 키운 닭이 낳은 달걀**\n\n* 중량: 30구\n* 생산지: 서초 자연농장\n* 특징: 무항생제, 방목 사육\n\n매일 아침 수거한 신선한 달걀입니다. HACCP 인증 시설에서 포장됩니다.',
        'price': 12000,
        'orderUnit': '1판(30구)',
        'stock': 15,
        'locationTagId': 'oksu_dong', // 🔄 새로운 구조
        'locationTagName': '옥수동', // 🔄 새로운 구조
        'productCategory': '축산물',
        'thumbnailUrl':
            'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Feggs.jpg?alt=media',
        'deliveryType': '배송',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
        'isOnSale': true,
        'isDeleted': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': '제철 햇 사과',
        'description':
            '# 당도 높은 제철 사과\n\n**친환경 농법으로 재배한 사과**\n\n* 중량: 3kg(9~12과)\n* 생산지: 송파 과수원\n* 당도: 14Brix 이상\n\n무농약 재배, 세척 없이 바로 드실 수 있습니다.',
        'price': 25000,
        'orderUnit': '1박스(3kg)',
        'stock': 8,
        'locationTagId': 'yeoksam_dong', // 🔄 새로운 구조
        'locationTagName': '역삼동', // 🔄 새로운 구조
        'productCategory': '농산물',
        'thumbnailUrl':
            'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Fapples.jpg?alt=media',
        'deliveryType': '픽업',
        'pickupInfo': ['송파역 1번 출구', '오전 10시 ~ 오후 2시'],
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 5))),
        'isOnSale': true,
        'isDeleted': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': '신선한 고등어',
        'description':
            '# 당일 잡은 신선한 고등어\n\n**바다에서 직접 잡은 고등어**\n\n* 중량: 2마리(약 800g)\n* 산지: 부산 연안\n* 특징: 당일 어획, 급속 냉동\n\n신선도가 생명인 고등어를 당일 배송으로 제공합니다.',
        'price': 15000,
        'orderUnit': '2마리',
        'stock': 12,
        'locationTagId': 'oksu_dong',
        'locationTagName': '옥수동',
        'productCategory': '수산물',
        'thumbnailUrl':
            'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Fmackerel.jpg?alt=media',
        'deliveryType': '배송',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 2))),
        'isOnSale': true,
        'isDeleted': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'name': '수제 김치',
        'description':
            '# 할머니 손맛 수제 김치\n\n**전통 방식으로 담근 김치**\n\n* 중량: 1kg\n* 재료: 국산 배추, 천일염\n* 특징: 무첨가물, 자연 발효\n\n3대째 이어온 전통 레시피로 정성스럽게 담근 김치입니다.',
        'price': 18000,
        'orderUnit': '1포기(1kg)',
        'stock': 25,
        'locationTagId': 'huam_dong',
        'locationTagName': '후암동',
        'productCategory': '기타',
        'thumbnailUrl':
            'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Fkimchi.jpg?alt=media',
        'deliveryType': '픽업',
        'pickupInfo': ['강서구청역 3번 출구', '오후 2시 ~ 6시'],
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 10))),
        'isOnSale': true,
        'isDeleted': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
    ];

    // Add dummy products to Firestore
    try {
      for (final product in dummyProducts) {
        await _productsCollection.add(product);
      }
      print('🛍️ ProductRepository: ${dummyProducts.length}개 더미 상품 추가 완료');
    } catch (e) {
      print('🛍️ ProductRepository: addDummyProducts() - 오류: $e');
      throw Exception('더미 상품 추가에 실패했습니다: $e');
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
      throw LocationValidationException('LocationTag ID는 필수 입력 항목입니다');
    }

    if (product.locationTagName.trim().isEmpty) {
      throw LocationValidationException('LocationTag 이름은 필수 입력 항목입니다');
    }

    // 공구 기간 검증
    if (product.startDate != null && product.endDate != null) {
      if (product.endDate!.isBefore(product.startDate!)) {
        throw ProductSaleEndedException('공구 종료일은 시작일보다 늦어야 합니다');
      }
    }
  }
}
