import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import 'add_dummy_users.dart';
import 'add_dummy_products.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Firestore 초기화
  final firestore = FirebaseFirestore.instance;
  
  // 1. 먼저 더미 사용자 추가
  print('===== 더미 사용자 추가 시작 =====');
  await addDummyUsers(firestore);
  print('===== 더미 사용자 추가 완료 =====\n');
  
  // 2. 더미 상품 추가
  print('===== 더미 상품 추가 시작 =====');
  await addDummyProducts(firestore);
  print('===== 더미 상품 추가 완료 =====\n');
  
  print('모든 더미 데이터가 성공적으로 추가되었습니다.');
} 