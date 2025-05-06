import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'dart:math' show cos, pi;

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get collection reference
  CollectionReference get _productsCollection => 
      _firestore.collection('products');

  // Get all products
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final QuerySnapshot snapshot = await _productsCollection
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('상품 목록을 불러오는데 실패했습니다: $e');
    }
  }

  // Get products by location - 단순화된 버전 (좌표 범위 기반)
  Future<List<ProductModel>> getProductsByLocation(
      GeoPoint center, double radiusInKm) async {
    try {
      // 대략적인 좌표 범위 계산 (매우 단순화된 방식)
      // 위도 1도 = 약 111km, 경도 1도는 위도에 따라 다름 (적도에서 약 111km)
      final double latRange = radiusInKm / 111.0;
      final double lngRange = radiusInKm / (111.0 * cos(center.latitude * (pi / 180)));
      
      final QuerySnapshot snapshot = await _productsCollection
          .where('isAvailable', isEqualTo: true)
          .get();
      
      // 쿼리 결과에서 범위 내 아이템 필터링 (클라이언트 필터링)
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final GeoPoint? coordinates = data['coordinates'] as GeoPoint?;
        
        if (coordinates == null) return false;
        
        final bool withinLat = (coordinates.latitude >= center.latitude - latRange) && 
                               (coordinates.latitude <= center.latitude + latRange);
        final bool withinLng = (coordinates.longitude >= center.longitude - lngRange) && 
                               (coordinates.longitude <= center.longitude + lngRange);
        
        return withinLat && withinLng;
      }).toList();
      
      return filteredDocs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('주변 상품을 불러오는데 실패했습니다: $e');
    }
  }

  // Get product by ID
  Future<ProductModel> getProductById(String productId) async {
    try {
      final DocumentSnapshot doc = 
          await _productsCollection.doc(productId).get();
      
      if (!doc.exists) {
        throw Exception('상품을 찾을 수 없습니다');
      }
      
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('상품 정보를 불러오는데 실패했습니다: $e');
    }
  }

  // Get products by seller ID
  Future<List<ProductModel>> getProductsBySeller(String sellerId) async {
    try {
      final QuerySnapshot snapshot = await _productsCollection
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('판매자 상품을 불러오는데 실패했습니다: $e');
    }
  }

  // Add dummy products for testing (only for development)
  Future<void> addDummyProducts() async {
    // Sample product data
    final List<Map<String, dynamic>> dummyProducts = [
      {
        'name': '애플 아이폰 15 Pro',
        'description': '# 아이폰 15 Pro\n\n**상태 좋은 중고 아이폰 판매합니다.**\n\n* 구매일: 2023년 11월\n* 색상: 블루 티타늄\n* 용량: 256GB\n* 배터리 효율: 98%\n\n직거래 가능합니다.',
        'price': 1200000,
        'location': '서울시 강남구',
        'imageUrls': [
          'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Fiphone.jpg?alt=media',
          'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Fiphone_back.jpg?alt=media',
        ],
        'sellerId': 'dummy_seller_1',
        'sellerName': '애플팬',
        'coordinates': GeoPoint(37.4988, 127.0281), // 강남
        'createdAt': Timestamp.now(),
        'isAvailable': true,
      },
      {
        'name': '삼성 갤럭시 S24 울트라',
        'description': '# 갤럭시 S24 울트라\n\n**거의 새제품 갤럭시 S24 판매합니다.**\n\n* 구매일: 2024년 1월\n* 색상: 그레이\n* 용량: 512GB\n* 구성품: 본체, 충전기, 케이스\n\n직거래 우선, 택배 거래 가능합니다.',
        'price': 1350000,
        'location': '서울시 서초구',
        'imageUrls': [
          'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Fgalaxy.jpg?alt=media',
          'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Fgalaxy_back.jpg?alt=media',
        ],
        'sellerId': 'dummy_seller_2',
        'sellerName': '갤럭시마스터',
        'coordinates': GeoPoint(37.4923, 127.0292), // 서초
        'createdAt': Timestamp.now(),
        'isAvailable': true,
      },
      {
        'name': '맥북 프로 16인치 M3 Pro',
        'description': '# 맥북 프로 16인치 M3 Pro\n\n**한 달 사용한 맥북 프로 판매합니다.**\n\n* 모델: 16인치 M3 Pro 2023년형\n* 스펙: 18GB RAM, 512GB SSD\n* 보증: 애플케어 포함 (2년)\n\n직거래만 가능합니다.',
        'price': 2800000,
        'location': '서울시 송파구',
        'imageUrls': [
          'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Fmacbook.jpg?alt=media',
        ],
        'sellerId': 'dummy_seller_1',
        'sellerName': '애플팬',
        'coordinates': GeoPoint(37.5145, 127.1057), // 송파
        'createdAt': Timestamp.now(),
        'options': [
          {'name': '색상', 'values': ['스페이스 그레이', '실버']},
          {'name': '추가 옵션', 'values': ['파우치 포함 (+50,000원)', '기본']},
        ],
        'stock': 1,
        'isAvailable': true,
      },
    ];

    // Add dummy products to Firestore
    for (final product in dummyProducts) {
      await _productsCollection.add(product);
    }
  }
} 