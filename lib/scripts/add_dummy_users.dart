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
  
  // 더미 사용자 데이터 생성 및 추가
  await addDummyUsers(firestore);
  
  print('모든 더미 사용자 데이터가 성공적으로 추가되었습니다.');
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
    {
      'uid': 'dummy_seller_6',
      'email': 'game_mania@example.com',
      'name': '게임마니아',
      'phoneNumber': '010-6789-0123',
      'address': '서울시 중구 명동길 55',
      'addressDetail': '명동역 5번 출구',
      'profileImageUrl': 'https://via.placeholder.com/150',
      'isPhoneVerified': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
    {
      'uid': 'dummy_seller_7',
      'email': 'tablet_master@example.com',
      'name': '태블릿달인',
      'phoneNumber': '010-7890-1234',
      'address': '경기도 성남시 분당구 판교역로 111',
      'addressDetail': '판교테크노밸리 3단지',
      'profileImageUrl': 'https://via.placeholder.com/150',
      'isPhoneVerified': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
    {
      'uid': 'dummy_seller_8',
      'email': 'audio_mania@example.com',
      'name': '오디오매니아',
      'phoneNumber': '010-8901-2345',
      'address': '경기도 부천시 부천로 222',
      'addressDetail': '부천역 2번 출구',
      'profileImageUrl': 'https://via.placeholder.com/150',
      'isPhoneVerified': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
    {
      'uid': 'dummy_seller_9',
      'email': 'camping_master@example.com',
      'name': '캠핑마스터',
      'phoneNumber': '010-9012-3456',
      'address': '경기도 고양시 일산동구 호수로 333',
      'addressDetail': '라페스타 3층',
      'profileImageUrl': 'https://via.placeholder.com/150',
      'isPhoneVerified': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
    {
      'uid': 'dummy_seller_10',
      'email': 'sneakers_collector@example.com',
      'name': '스니커즈콜렉터',
      'phoneNumber': '010-0123-4567',
      'address': '인천시 부평구 부평대로 444',
      'addressDetail': '부평역 4번 출구',
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