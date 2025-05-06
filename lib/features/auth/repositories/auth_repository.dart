import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../../../core/utils/secure_storage.dart';

class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => message;
}

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : 
    _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
    _firestore = firestore ?? FirebaseFirestore.instance;
  
  // 인증 상태 변화 스트림 제공
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  // 사용자 변경 스트림 제공 (토큰 변경 등 더 자세한 변경 사항 감지)
  Stream<User?> get userChanges => _firebaseAuth.userChanges();
  
  // Firestore에서 사용자 모델 가져오기
  Future<UserModel?> getUserModelFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return UserModel.fromDocument(doc);
    } catch (e) {
      debugPrint('Error getting user from Firestore: $e');
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
      
      if (user == null) {
        return null;
      }
      
      final idToken = await user.getIdToken(forceRefresh);
      if (idToken != null && idToken.isNotEmpty) {
        await SecureStorage.saveAccessToken(idToken);
      }
      return idToken;
    } catch (e) {
      debugPrint('Error getting id token: $e');
      return null;
    }
  }
  
  // Get current user from Firestore
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      
      if (user == null) {
        return null;
      }
      
      // 토큰 갱신 및 저장 추가
      final idToken = await user.getIdToken(false);
      if (idToken != null && idToken.isNotEmpty) {
        await SecureStorage.saveAccessToken(idToken);
      }
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return UserModel.fromDocument(doc);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }
  
  // Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print("AuthRepository: Starting signInWithEmailAndPassword");
      
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("AuthRepository: Firebase Auth signInWithEmailAndPassword successful");
      
      final user = userCredential.user;
      
      if (user == null) {
        print("AuthRepository: User is null after signInWithEmailAndPassword");
        throw AuthException('로그인에 실패했습니다.');
      }
      
      print("AuthRepository: User authenticated successfully: ${user.uid}");
      
      // Get user data from Firestore
      print("AuthRepository: Fetching user data from Firestore");
      
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          print("AuthRepository: User document does not exist in Firestore");
          throw AuthException('사용자 정보를 찾을 수 없습니다.');
        }
        
        print("AuthRepository: User document found in Firestore");
        
        // ID 토큰 가져오기 및 저장
        try {
          final String? idToken = await user.getIdToken(false);
          
          if (idToken != null && idToken.isNotEmpty) {
            await SecureStorage.saveAccessToken(idToken);
            print("AuthRepository: ID token saved to secure storage");
          }
        } catch (tokenError) {
          print("AuthRepository: Error getting ID token - $tokenError");
        }
        
        // In a real app, you would get a refresh token from your backend
        await SecureStorage.saveUserId(user.uid);
        
        print("AuthRepository: Login process completed successfully");
        return UserModel.fromDocument(userDoc);
      } catch (e) {
        // Firestore 오류 처리
        print("AuthRepository: Error fetching user data from Firestore: $e");
        
        // Firestore에서 사용자 정보를 가져올 수 없는 경우, Firebase Auth 정보로 최소한의 모델 생성
        final now = DateTime.now();
        return UserModel(
          uid: user.uid,
          email: user.email ?? email,
          name: user.displayName ?? email.split('@')[0],
          isPhoneVerified: user.phoneNumber != null,
          createdAt: now,
          updatedAt: now,
        );
      }
    } on FirebaseAuthException catch (e) {
      print("AuthRepository: FirebaseAuthException during login: ${e.code} - ${e.message}");
      switch (e.code) {
        case 'user-not-found':
          throw AuthException('해당 이메일로 등록된 사용자가 없습니다.');
        case 'wrong-password':
          throw AuthException('비밀번호가 일치하지 않습니다.');
        case 'invalid-email':
          throw AuthException('올바른 이메일 형식이 아닙니다.');
        case 'user-disabled':
          throw AuthException('해당 계정은 비활성화 되었습니다.');
        default:
          throw AuthException('로그인에 실패했습니다: ${e.message}');
      }
    } catch (e) {
      print("AuthRepository: General exception during login: $e");
      throw AuthException('로그인 중 오류가 발생했습니다: $e');
    }
  }
  
  // Sign up with email and password
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Check if email already exists
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      
      if (user == null) {
        throw AuthException('회원가입에 실패했습니다.');
      }
      
      // Create user data in Firestore
      final now = DateTime.now();
      final userData = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        isPhoneVerified: false,
        createdAt: now,
        updatedAt: now,
      );
      
      await _firestore.collection('users').doc(user.uid).set(userData.toMap());
      
      // 수정된 부분: getIdToken() 호출 방식 변경
      try {
        final String? idToken = await user.getIdToken(false);
        
        if (idToken != null && idToken.isNotEmpty) {
          await SecureStorage.saveAccessToken(idToken);
        } else {
          // 토큰을 가져올 수 없으면 임시 토큰 사용
          final tempToken = "temp-token-${user.uid}-${DateTime.now().millisecondsSinceEpoch}";
          await SecureStorage.saveAccessToken(tempToken);
        }
      } catch (tokenError) {
        print("Error getting ID token during signup: $tokenError");
        // 토큰 오류 발생 시 임시 토큰 사용
        final tempToken = "temp-token-${user.uid}-${DateTime.now().millisecondsSinceEpoch}";
        await SecureStorage.saveAccessToken(tempToken);
      }
      
      // In a real app, you would get a refresh token from your backend
      await SecureStorage.saveRefreshToken('refresh-token-placeholder');
      await SecureStorage.saveUserId(user.uid);
      
      return userData;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw AuthException('이미 사용 중인 이메일입니다.');
        case 'invalid-email':
          throw AuthException('올바른 이메일 형식이 아닙니다.');
        case 'weak-password':
          throw AuthException('비밀번호가 너무 약합니다.');
        case 'operation-not-allowed':
          throw AuthException('이메일/비밀번호 로그인이 비활성화되어 있습니다.');
        default:
          throw AuthException('회원가입에 실패했습니다: ${e.message}');
      }
    } catch (e) {
      throw AuthException('회원가입 중 오류가 발생했습니다: $e');
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await SecureStorage.deleteAllTokens();
    } catch (e) {
      throw AuthException('로그아웃 중 오류가 발생했습니다: $e');
    }
  }
  
  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw AuthException('올바른 이메일 형식이 아닙니다.');
        case 'user-not-found':
          throw AuthException('해당 이메일로 등록된 사용자가 없습니다.');
        default:
          throw AuthException('비밀번호 재설정 이메일 발송에 실패했습니다: ${e.message}');
      }
    } catch (e) {
      throw AuthException('비밀번호 재설정 이메일 발송 중 오류가 발생했습니다: $e');
    }
  }
  
  // Update user profile
  Future<UserModel> updateUserProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    String? address,
    String? addressDetail,
    String? profileImageUrl,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        throw AuthException('사용자 정보를 찾을 수 없습니다.');
      }
      
      final userData = UserModel.fromDocument(userDoc);
      
      final updatedData = userData.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        address: address,
        addressDetail: addressDetail,
        profileImageUrl: profileImageUrl,
        updatedAt: DateTime.now(),
      );
      
      await userRef.update(updatedData.toMap());
      
      return updatedData;
    } catch (e) {
      throw AuthException('프로필 업데이트 중 오류가 발생했습니다: $e');
    }
  }
  
  // Set phone number verified
  Future<UserModel> setPhoneVerified({
    required String uid,
    required bool verified,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        throw AuthException('사용자 정보를 찾을 수 없습니다.');
      }
      
      final userData = UserModel.fromDocument(userDoc);
      
      final updatedData = userData.copyWith(
        isPhoneVerified: verified,
        updatedAt: DateTime.now(),
      );
      
      await userRef.update({
        'isPhoneVerified': verified,
        'updatedAt': DateTime.now(),
      });
      
      return updatedData;
    } catch (e) {
      throw AuthException('전화번호 인증 상태 업데이트 중 오류가 발생했습니다: $e');
    }
  }
  
  // Refresh token
  Future<String> refreshToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      
      if (user == null) {
        throw AuthException('로그인이 필요합니다.');
      }
      
      // 수정된 부분: getIdToken() 호출 방식 변경
      try {
        final String? idToken = await user.getIdToken(true); // 강제 갱신
        
        if (idToken == null || idToken.isEmpty) {
          throw AuthException('인증 토큰을 갱신하는 데 실패했습니다.');
        }
        
        await SecureStorage.saveAccessToken(idToken);
        return idToken;
      } catch (tokenError) {
        print("Error refreshing token: $tokenError");
        // 임시 대체 토큰 사용
        final tempToken = "temp-refresh-${user.uid}-${DateTime.now().millisecondsSinceEpoch}";
        await SecureStorage.saveAccessToken(tempToken);
        return tempToken;
      }
    } catch (e) {
      throw AuthException('토큰 갱신 중 오류가 발생했습니다: $e');
    }
  }
} 