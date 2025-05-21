import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

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

  // Get all products
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final QuerySnapshot snapshot = await _productsCollection
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('상품 목록을 불러오는데 실패했습니다: $e');
    }
  }

  // Get products by location tag
  Future<ProductQueryResult> getProductsByLocation(
      GeoPoint center, double radiusInKm, DocumentSnapshot? lastDocument, int limit) async {
    try {
      // 위치 중심 좌표에서 주소를 가져오는 로직이 필요함
      // 실제로는 Geocoding API 등을 사용해 위도/경도 -> 주소 -> locationTag를 추출하는 로직이 있어야 함
      // 여기서는 간단하게 하드코딩된 값으로 예시를 보여줌
      String locationTag = _getLocationTagFromCoordinates(center);
      
      Query query = _productsCollection
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .where('locationTag', isEqualTo: locationTag)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final QuerySnapshot snapshot = await query.get();
      
      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
      
      return ProductQueryResult(
        products: products,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      // Consider more specific error handling or logging
      print('Error in getProductsByLocation: $e');
      throw Exception('주변 상품을 불러오는데 실패했습니다: $e');
    }
  }

  // 좌표로부터 locationTag 추출하는 더미 메서드 (실제로는 Geocoding API 등을 사용해야 함)
  String _getLocationTagFromCoordinates(GeoPoint coordinates) {
    // 강남 주변 좌표인 경우
    if ((coordinates.latitude - 37.4988).abs() < 0.01 && 
        (coordinates.longitude - 127.0281).abs() < 0.01) {
      return '강남동';
    }
    // 서초 주변 좌표인 경우
    else if ((coordinates.latitude - 37.4923).abs() < 0.01 && 
             (coordinates.longitude - 127.0292).abs() < 0.01) {
      return '서초동';
    }
    // 송파 주변 좌표인 경우
    else if ((coordinates.latitude - 37.5145).abs() < 0.01 && 
             (coordinates.longitude - 127.1057).abs() < 0.01) {
      return '송파동';
    }
    // 기본값
    else {
      // 기본값 또는 오류 처리. ProductNotifier의 로직과 일관성 유지 필요.
      // 여기서는 ProductNotifier에서 '전체' 태그 외의 경우 특정 태그를 기대하므로,
      // 매칭되는 태그가 없을 경우 빈 리스트를 반환하거나,
      // ProductNotifier에서 이 함수를 호출하기 전에 locationTag를 결정하도록 변경하는 것이 좋음.
      // 지금은 임시로 '강남동'을 반환.
      return '강남동';
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

  // Get products by location tag
  Future<ProductQueryResult> getProductsByLocationTag(
      String locationTag, DocumentSnapshot? lastDocument, int limit) async {
    try {
      Query query = _productsCollection
          .where('locationTag', isEqualTo: locationTag)
          .where('isOnSale', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final QuerySnapshot snapshot = await query.get();
      
      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
          
      return ProductQueryResult(
        products: products,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      // Consider more specific error handling or logging
      print('Error in getProductsByLocationTag: $e');
      throw Exception('해당 지역 상품을 불러오는데 실패했습니다: $e');
    }
  }

  // Add dummy products for testing (only for development)
  Future<void> addDummyProducts() async {
    // Sample product data
    final List<Map<String, dynamic>> dummyProducts = [
      {
        'name': '당일 수확 유기농 방울토마토',
        'description': '# 당일 수확한 유기농 방울토마토\n\n**맛있고 신선한 방울토마토**\n\n* 중량: 500g/팩\n* 생산지: 강남농장\n* 특징: 무농약, 유기농법으로 재배\n\n직접 수확하여 판매합니다. 무항생제, 무항균제, 무잔류농약 검사 완료했습니다.',
        'price': 8900,
        'orderUnit': '1팩(500g)',
        'stock': 20,
        'locationTag': '강남동',
        'thumbnailUrl': 'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Ftomato.jpg?alt=media',
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
        'description': '# 무항생제 유정란\n\n**자연 방목으로 키운 닭이 낳은 달걀**\n\n* 중량: 30구\n* 생산지: 서초 자연농장\n* 특징: 무항생제, 방목 사육\n\n매일 아침 수거한 신선한 달걀입니다. HACCP 인증 시설에서 포장됩니다.',
        'price': 12000,
        'orderUnit': '1판(30구)',
        'stock': 15,
        'locationTag': '서초동',
        'thumbnailUrl': 'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Feggs.jpg?alt=media',
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
        'description': '# 당도 높은 제철 사과\n\n**친환경 농법으로 재배한 사과**\n\n* 중량: 3kg(9~12과)\n* 생산지: 송파 과수원\n* 당도: 14Brix 이상\n\n무농약 재배, 세척 없이 바로 드실 수 있습니다.',
        'price': 25000,
        'orderUnit': '1박스(3kg)',
        'stock': 8,
        'locationTag': '송파동',
        'thumbnailUrl': 'https://firebasestorage.googleapis.com/v0/b/gonggoo-app-pjh.appspot.com/o/products%2Fapples.jpg?alt=media',
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
    for (final product in dummyProducts) {
      await _productsCollection.add(product);
    }
  }
} 