import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Firestore 초기화
  final firestore = FirebaseFirestore.instance;
  
  // 1. 더미 사용자 추가
  print('===== 더미 사용자 추가 시작 =====');
  await addDummyUsers(firestore);
  print('===== 더미 사용자 추가 완료 =====\n');
  
  // 2. 더미 상품 추가
  print('===== 더미 상품 추가 시작 =====');
  await addDummyProducts(firestore);
  print('===== 더미 상품 추가 완료 =====\n');
  
  print('모든 더미 데이터가 성공적으로 추가되었습니다.');
  
  // 명령줄 실행을 위해 명시적으로 종료
  io.exit(0);
}

// 앱 종료를 위한 함수
void exit(int code) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(seconds: 1), () {
      print('프로그램 종료...');
    });
  });
}

Future<void> addDummyUsers(FirebaseFirestore firestore) async {
  // users 컬렉션 참조
  final usersRef = firestore.collection('users');
  
  // 더미 사용자 데이터 목록
  final dummyUsers = [
    {
      'uid': 'dummy_seller_1',
      'email': 'apple_lover@example.com',
      'name': '애플러버',
      'phoneNumber': '010-1234-5678',
      'address': '서울시 강남구 테헤란로 123',
      'addressDetail': '102동 1201호',
      'profileImageUrl': 'https://via.placeholder.com/150',
      'isPhoneVerified': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
    {
      'uid': 'dummy_seller_2',
      'email': 'tech_master@example.com',
      'name': '테크마스터',
      'phoneNumber': '010-2345-6789',
      'address': '서울시 송파구 올림픽로 456',
      'addressDetail': '롯데월드타워 3201호',
      'profileImageUrl': 'https://via.placeholder.com/150',
      'isPhoneVerified': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
    {
      'uid': 'dummy_seller_3',
      'email': 'macbook_pro@example.com',
      'name': '맥북장인',
      'phoneNumber': '010-3456-7890',
      'address': '서울시 마포구 와우산로 789',
      'addressDetail': '홍대입구역 3번 출구 앞',
      'profileImageUrl': 'https://via.placeholder.com/150',
      'isPhoneVerified': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
    {
      'uid': 'dummy_seller_4',
      'email': 'beauty_queen@example.com',
      'name': '뷰티퀸',
      'phoneNumber': '010-4567-8901',
      'address': '서울시 서초구 강남대로 101',
      'addressDetail': '서초역 4번 출구 앞',
      'profileImageUrl': 'https://via.placeholder.com/150',
      'isPhoneVerified': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
    {
      'uid': 'dummy_seller_5',
      'email': 'digital_home@example.com',
      'name': '디지털홈',
      'phoneNumber': '010-5678-9012',
      'address': '서울시 용산구 한강대로 303',
      'addressDetail': '용산전자상가 3층 23호',
      'profileImageUrl': 'https://via.placeholder.com/150',
      'isPhoneVerified': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
  ];
  
  // 데이터 추가
  int count = 0;
  for (final user in dummyUsers) {
    try {
      // 사용자 uid를 document ID로 사용
      await usersRef.doc(user['uid'] as String).set(user);
      count++;
      print('${user['name']} 사용자 추가 완료');
    } catch (e) {
      print('${user['name']} 사용자 추가 실패: $e');
    }
  }
  
  print('총 $count명의 더미 사용자가 추가되었습니다.');
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