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
  
  // 현재 로그인한 사용자 정보 추가
  await addCurrentUser(firestore);
  
  print('종료 중...');
  io.exit(0);
}

Future<void> addCurrentUser(FirebaseFirestore firestore) async {
  // users 컬렉션 참조
  final usersRef = firestore.collection('users');
  
  // 현재 로그인한 사용자 데이터
  final currentUser = {
    'uid': 'kYLFm08z8mdQ9ijOBC44AsPfbjM2',
    'email': 'test@example.com',
    'name': '테스트 사용자',
    'phoneNumber': '010-1234-5678',
    'address': '서울시 강남구 테헤란로 123',
    'addressDetail': '102동 1201호',
    'profileImageUrl': 'https://via.placeholder.com/150',
    'isPhoneVerified': true,
    'createdAt': Timestamp.now(),
    'updatedAt': Timestamp.now(),
  };
  
  try {
    // 사용자 uid를 document ID로 사용
    await usersRef.doc(currentUser['uid'] as String).set(currentUser);
    print('현재 로그인한 사용자 정보 추가 완료: ${currentUser['name']}');
  } catch (e) {
    print('현재 로그인한 사용자 정보 추가 실패: $e');
  }
} 