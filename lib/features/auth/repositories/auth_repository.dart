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

  // 전화번호로 사용자 존재 여부 확인
  Future<bool> checkUserExistsByPhoneNumber(String phoneNumber) async {
    try {
      if (kDebugMode) {
        print(
            'AuthRepository: checkUserExistsByPhoneNumber() - 조회 중: $phoneNumber');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      final exists = querySnapshot.docs.isNotEmpty;

      if (kDebugMode) {
        print('AuthRepository: checkUserExistsByPhoneNumber() - 결과: $exists');
      }

      return exists;
    } catch (e) {
      if (kDebugMode) {
        print('AuthRepository: checkUserExistsByPhoneNumber() - 에러: $e');
      }
      throw AuthException('사용자 조회 중 오류가 발생했습니다: $e');
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
    String? locationTagId,
    String? locationTagName,
    String locationStatus = 'none',
    String? pendingLocationName,
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
        locationTagId: locationTagId,
        locationTagName: locationTagName,
        locationStatus: locationStatus,
        pendingLocationName: pendingLocationName,
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
    String? locationTagId,
    String? locationTagName,
    String? locationStatus,
    String? pendingLocationName,
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
        locationTagId: locationTagId,
        locationTagName: locationTagName,
        locationStatus: locationStatus,
        pendingLocationName: pendingLocationName,
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
    String? locationTagId,
    String? locationTagName,
    String locationStatus = 'none',
    String? pendingLocationName,
  }) async {
    try {
      if (kDebugMode) {
        print('🏪 AuthRepository: saveUserProfileForExistingUser() - 시작');
        print('🏪 AuthRepository: 입력 파라미터:');
        print('  - uid: $uid');
        print('  - name: $name');
        print('  - phoneNumber: $phoneNumber');
        print('  - roadNameAddress: $roadNameAddress');
        print('  - locationAddress: $locationAddress');
        print('  - locationTagId: $locationTagId');
        print('  - locationTagName: $locationTagName');
        print('  - locationStatus: $locationStatus');
        print('  - pendingLocationName: $pendingLocationName');
      }

      // 🔐 1단계: Firebase Auth 사용자 검증 및 토큰 갱신
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw AuthException('Firebase Auth 사용자가 존재하지 않습니다.');
      }

      if (currentUser.uid != uid) {
        throw AuthException('요청된 UID와 현재 인증된 사용자의 UID가 일치하지 않습니다.');
      }

      if (kDebugMode) {
        print('🏪 AuthRepository: Firebase Auth 사용자 확인 완료: ${currentUser.uid}');
        print('🏪 AuthRepository: 사용자 이메일: ${currentUser.email}');
        print('🏪 AuthRepository: 사용자 전화번호: ${currentUser.phoneNumber}');
        print('🏪 AuthRepository: 이메일 인증 상태: ${currentUser.emailVerified}');
      }

      // 🔄 2단계: ID 토큰 강제 갱신 - Firestore 쓰기 전에 반드시 수행
      try {
        if (kDebugMode) {
          print('🏪 AuthRepository: ID 토큰 강제 갱신 시작...');
        }

        final idToken = await currentUser.getIdToken(true); // 강제 갱신

        if (idToken == null || idToken.isEmpty) {
          throw AuthException('ID 토큰 갱신에 실패했습니다.');
        }

        if (kDebugMode) {
          print('✅ AuthRepository: ID 토큰 갱신 성공 (길이: ${idToken.length})');
        }

        // SecureStorage에도 저장
        await SecureStorage.saveAccessToken(idToken);
      } catch (tokenError) {
        if (kDebugMode) {
          print('❌ AuthRepository: ID 토큰 갱신 실패: $tokenError');
        }
        throw AuthException('사용자 인증 토큰 갱신에 실패했습니다. 다시 로그인해주세요.');
      }

      // 🔄 3단계: 잠시 대기 후 UserModel 생성
      await Future.delayed(const Duration(milliseconds: 500)); // 토큰 동기화 대기

      final now = DateTime.now();

      if (kDebugMode) {
        print('🏪 AuthRepository: UserModel 생성 중...');
      }

      final userData = UserModel(
        uid: uid,
        name: name,
        phoneNumber: phoneNumber,
        roadNameAddress: roadNameAddress,
        locationAddress: locationAddress,
        locationTagId: locationTagId,
        locationTagName: locationTagName,
        locationStatus: locationStatus,
        pendingLocationName: pendingLocationName,
        createdAt: now,
        updatedAt: now,
      );

      if (kDebugMode) {
        print('🏪 AuthRepository: UserModel 생성 완료');
        print('🏪 AuthRepository: Firestore 쓰기 시작...');
        print('🏪 AuthRepository: 대상 경로: users/$uid');
      }

      // 📝 4단계: Firestore에 사용자 정보 저장 (재시도 로직 포함)
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          if (kDebugMode) {
            print(
                '🏪 AuthRepository: Firestore 쓰기 시도 ${retryCount + 1}/$maxRetries');
          }

          await _firestore.collection('users').doc(uid).set(userData.toMap());

          if (kDebugMode) {
            print('✅ AuthRepository: Firestore 문서 쓰기 성공!');
          }
          break; // 성공 시 루프 탈출
        } catch (firestoreError) {
          retryCount++;

          if (kDebugMode) {
            print(
                '❌ AuthRepository: Firestore 쓰기 실패 (시도 $retryCount/$maxRetries): $firestoreError');
          }

          if (retryCount >= maxRetries) {
            // 최대 재시도 횟수 도달
            if (kDebugMode) {
              print('❌ AuthRepository: 최대 재시도 횟수 도달, 최종 실패');
              print('❌ AuthRepository: 에러 타입: ${firestoreError.runtimeType}');
              print('❌ AuthRepository: 에러 메시지: $firestoreError');
            }
            throw firestoreError;
          }

          // 재시도 전 대기
          await Future.delayed(Duration(milliseconds: 1000 * retryCount));

          // 토큰 재갱신 시도
          try {
            await currentUser.getIdToken(true);
            if (kDebugMode) {
              print('🔄 AuthRepository: 재시도를 위한 토큰 재갱신 완료');
            }
          } catch (retryTokenError) {
            if (kDebugMode) {
              print('⚠️ AuthRepository: 토큰 재갱신 실패: $retryTokenError');
            }
          }
        }
      }

      // 🔐 5단계: 토큰 처리 및 세션 저장
      if (kDebugMode) {
        print('🏪 AuthRepository: 토큰 처리 시작...');
      }

      try {
        await _processTokens(currentUser, true);
        await SecureStorage.saveUserId(currentUser.uid);

        if (kDebugMode) {
          print('✅ AuthRepository: 토큰 처리 완료');
        }
      } catch (tokenError) {
        if (kDebugMode) {
          print('⚠️ AuthRepository: 토큰 처리 실패 (계속 진행): $tokenError');
        }
        // 토큰 처리 실패해도 사용자 생성은 성공으로 처리
      }

      if (kDebugMode) {
        print('🎉 AuthRepository: saveUserProfileForExistingUser() 완료!');
      }

      return userData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthRepository: saveUserProfileForExistingUser() 실패');
        print('❌ AuthRepository: 에러 타입: ${e.runtimeType}');
        print('❌ AuthRepository: 에러 메시지: $e');
        print('❌ AuthRepository: Stack trace: ${StackTrace.current}');

        if (e.toString().contains('permission-denied')) {
          print('❌ AuthRepository: Firestore 권한 오류 감지');
          print(
              '❌ AuthRepository: 현재 Auth 사용자: ${_firebaseAuth.currentUser?.uid}');
          print('❌ AuthRepository: 시도한 문서 경로: users/$uid');

          // 상세 디버깅 정보
          final user = _firebaseAuth.currentUser;
          if (user != null) {
            try {
              final token = await user.getIdToken();
              print('❌ AuthRepository: 현재 토큰 존재: ${token != null}');
              print('❌ AuthRepository: 토큰 길이: ${token?.length ?? 0}');
            } catch (debugTokenError) {
              print('❌ AuthRepository: 토큰 디버깅 실패: $debugTokenError');
            }
          }
        }
      }

      throw AuthException('사용자 프로필 저장 중 오류가 발생했습니다: $e');
    }
  }
}
