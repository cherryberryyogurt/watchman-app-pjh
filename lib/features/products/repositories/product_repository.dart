import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../exceptions/product_exceptions.dart';
import '../exceptions/location_exceptions.dart';
import 'dart:math';

// ProductQueryResult 클래스 정의
class ProductQueryResult {
  final List<ProductModel> products;
  final DocumentSnapshot? lastDocument;

  ProductQueryResult({required this.products, this.lastDocument});
}

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // 좌표 기반으로 가장 가까운 LocationTag 결정
      String locationTagId = _getLocationTagIdFromCoordinates(location);

      // LocationTag 기반으로 상품 조회
      return await getProductsByLocationTagIdWithPagination(
          locationTagId, lastDocument, limit);
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

      // LocationTag 이름을 ID로 변환
      String locationTagId = _convertLocationTagNameToId(locationTagName);

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

  // 🗺️ 좌표에서 LocationTag ID 결정하는 헬퍼 메서드
  String _getLocationTagIdFromCoordinates(GeoPoint location) {
    // 주요 지역의 좌표 중심과 해당 지역 태그 정의
    final regionMap = [
      {
        'name': 'gangnam_dong',
        'center': const GeoPoint(37.4988, 127.0281),
        'radius': 2.0
      },
      {
        'name': 'seocho_dong',
        'center': const GeoPoint(37.4923, 127.0292),
        'radius': 2.0
      },
      {
        'name': 'songpa_dong',
        'center': const GeoPoint(37.5145, 127.1057),
        'radius': 2.0
      },
      {
        'name': 'yeongdeungpo_dong',
        'center': const GeoPoint(37.5257, 126.8957),
        'radius': 2.0
      },
      {
        'name': 'gangseo_dong',
        'center': const GeoPoint(37.5509, 126.8495),
        'radius': 2.0
      },
    ];

    // 현재 위치와 가장 가까운 지역 찾기
    double minDistance = double.infinity;
    String nearestRegionId = 'gangnam_dong'; // 기본값

    for (final region in regionMap) {
      final center = region['center'] as GeoPoint;

      // 두 좌표 간의 거리 계산 (단순화된 근사값)
      final latDiff = (location.latitude - center.latitude) * 111.0;
      final lngDiff = (location.longitude - center.longitude) * 111.0;
      final distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);

      if (distance < minDistance) {
        minDistance = distance;
        nearestRegionId = region['name'] as String;
      }
    }

    return nearestRegionId;
  }

  // 🗺️ LocationTag 이름을 ID로 변환하는 헬퍼 메서드
  String _convertLocationTagNameToId(String locationTagName) {
    const locationTagMapping = {
      '강남동': 'gangnam_dong',
      '서초동': 'seocho_dong',
      '송파동': 'songpa_dong',
      '영등포동': 'yeongdeungpo_dong',
      '강서동': 'gangseo_dong',
      '전체': 'gangnam_dong', // 기본값
    };

    return locationTagMapping[locationTagName] ?? 'gangnam_dong';
  }

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
        'locationTagId': 'gangnam_dong', // 🔄 새로운 구조
        'locationTagName': '강남동', // 🔄 새로운 구조
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
        'locationTagId': 'seocho_dong', // 🔄 새로운 구조
        'locationTagName': '서초동', // 🔄 새로운 구조
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
        'locationTagId': 'songpa_dong', // 🔄 새로운 구조
        'locationTagName': '송파동', // 🔄 새로운 구조
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
