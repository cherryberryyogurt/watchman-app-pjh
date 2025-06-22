import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../../../core/utils/secure_storage.dart';
import '../services/auth_integrity_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'auth_state.g.dart';

// Uncomment and implement the AuthStatus enum
enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

// 세부 작업 타입을 정의
enum AuthActionType {
  none,
  login,
  register,
  passwordReset,
  updateProfile,
}

// AsyncValue와 함께 사용될 단순화된 AuthState
class AuthState {
  final UserModel? user;
  final AuthActionType currentAction;
  final bool isPasswordResetSuccess;
  final AuthStatus status;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.user,
    this.currentAction = AuthActionType.none,
    this.isPasswordResetSuccess = false,
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.isLoading = false,
  });

  // copyWith는 필요에 따라 유지하거나 AsyncNotifier 내부 로직으로 대체
  AuthState copyWith({
    UserModel? user,
    AuthActionType? currentAction,
    bool? isPasswordResetSuccess,
    AuthStatus? status,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      user: user ?? this.user,
      currentAction: currentAction ?? this.currentAction,
      isPasswordResetSuccess:
          isPasswordResetSuccess ?? this.isPasswordResetSuccess,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// AuthRepository Provider
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

// AuthIntegrityService Provider
@riverpod
AuthIntegrityService authIntegrityService(Ref ref) {
  return AuthIntegrityService.instance;
}

// Auth 상태 노티파이어
@riverpod
class Auth extends _$Auth {
  // AuthRepository와 AuthIntegrityService를 ref를 통해 가져옴
  late final AuthRepository _authRepository;
  late final AuthIntegrityService _integrityService;
  // StreamSubscription<firebase_auth.User?>? _authStateSubscription;

  @override
  Stream<AuthState> build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _integrityService = ref.watch(authIntegrityServiceProvider);

    if (kDebugMode) {
      _integrityService.startPeriodicChecks(interval: const Duration(hours: 6));
      // AsyncNotifier가 dispose될 때 체크를 중지하도록 설정
      ref.onDispose(() {
        _integrityService.stopPeriodicChecks();
      });
    }

    return _authRepository.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        if (kDebugMode) {
          print('🔑 Firebase User is null - returning unauthenticated state');
        }
        return AuthState(user: null, status: AuthStatus.unauthenticated);
      }

      try {
        final rememberMe = await SecureStorage.getRememberMe();
        if (!rememberMe) {
          if (kDebugMode) {
            print('🔑 Remember me is false - returning unauthenticated state');
          }
          return AuthState(user: null, status: AuthStatus.unauthenticated);
        }

        // 🔐 Phone Auth 사용자인지 확인하고 적절한 인증 검사 수행
        final isPhoneAuth = await SecureStorage.isPhoneAuthUser();
        bool isAuthValid = false;

        if (isPhoneAuth) {
          // Phone Auth 사용자인 경우 세션 유효성 검사
          isAuthValid = await SecureStorage.isPhoneAuthSessionValid();
          if (kDebugMode) {
            print('🔑 Phone Auth Session Valid: $isAuthValid');
          }

          // 추가 검사: 최근 생성된 사용자인 경우 세션 연장
          final currentUser = await _authRepository.getCurrentUser();
          if (currentUser != null) {
            final now = DateTime.now();
            final timeDiff = now.difference(currentUser.createdAt);
            if (timeDiff.inMinutes <= 5) {
              if (kDebugMode) {
                print('🔑 Recently created user - extending session');
              }
              isAuthValid = true;
            }
          }
        } else {
          // 기존 email+password 사용자인 경우 토큰 유효성 검사
          isAuthValid = await SecureStorage.isTokenValid();
          if (kDebugMode) {
            print('🔑 Token Valid: $isAuthValid');
          }
        }

        // Firebase Auth 토큰 갱신 시도
        try {
          await _authRepository.getIdToken(true);
          if (kDebugMode) {
            print('🔑 Firebase token refreshed successfully');
          }
        } catch (e) {
          if (kDebugMode) {
            print('🔑 Firebase token refresh failed: $e');
          }
          // 토큰 갱신 실패해도 계속 진행
        }

        final userModel =
            await _authRepository.getUserModelFromFirestore(firebaseUser.uid);
        if (userModel != null) {
          if (kDebugMode) {
            print('🔑 User model loaded successfully: ${userModel.name}');
          }
          return AuthState(user: userModel, status: AuthStatus.authenticated);
        } else {
          if (kDebugMode) {
            print('🔑 User model not found in Firestore');
          }
          throw Exception('사용자 프로필 정보를 찾을 수 없습니다.');
        }
      } catch (e, s) {
        if (kDebugMode) {
          print('🔑 Error in auth state processing: $e');
        }
        throw Exception('인증 상태 처리 중 오류: ${e.toString()}');
      }
    }).handleError((error, stackTrace) {
      if (kDebugMode) {
        print('🔑 AuthState handleError: $error');
      }
      return AuthState(
          user: null, status: AuthStatus.error, errorMessage: error.toString());
    });
  }

  // 🔥 Auth State 강제 새로고침 기능 추가
  Future<void> refreshAuthState() async {
    if (kDebugMode) {
      print('🔑 Refreshing auth state...');
    }

    try {
      final currentUser = await _authRepository.getCurrentUser();

      if (currentUser != null) {
        // Phone Auth 사용자라면 세션 갱신
        final isPhoneAuth = await SecureStorage.isPhoneAuthUser();
        if (isPhoneAuth) {
          await SecureStorage.savePhoneAuthSession();
          if (kDebugMode) {
            print('🔑 Phone auth session refreshed');
          }
        }

        state = AsyncValue.data(
            AuthState(user: currentUser, status: AuthStatus.authenticated));

        if (kDebugMode) {
          print('🔑 Auth state refreshed successfully');
        }
      } else {
        state = AsyncValue.data(
            AuthState(user: null, status: AuthStatus.unauthenticated));
        if (kDebugMode) {
          print('🔑 No current user found - set to unauthenticated');
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('🔑 Error refreshing auth state: $e');
      }
      await _integrityService.logAuthError(
        operation: 'refreshAuthState',
        errorMessage: e.toString(),
        additionalData: {'stackTrace': s.toString()},
      );
      state = AsyncValue.error(e, s);
    }
  }

  // 사용자 정보 초기 로드 메소드 추가
  Future<void> loadCurrentUser() async {
    if (kDebugMode) {
      print('🔑 Loading current user...');
    }

    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser != null) {
        state = AsyncValue.data(
            AuthState(user: currentUser, status: AuthStatus.authenticated));
        if (kDebugMode) {
          print('🔑 Current user loaded successfully: ${currentUser.name}');
        }
      } else {
        state = AsyncValue.data(
            AuthState(user: null, status: AuthStatus.unauthenticated));
        if (kDebugMode) {
          print('🔑 No current user found');
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('🔑 Error loading current user: $e');
      }
      await _integrityService.logAuthError(
        operation: 'loadCurrentUser',
        errorMessage: e.toString(),
        additionalData: {'stackTrace': s.toString()},
      );
      state = AsyncValue.error(e, s);
    }
  }

  // 로그인 메소드 - 전화번호 인증으로 변경
  Future<void> signInWithPhoneNumber(
      String verificationId, String smsCode) async {
    if (kDebugMode) {
      print('🔑 Signing in with phone number...');
    }

    try {
      // PhoneAuthCredential 생성
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Firebase Auth 로그인 - 직접 Firebase Auth 사용
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('로그인에 실패했습니다.');
      }

      if (kDebugMode) {
        print(
            '🔑 Firebase phone auth successful for user: ${firebaseUser.uid}');
      }

      // Firestore에서 사용자 정보 확인
      final userModel =
          await _authRepository.getUserModelFromFirestore(firebaseUser.uid);

      if (userModel == null) {
        // 신규 사용자인 경우 - 회원가입이 필요함을 알림
        if (kDebugMode) {
          print('🔑 New user detected - signup required');
        }
        throw Exception('신규 사용자입니다. 회원가입을 완료해주세요.');
      }

      // 기존 사용자인 경우 로그인 완료
      // 🔐 Phone Auth 사용자로 설정하고 세션 저장
      await SecureStorage.setPhoneAuthUser(true);
      await SecureStorage.savePhoneAuthSession();
      await SecureStorage.saveRememberMe(true);

      if (kDebugMode) {
        print('🔑 Phone auth login completed for user: ${userModel.name}');
      }

      state = AsyncValue.data(
          AuthState(user: userModel, status: AuthStatus.authenticated));
    } catch (e, s) {
      if (kDebugMode) {
        print('🔑 Phone auth login error: $e');
      }
      state = AsyncValue.error(e, s);
    }
  }

  // 회원가입 메소드 - 전화번호 인증 완료 후 호출
  Future<void> signUp(String name, String? phone, String? roadNameAddress,
      String? locationAddress, String? locationTag) async {
    if (kDebugMode) {
      print('🔑 Starting signup process for user: $name');
    }

    try {
      // 전화번호 인증이 회원가입 과정 중 마지막에 완료된 상태
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        throw Exception('전화번호 인증이 완료되지 않았습니다.');
      }

      if (kDebugMode) {
        print('🔑 Firebase user confirmed: ${firebaseUser.uid}');
      }

      // 기존 사용자인지 확인
      final existingUser =
          await _authRepository.getUserModelFromFirestore(firebaseUser.uid);
      if (existingUser != null) {
        // 이미 존재하는 사용자인 경우 해당 정보로 로그인 처리
        if (kDebugMode) {
          print('🔑 Existing user found: ${existingUser.name}');
        }
        await SecureStorage.savePhoneAuthSession();
        await SecureStorage.saveRememberMe(true);

        state = AsyncValue.data(
            AuthState(user: existingUser, status: AuthStatus.authenticated));
        return;
      }

      // 신규 사용자인 경우 Firestore에 사용자 정보 저장
      final user = await _authRepository.saveUserProfileForExistingUser(
        uid: firebaseUser.uid,
        name: name,
        phoneNumber: phone,
        roadNameAddress: roadNameAddress,
        locationAddress: locationAddress,
        locationTagId: null,
        locationTagName: null,
        locationStatus: 'none',
        pendingLocationName: null,
      );

      // 🔐 Phone Auth 사용자로 설정하고 세션 저장
      await SecureStorage.setPhoneAuthUser(true);
      await SecureStorage.savePhoneAuthSession();
      await SecureStorage.saveRememberMe(true);

      if (kDebugMode) {
        print('🔑 Signup completed successfully for user: ${user.name}');
      }

      state = AsyncValue.data(
          AuthState(user: user, status: AuthStatus.authenticated));
    } catch (e, s) {
      if (kDebugMode) {
        print('🔑 Signup error: $e');
      }
      state = AsyncValue.error(e, s);
    }
  }

  // 로그아웃 메소드
  Future<void> signOut() async {
    if (kDebugMode) {
      print('🔑 Signing out user...');
    }

    try {
      await _authRepository.signOut();
      state = AsyncValue.data(
          AuthState(user: null, status: AuthStatus.unauthenticated));

      if (kDebugMode) {
        print('🔑 Sign out completed successfully');
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('🔑 Sign out error: $e');
      }
      state = AsyncValue.error(e, s);
    }
  }

  // 프로필 업데이트
  Future<void> updateUserProfile({
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
    if (kDebugMode) {
      print('🔑 Updating user profile for uid: $uid');
    }

    state = const AsyncValue.loading(); // 프로필 업데이트 중 로딩

    try {
      final updatedUser = await _authRepository.updateUserProfile(
        uid: uid,
        name: name,
        phoneNumber: phoneNumber,
        roadNameAddress: roadNameAddress,
        locationAddress: locationAddress,
        locationTagId: locationTagId,
        locationTagName: locationTagName,
        locationStatus: locationStatus,
        pendingLocationName: pendingLocationName,
      );

      if (kDebugMode) {
        print('🔑 Profile update completed successfully');
      }

      state = AsyncValue.data(
          AuthState(user: updatedUser, status: AuthStatus.authenticated));
    } catch (e, s) {
      if (kDebugMode) {
        print('🔑 Profile update error: $e');
      }
      state = AsyncValue.error(e, s);
    }
  }

  // 전화번호로 사용자 존재 여부 확인
  Future<bool> checkUserExistsByPhoneNumber(String phoneNumber) async {
    if (kDebugMode) {
      print('🔑 Checking if user exists by phone number: $phoneNumber');
    }

    try {
      final exists =
          await _authRepository.checkUserExistsByPhoneNumber(phoneNumber);
      if (kDebugMode) {
        print('🔑 User exists check result: $exists');
      }
      return exists;
    } catch (e, s) {
      if (kDebugMode) {
        print('🔑 Error checking user existence: $e');
      }
      await _integrityService.logAuthError(
        operation: 'checkUserExistsByPhoneNumber',
        errorMessage: e.toString(),
        additionalData: {
          'stackTrace': s.toString(),
          'phoneNumber': phoneNumber
        },
      );
      throw e;
    }
  }
}
