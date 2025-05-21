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
  
  // Helper method to process tokens
  Future<void> _processTokens(User user, bool rememberMe) async {
    try {
      final String? idToken = await user.getIdToken(false);
      
      if (idToken != null && idToken.isNotEmpty) {
        await SecureStorage.saveAccessToken(idToken);
        
        // 토큰 만료 시간 계산 및 저장 (Firebase 토큰은 기본적으로 1시간 유효)
        final expiryTime = DateTime.now().add(const Duration(hours: 1));
        await SecureStorage.saveTokenExpiryTime(expiryTime);
        
        print("AuthRepository: ID token and expiry time saved to secure storage");
      }
    } catch (tokenError) {
      print("AuthRepository: Error getting ID token - $tokenError");
      // Don't throw here - we'll continue with login using potentially cached tokens
    }
  }
  
  // Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool rememberMe = false,
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
      
      // Save the "remember me" setting
      await SecureStorage.saveRememberMe(rememberMe);
      print("AuthRepository: Remember me setting saved: $rememberMe");
      
      // Get user data from Firestore
      print("AuthRepository: Fetching user data from Firestore");
      
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        // AUTO-RECOVERY: Create missing Firestore document if one doesn't exist
        if (!userDoc.exists) {
          print("AuthRepository: User document does not exist in Firestore. Creating one now.");
          
          // Create a basic user document using Firebase Auth data
          final now = DateTime.now();
          final userData = UserModel(
            uid: user.uid,
            email: user.email ?? email, // Use the email from credentials if not in user object
            name: user.displayName ?? email.split('@')[0], // Use part of email as name if display name not available
            isPhoneVerified: false,
            createdAt: now,
            updatedAt: now,
          );
          
          // Save to Firestore
          await _firestore.collection('users').doc(user.uid).set(userData.toMap());
          print("AuthRepository: Created new Firestore document for user");
          
          // Process tokens and continue login
          await _processTokens(user, rememberMe);
          await SecureStorage.saveUserId(user.uid);
          
          print("AuthRepository: Login process completed with auto-recovery");
          return userData;
        }
        
        print("AuthRepository: User document found in Firestore");
        
        // Process tokens
        await _processTokens(user, rememberMe);
        await SecureStorage.saveUserId(user.uid);
        
        print("AuthRepository: Login process completed successfully");
        return UserModel.fromDocument(userDoc);
      } catch (e) {
        // Firestore 오류 처리
        print("AuthRepository: Error fetching user data from Firestore: $e");
        
        // Firestore에서 사용자 정보를 가져올 수 없는 경우 로그아웃 처리
        await signOut();
        throw AuthException('사용자 정보를 찾을 수 없습니다. 관리자에게 문의하세요.');
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
    User? firebaseUser;
    UserModel? userData;
    
    try {
      print("AuthRepository: Starting signUpWithEmailAndPassword");
      
      // Step 1: Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        throw AuthException('회원가입에 실패했습니다.');
      }
      
      print("AuthRepository: Firebase Auth user created successfully: ${firebaseUser.uid}");
      
      // Step 2: Create user data for Firestore
      final now = DateTime.now();
      userData = UserModel(
        uid: firebaseUser.uid,
        email: email,
        name: name,
        isPhoneVerified: false,
        createdAt: now,
        updatedAt: now,
      );
      
      // Step 3: Create document in Firestore using transaction for atomicity
      await _firestore.runTransaction((transaction) async {
        // Check if document already exists (should not, but verify)
        final docRef = _firestore.collection('users').doc(firebaseUser!.uid);
        final docSnapshot = await transaction.get(docRef);
        
        if (docSnapshot.exists) {
          print("AuthRepository: User document already exists, using existing data");
          userData = UserModel.fromDocument(docSnapshot);
        } else {
          // Create new document
          transaction.set(docRef, userData!.toMap());
          print("AuthRepository: User document created in Firestore transaction");
        }
      });
      
      print("AuthRepository: Firestore transaction completed successfully");
      
      // Step 4: Process tokens and save user ID
      await _processTokens(firebaseUser, true); // Default to remember me for new users
      await SecureStorage.saveUserId(firebaseUser.uid);
      
      print("AuthRepository: Registration completed successfully");
      return userData!;
    } catch (e) {
      // If we created a Firebase Auth user but failed to create Firestore document,
      // we need to delete the Auth user to maintain consistency
      if (firebaseUser != null && userData != null) {
        try {
          print("AuthRepository: Error during signup, attempting to cleanup Auth user: ${firebaseUser.uid}");
          await firebaseUser.delete();
          print("AuthRepository: Deleted Auth user after Firestore operation failed");
        } catch (deleteError) {
          print("AuthRepository: Failed to delete Auth user after error: $deleteError");
          // Log orphaned auth user for later cleanup
          await _logOrphanedAuthUser(firebaseUser.uid, email);
        }
      }
      
      // Re-throw appropriate error
      if (e is FirebaseAuthException) {
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
      } else {
        throw AuthException('회원가입 중 오류가 발생했습니다: $e');
      }
    }
  }
  
  // Helper method to log orphaned Auth users for later cleanup
  Future<void> _logOrphanedAuthUser(String uid, String email) async {
    try {
      await _firestore.collection('system_logs').doc('orphaned_auth_users').set({
        uid: {
          'email': email,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'orphaned',
        }
      }, SetOptions(merge: true));
      
      print("AuthRepository: Logged orphaned Auth user for cleanup: $uid");
    } catch (e) {
      print("AuthRepository: Failed to log orphaned Auth user: $e");
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
  
  // Check if user is authenticated with valid credentials
  Future<bool> isAuthenticated() async {
    // "로그인 상태 유지" 설정 및 토큰 유효성 확인
    final isValid = await SecureStorage.hasValidTokens();
    
    // 유효하지 않으면 로그아웃 처리
    if (!isValid) {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        print("AuthRepository: Tokens invalid or 'remember me' not set, signing out");
        await signOut();
      }
      return false;
    }
    
    final user = _firebaseAuth.currentUser;
    return user != null;
  }
} 