import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Firestore 초기화
  final firestore = FirebaseFirestore.instance;
  
  // 더미 상품 데이터 생성 및 추가
  await addDummyProducts(firestore);
  
  print('모든 더미 데이터가 성공적으로 추가되었습니다.');
}

Future<void> addDummyProducts(FirebaseFirestore firestore) async {
  // products 컬렉션 참조
  final productsRef = firestore.collection('products');
  
  // 이미지 URL (실제 이미지 URL로 대체하세요)
  final defaultImageUrls = [
    'https://via.placeholder.com/400x300',
    'https://via.placeholder.com/400x300?text=Product+Image',
  ];
  
  // 더미 데이터 목록
  final dummyProducts = [
    {
      'name': '아이폰 15 Pro 256GB',
      'description': '완전 새제품, 미개봉 상태입니다. 색상은 티타늄 블랙이고, 정품 애플케어+ 가입 가능합니다.',
      'price': 1450000,
      'location': '서울시 강남구',
      'imageUrls': defaultImageUrls,
      'sellerId': 'dummy_seller_1',
      'sellerName': '애플러버',
      'coordinates': GeoPoint(37.5172, 127.0473),  // 강남구 좌표
      'createdAt': Timestamp.now(),
      'options': [
        {
          'name': '색상',
          'values': ['티타늄 블랙', '티타늄 내추럴', '티타늄 블루']
        }
      ],
      'stock': 1,
      'isAvailable': true,
    },
    {
      'name': '갤럭시 S24 울트라 512GB',
      'description': '사용기간 1개월 미만, 풀박스 구성품 모두 있습니다. 필름 부착 상태이며 케이스 함께 드립니다.',
      'price': 1350000,
      'location': '서울시 송파구',
      'imageUrls': defaultImageUrls,
      'sellerId': 'dummy_seller_2',
      'sellerName': '테크마스터',
      'coordinates': GeoPoint(37.5145, 127.1058),  // 송파구 좌표
      'createdAt': Timestamp.now(),
      'options': [
        {
          'name': '색상',
          'values': ['블랙', '화이트', '바이올렛']
        }
      ],
      'stock': 1,
      'isAvailable': true,
    },
    {
      'name': '맥북 프로 M3 14인치',
      'description': '2024년식 맥북 프로 M3 14인치 모델입니다. 램 16GB, SSD 512GB 사양입니다. 키보드/스크린 보호필름 부착 상태이며 충전 사이클 10회 미만입니다.',
      'price': 2200000,
      'location': '서울시 마포구',
      'imageUrls': defaultImageUrls,
      'sellerId': 'dummy_seller_3',
      'sellerName': '맥북장인',
      'coordinates': GeoPoint(37.5665, 126.9018),  // 마포구 좌표
      'createdAt': Timestamp.now(),
      'options': null,
      'stock': 1,
      'isAvailable': true,
    },
    {
      'name': '다이슨 에어랩',
      'description': '다이슨 에어랩 컴플리트 세트입니다. 구매 후 3번 사용했습니다. 모든 구성품 있고 상태 매우 좋습니다.',
      'price': 420000,
      'location': '서울시 서초구',
      'imageUrls': defaultImageUrls,
      'sellerId': 'dummy_seller_4',
      'sellerName': '뷰티퀸',
      'coordinates': GeoPoint(37.4837, 127.0324),  // 서초구 좌표
      'createdAt': Timestamp.now(),
      'options': null,
      'stock': 1,
      'isAvailable': true,
    },
    {
      'name': 'LG 스탠바이미',
      'description': '구매한지 2주 지났습니다. 거치대까지 모두 있고 미어캣 무선충전 세트 함께 드립니다.',
      'price': 880000,
      'location': '서울시 용산구',
      'imageUrls': defaultImageUrls,
      'sellerId': 'dummy_seller_5',
      'sellerName': '디지털홈',
      'coordinates': GeoPoint(37.5320, 126.9901),  // 용산구 좌표
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      'options': null,
      'stock': 1,
      'isAvailable': true,
    },
    {
      'name': '닌텐도 스위치 OLED 모델',
      'description': '닌텐도 스위치 OLED 화이트 모델입니다. 풀박스에 구성품 모두 있고, 젤다의 전설, 마리오 카트 게임 카트리지 함께 드립니다.',
      'price': 330000,
      'location': '서울시 중구',
      'imageUrls': defaultImageUrls,
      'sellerId': 'dummy_seller_6',
      'sellerName': '게임마니아',
      'coordinates': GeoPoint(37.5636, 126.9975),  // 중구 좌표
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      'options': null,
      'stock': 1,
      'isAvailable': true,
    },
    {
      'name': '아이패드 프로 M2 11인치',
      'description': '아이패드 프로 M2 11인치 256GB 스페이스그레이 Wi-Fi 모델입니다. 애플펜슬 2세대와 매직키보드 포함입니다.',
      'price': 1150000,
      'location': '경기도 성남시',
      'imageUrls': defaultImageUrls,
      'sellerId': 'dummy_seller_7',
      'sellerName': '태블릿달인',
      'coordinates': GeoPoint(37.4449, 127.1389),  // 성남시 좌표
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
      'options': null,
      'stock': 1,
      'isAvailable': true,
    },
    {
      'name': '소니 WH-1000XM5 헤드폰',
      'description': '소니 WH-1000XM5 노이즈캔슬링 헤드폰입니다. 구매 후 한 달 사용했고 케이스, 충전 케이블 등 구성품 모두 있습니다.',
      'price': 280000,
      'location': '경기도 부천시',
      'imageUrls': defaultImageUrls,
      'sellerId': 'dummy_seller_8',
      'sellerName': '오디오매니아',
      'coordinates': GeoPoint(37.5035, 126.7882),  // 부천시 좌표
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
      'options': [
        {
          'name': '색상',
          'values': ['블랙', '화이트']
        }
      ],
      'stock': 1,
      'isAvailable': true,
    },
    {
      'name': '캠핑용 텐트 4인용',
      'description': '코베아 트리플돔 텐트 4인용입니다. 사용 2회로 상태 매우 좋고, 그라운드시트, 폴대 등 구성품 모두 있습니다.',
      'price': 180000,
      'location': '경기도 고양시',
      'imageUrls': defaultImageUrls,
      'sellerId': 'dummy_seller_9',
      'sellerName': '캠핑마스터',
      'coordinates': GeoPoint(37.6583, 126.8320),  // 고양시 좌표
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
      'options': null,
      'stock': 1,
      'isAvailable': true,
    },
    {
      'name': '나이키 에어포스1 로우 화이트',
      'description': '나이키 에어포스1 로우 클래식 화이트 255mm입니다. 신품이고 국내 나이키 매장에서 구매한 정품입니다.',
      'price': 120000,
      'location': '인천시 부평구',
      'imageUrls': defaultImageUrls,
      'sellerId': 'dummy_seller_10',
      'sellerName': '스니커즈콜렉터',
      'coordinates': GeoPoint(37.5053, 126.7020),  // 부평구 좌표
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 12))),
      'options': [
        {
          'name': '사이즈',
          'values': ['240mm', '245mm', '250mm', '255mm', '260mm']
        }
      ],
      'stock': 5,
      'isAvailable': true,
    },
  ];
  
  // 데이터 추가
  int count = 0;
  for (final product in dummyProducts) {
    try {
      await productsRef.add(product);
      count++;
      print('${product['name']} 추가 완료');
    } catch (e) {
      print('${product['name']} 추가 실패: $e');
    }
  }
  
  print('총 $count개의 더미 상품이 추가되었습니다.');
} 