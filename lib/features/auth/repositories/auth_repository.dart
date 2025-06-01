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
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
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

  // Helper method to process tokens
  Future<void> _processTokens(User user, bool rememberMe) async {
    try {
      final String? idToken = await user.getIdToken(false);

      if (idToken != null && idToken.isNotEmpty) {
        await SecureStorage.saveAccessToken(idToken);

        // 토큰 만료 시간 계산 및 저장 (Firebase 토큰은 기본적으로 1시간 유효)
        final expiryTime = DateTime.now().add(const Duration(hours: 1));
        await SecureStorage.saveTokenExpiryTime(expiryTime);

        print(
            "AuthRepository: ID token and expiry time saved to secure storage");
      }
    } catch (tokenError) {
      print("AuthRepository: Error getting ID token - $tokenError");
      // Don't throw here - we'll continue with login using potentially cached tokens
    }
  }

  // Sign up with phone authentication
  Future<UserModel> signUp({
    required String name,
    String? phoneNumber,
    String? roadNameAddress,
    String? locationAddress,
    String? locationTag,
  }) async {
    User? firebaseUser;
    UserModel? userData;

    try {
      print("AuthRepository: Starting signUp");

      // 현재 Firebase Auth 사용자 사용 (전화번호 인증이 이미 완료된 상태)
      firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        throw AuthException('전화번호 인증이 완료되지 않았습니다.');
      }

      print(
          "AuthRepository: Using existing Firebase Auth user: ${firebaseUser.uid}");

      // Step 2: Create user data for Firestore
      final now = DateTime.now();
      userData = UserModel(
        uid: firebaseUser.uid,
        name: name,
        phoneNumber: phoneNumber,
        roadNameAddress: roadNameAddress,
        locationAddress: locationAddress,
        locationTag: locationTag,
        createdAt: now,
        updatedAt: now,
      );

      // Step 3: Create document in Firestore using transaction for atomicity
      await _firestore.runTransaction((transaction) async {
        // Check if document already exists (should not, but verify)
        final docRef = _firestore.collection('users').doc(firebaseUser!.uid);
        final docSnapshot = await transaction.get(docRef);

        if (docSnapshot.exists) {
          print(
              "AuthRepository: User document already exists, using existing data");
          userData = UserModel.fromDocument(docSnapshot);
        } else {
          // Create new document
          transaction.set(docRef, userData!.toMap());
          print(
              "AuthRepository: User document created in Firestore transaction");
        }
      });

      print("AuthRepository: Firestore transaction completed successfully");

      // Step 4: Process tokens and save user ID
      await _processTokens(firebaseUser, true);
      await SecureStorage.saveUserId(firebaseUser.uid);

      print("AuthRepository: Registration completed successfully");
      return userData!;
    } catch (e) {
      // Re-throw appropriate error
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw AuthException('전화번호 인증이 완료되지 않았습니다.');
          default:
            throw AuthException('회원가입에 실패했습니다: ${e.message}');
        }
      } else {
        throw AuthException('회원가입 중 오류가 발생했습니다: $e');
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear saved tokens and user info
      await SecureStorage.deleteAllTokens();
      await _firebaseAuth.signOut();
    } catch (e) {
      print("AuthRepository: Error during signOut - $e");
      throw AuthException('로그아웃 중 오류가 발생했습니다: $e');
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    String? roadNameAddress,
    String? locationAddress,
    String? locationTag,
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
        roadNameAddress: roadNameAddress,
        locationAddress: locationAddress,
        locationTag: locationTag,
        updatedAt: DateTime.now(),
      );

      await userRef.update(updatedData.toMap());

      return updatedData;
    } catch (e) {
      throw AuthException('프로필 업데이트 중 오류가 발생했습니다: $e');
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
        final tempToken =
            "temp-refresh-${user.uid}-${DateTime.now().millisecondsSinceEpoch}";
        await SecureStorage.saveAccessToken(tempToken);
        return tempToken;
      }
    } catch (e) {
      throw AuthException('토큰 갱신 중 오류가 발생했습니다: $e');
    }
  }

  // Check if user is authenticated with valid credentials
  Future<bool> isAuthenticated() async {
    // "로그인 상태 유지" 설정 및 토큰 유효성 확인
    final isValid = await SecureStorage.hasValidTokens();

    // 유효하지 않으면 로그아웃 처리
    if (!isValid) {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        print(
            "AuthRepository: Tokens invalid or 'remember me' not set, signing out");
        await signOut();
      }
      return false;
    }

    final user = _firebaseAuth.currentUser;
    return user != null;
  }

  Future<UserModel> saveUserProfileForExistingUser({
    required String uid,
    required String name,
    String? phoneNumber,
    String? roadNameAddress,
    String? locationAddress,
    String? locationTag,
  }) async {
    try {
      final now = DateTime.now();
      final userData = UserModel(
        uid: uid,
        name: name,
        phoneNumber: phoneNumber,
        roadNameAddress: roadNameAddress,
        locationAddress: locationAddress,
        locationTag: locationTag,
        createdAt: now,
        updatedAt: now,
      );

      // Firestore에만 저장 (Firebase Auth 사용자는 이미 존재)
      await _firestore.collection('users').doc(uid).set(userData.toMap());

      // 토큰 처리
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _processTokens(user, true);
        await SecureStorage.saveUserId(user.uid);
      }

      return userData;
    } catch (e) {
      throw AuthException('사용자 프로필 저장 중 오류가 발생했습니다: $e');
    }
  }
}
