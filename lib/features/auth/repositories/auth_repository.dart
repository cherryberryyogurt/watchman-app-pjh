import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../../../core/utils/secure_storage.dart';
// import '../../location/repositories/location_tag_repository.dart';

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  // final LocationTagRepository _locationTagRepository;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    // LocationTagRepository? locationTagRepository,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;
  // _locationTagRepository =
  //     locationTagRepository ?? LocationTagRepository();

  // 인증 상태 변화 스트림 제공
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // 사용자 변경 스트림 제공
  Stream<User?> get userChanges => _firebaseAuth.userChanges();

  // LocationTagRepository에 접근하는 getter
  // LocationTagRepository get locationTagRepository => _locationTagRepository;

  // 현재 사용자 가져오기
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null) return null;

      // 토큰 갱신 및 저장
      final idToken = await user.getIdToken(false);
      if (idToken != null && idToken.isNotEmpty) {
        await SecureStorage.saveAccessToken(idToken);
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromDocument(doc);
    } catch (e) {
      debugPrint('❌ AuthRepository: Error getting current user: $e');
      return null;
    }
  }

  // 회원가입
  Future<UserModel> signUp({
    required String name,
    String? phoneNumber,
    String? roadNameAddress,
    String? detailedAddress,
    String? locationAddress,
    String? locationTagId,
    String? locationTagName,
    String locationStatus = 'none',
    String? pendingLocationName,
  }) async {
    try {
      if (kDebugMode) {
        print('🔐 AuthRepository: Starting user sign up');
      }

      // 1. 현재 Firebase 사용자 확인
      final User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw AuthException('Firebase 사용자가 없습니다. 먼저 전화번호 인증을 완료해주세요.');
      }

      // 2. 사용자 데이터 생성
      final userData = {
        'uid': firebaseUser.uid,
        'name': name,
        'phoneNumber': phoneNumber,
        'roadNameAddress': roadNameAddress,
        'detailedAddress': detailedAddress,
        'locationAddress': locationAddress,
        'locationTagId': locationTagId,
        'locationTagName': locationTagName,
        'locationStatus': locationStatus,
        'pendingLocationName': pendingLocationName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 3. Firestore에 사용자 정보 저장
      await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

      // 4. 저장된 사용자 정보 조회
      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      final user = UserModel.fromDocument(doc);

      if (kDebugMode) {
        print('🎉 AuthRepository: User sign up completed: ${user.uid}');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthRepository: Sign up failed: $e');
      }
      throw AuthException('회원가입에 실패했습니다: $e');
    }
  }

  // 사용자 프로필 업데이트
  Future<UserModel> updateUserProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    String? roadNameAddress,
    String? detailedAddress,
    String? locationAddress,
    String? postalCode,
    String? locationTagId,
    String? locationTagName,
    String? locationStatus,
    String? pendingLocationName,
  }) async {
    try {
      if (kDebugMode) {
        print('🔐 AuthRepository: Updating user profile for: $uid');
      }

      // 업데이트할 데이터 준비
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (roadNameAddress != null)
        updateData['roadNameAddress'] = roadNameAddress;
      if (detailedAddress != null)
        updateData['detailedAddress'] = detailedAddress;
      if (locationAddress != null)
        updateData['locationAddress'] = locationAddress;
      if (postalCode != null) updateData['postalCode'] = postalCode;
      if (locationTagId != null) updateData['locationTagId'] = locationTagId;
      if (locationTagName != null)
        updateData['locationTagName'] = locationTagName;
      if (locationStatus != null) updateData['locationStatus'] = locationStatus;
      if (pendingLocationName != null)
        updateData['pendingLocationName'] = pendingLocationName;

      // Firestore 업데이트
      await _firestore.collection('users').doc(uid).update(updateData);

      // 업데이트된 사용자 정보 조회
      final doc = await _firestore.collection('users').doc(uid).get();
      final user = UserModel.fromDocument(doc);

      if (kDebugMode) {
        print('🎉 AuthRepository: User profile updated: ${user.uid}');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthRepository: Profile update failed: $e');
      }
      throw AuthException('프로필 업데이트에 실패했습니다: $e');
    }
  }

  // 기존 사용자 프로필 저장
  Future<UserModel> saveUserProfileForExistingUser({
    required String uid,
    required String name,
    String? phoneNumber,
    String? roadNameAddress,
    String? detailedAddress,
    String? locationAddress,
    String? postalCode,
    String? locationTagId,
    String? locationTagName,
    String? locationStatus,
    String? pendingLocationName,
  }) async {
    try {
      if (kDebugMode) {
        print('🔐 AuthRepository: Saving profile for existing user: $uid');
      }

      // 사용자 데이터 생성
      final userData = {
        'uid': uid,
        'name': name,
        'phoneNumber': phoneNumber,
        'roadNameAddress': roadNameAddress,
        'detailedAddress': detailedAddress,
        'locationAddress': locationAddress,
        'postalCode': postalCode,
        'locationTagId': locationTagId,
        'locationTagName': locationTagName,
        'locationStatus': locationStatus ?? 'none',
        'pendingLocationName': pendingLocationName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Firestore에 사용자 정보 저장 (덮어쓰기)
      await _firestore.collection('users').doc(uid).set(userData);

      // 저장된 사용자 정보 조회
      final doc = await _firestore.collection('users').doc(uid).get();
      final user = UserModel.fromDocument(doc);

      if (kDebugMode) {
        print('🎉 AuthRepository: Existing user profile saved: ${user.uid}');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthRepository: Save existing user profile failed: $e');
      }
      throw AuthException('기존 사용자 프로필 저장에 실패했습니다: $e');
    }
  }

  // 전화번호로 사용자 존재 여부 확인
  Future<bool> checkUserExistsByPhoneNumber(String phoneNumber) async {
    try {
      if (kDebugMode) {
        print('🔐 AuthRepository: Checking user exists by phone: $phoneNumber');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      final exists = querySnapshot.docs.isNotEmpty;

      if (kDebugMode) {
        print('🔐 AuthRepository: User exists: $exists');
      }

      return exists;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthRepository: Check user exists failed: $e');
      }
      throw AuthException('사용자 조회 중 오류가 발생했습니다: $e');
    }
  }

  // Firestore에서 사용자 모델 가져오기
  Future<UserModel?> getUserModelFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromDocument(doc);
    } catch (e) {
      debugPrint('❌ AuthRepository: Error getting user from Firestore: $e');
      return null;
    }
  }

  // 현재 Firebase User 가져오기
  User? getCurrentFirebaseUser() {
    return _firebaseAuth.currentUser;
  }

  // Firebase User의 ID 토큰 가져오기
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final idToken = await user.getIdToken(forceRefresh);
      if (idToken != null && idToken.isNotEmpty) {
        await SecureStorage.saveAccessToken(idToken);
      }
      return idToken;
    } catch (e) {
      debugPrint('❌ AuthRepository: Error getting id token: $e');
      return null;
    }
  }

  // 토큰 갱신
  Future<String?> refreshToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException('로그인이 필요합니다.');
      }

      final String? idToken = await user.getIdToken(true); // 강제 갱신
      if (idToken == null || idToken.isEmpty) {
        throw AuthException('인증 토큰을 갱신하는 데 실패했습니다.');
      }

      await SecureStorage.saveAccessToken(idToken);
      return idToken;
    } catch (e) {
      debugPrint('❌ AuthRepository: Token refresh failed: $e');
      throw AuthException('토큰 갱신 중 오류가 발생했습니다: $e');
    }
  }

  // 인증 상태 확인
  Future<bool> isAuthenticated() async {
    try {
      final isValid = await SecureStorage.hasValidTokens();
      if (!isValid) {
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          await signOut();
        }
        return false;
      }

      final user = _firebaseAuth.currentUser;
      return user != null;
    } catch (e) {
      debugPrint('❌ AuthRepository: Error checking authentication: $e');
      return false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await SecureStorage.deleteAllTokens();
    } catch (e) {
      debugPrint('❌ AuthRepository: Sign out failed: $e');
      throw AuthException('로그아웃에 실패했습니다: $e');
    }
  }
}
