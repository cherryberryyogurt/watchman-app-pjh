import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../utils/secure_storage.dart';
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
AuthRepository authRepository(AuthRepositoryRef ref) {
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
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;

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
      if (kDebugMode) {
        print('🔥 Auth: build() - Firebase 사용자: ${firebaseUser?.uid ?? "없음"}');
      }

      if (firebaseUser == null) {
        await SecureStorage.deleteAllTokens();
        if (kDebugMode) {
          print('🔥 Auth: build() - 사용자 없음, 비인증 상태로 설정');
        }
        return const AuthState(user: null, status: AuthStatus.unauthenticated);
      }

      try {
        final rememberMe = await SecureStorage.getRememberMe();
        if (!rememberMe) {
          if (kDebugMode) {
            print('🔥 Auth: build() - Remember Me 비활성화, 비인증 상태로 설정');
          }
          return const AuthState(
              user: null, status: AuthStatus.unauthenticated);
        }

        // 🔐 Phone Auth 사용자인지 확인하고 적절한 인증 검사 수행
        final isPhoneAuth = await SecureStorage.isPhoneAuthUser();
        bool isAuthValid = false;

        if (isPhoneAuth) {
          // Phone Auth 사용자인 경우 세션 유효성 검사
          isAuthValid = await SecureStorage.isPhoneAuthSessionValid();
          if (kDebugMode) {
            print('🔥 Auth: build() - Phone Auth 사용자, 세션 유효성: $isAuthValid');
          }

          // Phone Auth 세션이 유효하지 않아도 회원가입 직후라면 계속 진행
          if (!isAuthValid) {
            // 회원가입 직후 5분 이내라면 예외적으로 허용
            final currentUser = await _authRepository
                .getUserModelFromFirestore(firebaseUser.uid);
            if (currentUser != null) {
              final now = DateTime.now();
              final timeDiff = now.difference(currentUser.createdAt);
              if (timeDiff.inMinutes <= 5) {
                if (kDebugMode) {
                  print('🔥 Auth: build() - 회원가입 직후 5분 이내, 세션 무효해도 허용');
                }
                // Phone Auth 세션을 새로 생성
                await SecureStorage.savePhoneAuthSession();
                isAuthValid = true;
              }
            }
          }
        } else {
          // 기존 email+password 사용자인 경우 토큰 유효성 검사
          isAuthValid = await SecureStorage.isTokenValid();
          if (kDebugMode) {
            print('🔥 Auth: build() - Email 사용자, 토큰 유효성: $isAuthValid');
          }
        }

        // 인증이 유효하지 않으면 에러 없이 계속 진행하여 Firestore 조회 시도
        if (!isAuthValid) {
          if (kDebugMode) {
            print('🔥 Auth: build() - 인증 유효하지 않음, Firestore 조회 계속 진행');
          }
        }

        // Firebase Auth 토큰 갱신 시도
        try {
          await _authRepository.getIdToken(true);
          if (kDebugMode) {
            print('🔥 Auth: build() - Firebase Auth 토큰 갱신 성공');
          }
        } catch (tokenError) {
          if (kDebugMode) {
            print('🔥 Auth: build() - Firebase Auth 토큰 갱신 실패: $tokenError');
          }
          // 토큰 갱신 실패해도 계속 진행
        }

        final userModel =
            await _authRepository.getUserModelFromFirestore(firebaseUser.uid);
        if (userModel != null) {
          if (kDebugMode) {
            print(
                '🔥 Auth: build() - Firestore에서 사용자 정보 조회 성공: ${userModel.name}');
          }
          return AuthState(user: userModel, status: AuthStatus.authenticated);
        } else {
          if (kDebugMode) {
            print('🔥 Auth: build() - Firestore에서 사용자 정보 없음');
          }
          await _integrityService.logAuthError(
              operation: 'BuildAuthState_FirestoreUserNotFound',
              errorMessage: 'Firestore에서 사용자 모델을 찾을 수 없습니다.',
              userId: firebaseUser.uid);
          throw Exception('사용자 프로필 정보를 찾을 수 없습니다.');
        }
      } catch (e, s) {
        if (kDebugMode) {
          print('🔥 Auth: build() - 에러 발생: $e');
        }
        await _integrityService.logAuthError(
            operation: 'BuildAuthState_ProcessingUser',
            errorMessage: e.toString(),
            userId: firebaseUser.uid,
            additionalData: {'stackTrace': s.toString()});
        throw Exception('인증 상태 처리 중 오류: ${e.toString()}');
      }
    }).handleError((error, stackTrace) {
      if (kDebugMode) {
        print('🔥 Auth: build() - 글로벌 에러: $error');
      }
      _integrityService.logAuthError(
          operation: 'AuthStateStream_GlobalError',
          errorMessage: error.toString(),
          additionalData: {'stackTrace': stackTrace.toString()});
      return AuthState(
          user: null, status: AuthStatus.error, errorMessage: error.toString());
    });
  }

  // 🔥 Auth State 강제 새로고침 기능 추가
  Future<void> refreshAuthState() async {
    if (kDebugMode) {
      print('🔥 Auth: refreshAuthState() - 시작');
    }

    try {
      state = const AsyncValue.loading();
      final currentUser = await _authRepository.getCurrentUser();

      if (currentUser != null) {
        // Phone Auth 사용자라면 세션 갱신
        final isPhoneAuth = await SecureStorage.isPhoneAuthUser();
        if (isPhoneAuth) {
          await SecureStorage.savePhoneAuthSession();
          if (kDebugMode) {
            print('🔥 Auth: refreshAuthState() - Phone Auth 세션 갱신 완료');
          }
        }

        state = AsyncValue.data(
            AuthState(user: currentUser, status: AuthStatus.authenticated));
        if (kDebugMode) {
          print('🔥 Auth: refreshAuthState() - 성공: ${currentUser.name}');
        }
      } else {
        state = const AsyncValue.data(
            AuthState(user: null, status: AuthStatus.unauthenticated));
        if (kDebugMode) {
          print('🔥 Auth: refreshAuthState() - 사용자 없음');
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('🔥 Auth: refreshAuthState() - 에러: $e');
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
      print('🔥 Auth: loadCurrentUser() - 시작');
    }

    state = AsyncValue.loading();
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser != null) {
        state = AsyncValue.data(
            AuthState(user: currentUser, status: AuthStatus.authenticated));
        if (kDebugMode) {
          print('🔥 Auth: loadCurrentUser() - 성공: ${currentUser.name}');
        }
      } else {
        state = const AsyncValue.data(
            AuthState(user: null, status: AuthStatus.unauthenticated));
        if (kDebugMode) {
          print('🔥 Auth: loadCurrentUser() - 사용자 없음');
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('🔥 Auth: loadCurrentUser() - 에러: $e');
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
      print('🔥 Auth: signInWithPhoneNumber() - 시작');
    }

    state = AsyncValue.loading();

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
            '🔥 Auth: signInWithPhoneNumber() - Firebase Auth 로그인 성공: ${firebaseUser.uid}');
      }

      // Firestore에서 사용자 정보 확인
      final userModel =
          await _authRepository.getUserModelFromFirestore(firebaseUser.uid);

      if (userModel == null) {
        // 신규 사용자인 경우 - 회원가입이 필요함을 알림
        if (kDebugMode) {
          print('🔥 Auth: signInWithPhoneNumber() - 신규 사용자, 회원가입 필요');
        }
        throw Exception('USER_NOT_FOUND');
      }

      // 기존 사용자인 경우 로그인 완료
      // 🔐 Phone Auth 사용자로 설정하고 세션 저장
      await SecureStorage.setPhoneAuthUser(true);
      await SecureStorage.savePhoneAuthSession();
      await SecureStorage.saveRememberMe(true);

      if (kDebugMode) {
        print(
            '🔥 Auth: signInWithPhoneNumber() - 기존 사용자 로그인 완료: ${userModel.name}');
      }

      state = AsyncValue.data(
          AuthState(user: userModel, status: AuthStatus.authenticated));
    } catch (e, s) {
      if (kDebugMode) {
        print('🔥 Auth: signInWithPhoneNumber() - 에러: $e');
      }
      await _integrityService.logAuthError(
        operation: 'signInWithPhoneNumber',
        errorMessage: e.toString(),
        additionalData: {'stackTrace': s.toString()},
      );
      state = AsyncValue.error(e, s);
    }
  }

  // 회원가입 메소드 - 전화번호 인증 완료 후 호출
  Future<void> signUp(String name, String? phone, String? roadNameAddress,
      String? locationAddress, String? locationTag) async {
    if (kDebugMode) {
      print('🔥 Auth: signUp() - 시작: $name');
    }

    state = AsyncValue.loading();

    try {
      // 전화번호 인증이 회원가입 과정 중 마지막에 완료된 상태
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        throw Exception('전화번호 인증이 완료되지 않았습니다.');
      }

      if (kDebugMode) {
        print('🔥 Auth: signUp() - Firebase Auth 사용자 확인: ${firebaseUser.uid}');
      }

      // Firestore에서 기존 사용자 정보 확인 (혹시 이미 존재하는지 체크)
      final existingUser =
          await _authRepository.getUserModelFromFirestore(firebaseUser.uid);

      if (existingUser != null) {
        // 이미 존재하는 사용자인 경우 해당 정보로 로그인 처리
        if (kDebugMode) {
          print('🔥 Auth: signUp() - 이미 존재하는 사용자: ${existingUser.name}');
        }

        // 🔐 Phone Auth 사용자로 설정하고 세션 저장
        await SecureStorage.setPhoneAuthUser(true);
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
        locationTag: locationTag,
      );

      // 🔐 Phone Auth 사용자로 설정하고 세션 저장
      await SecureStorage.setPhoneAuthUser(true);
      await SecureStorage.savePhoneAuthSession();
      await SecureStorage.saveRememberMe(true);

      if (kDebugMode) {
        print('🔥 Auth: signUp() - 신규 사용자 등록 완료: ${user.name}');
      }

      // Update state with authenticated user after successful signup
      state = AsyncValue.data(
          AuthState(user: user, status: AuthStatus.authenticated));
    } catch (e, s) {
      if (kDebugMode) {
        print('🔥 Auth: signUp() - 에러: $e');
      }
      await _integrityService.logAuthError(
        operation: 'signUp',
        errorMessage: e.toString(),
        additionalData: {'stackTrace': s.toString(), 'name': name},
      );
      state = AsyncValue.error(e, s);
    }
  }

  // 로그아웃 메소드
  Future<void> signOut() async {
    if (kDebugMode) {
      print('🔥 Auth: signOut() - 시작');
    }

    state = const AsyncValue.loading();

    try {
      await _authRepository.signOut();

      if (kDebugMode) {
        print('🔥 Auth: signOut() - 완료');
      }

      // Update state to unauthenticated after successful logout
      state = const AsyncValue.data(
          AuthState(user: null, status: AuthStatus.unauthenticated));
    } catch (e, s) {
      if (kDebugMode) {
        print('🔥 Auth: signOut() - 에러: $e');
      }
      await _integrityService.logAuthError(
        operation: 'signOut',
        errorMessage: e.toString(),
        additionalData: {'stackTrace': s.toString()},
      );
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
    String? locationTag,
  }) async {
    if (kDebugMode) {
      print('🔥 Auth: updateUserProfile() - 시작: $uid');
    }

    final currentUserState = state.value ?? const AuthState();
    // state = AsyncValue.data(currentUserState.copyWith(currentAction: AuthActionType.updateProfile));
    state = const AsyncValue.loading(); // 프로필 업데이트 중 로딩

    try {
      final updatedUser = await _authRepository.updateUserProfile(
        uid: uid,
        name: name,
        phoneNumber: phoneNumber,
        roadNameAddress: roadNameAddress,
        locationAddress: locationAddress,
        locationTag: locationTag,
      );

      if (kDebugMode) {
        print('🔥 Auth: updateUserProfile() - 성공: ${updatedUser.name}');
      }

      // 성공 시 build() 스트림이 갱신된 사용자 정보로 상태를 업데이트 하거나,
      // 여기서 명시적으로 업데이트된 사용자로 상태 설정.
      state = AsyncValue.data(
          AuthState(user: updatedUser, currentAction: AuthActionType.none));
    } catch (e, s) {
      if (kDebugMode) {
        print('🔥 Auth: updateUserProfile() - 에러: $e');
      }
      await _integrityService.logAuthError(
        operation: 'updateUserProfile',
        errorMessage: e.toString(),
        additionalData: {'stackTrace': s.toString(), 'userId': uid},
      );
      // state = AsyncValue.data(AuthState(user: currentUserState.user, currentAction: AuthActionType.none)); // 실패 시 이전 상태로
      state = AsyncValue.error(e, s); // 또는 에러 상태로
      // throw e;
    }
  }

  // 현재 사용자 가져오기 (AsyncValue<AuthState>의 data 부분에서 user를 가져오도록 UI에서 처리)
  // UserModel? get currentUser => state.value?.user; (state가 AsyncValue<AuthState>이므로)

  // 전화번호로 사용자 존재 여부 확인
  Future<bool> checkUserExistsByPhoneNumber(String phoneNumber) async {
    if (kDebugMode) {
      print('🔥 Auth: checkUserExistsByPhoneNumber() - 시작: $phoneNumber');
    }

    try {
      final userExists =
          await _authRepository.checkUserExistsByPhoneNumber(phoneNumber);

      if (kDebugMode) {
        print('🔥 Auth: checkUserExistsByPhoneNumber() - 결과: $userExists');
      }

      return userExists;
    } catch (e, s) {
      if (kDebugMode) {
        print('🔥 Auth: checkUserExistsByPhoneNumber() - 에러: $e');
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

  // Stream 구독 해제 (AsyncNotifier는 자동으로 처리해줄 수 있음, 또는 ref.onDispose 사용)
  // @override
  // void dispose() {
  //   _authStateSubscription?.cancel();
  //   super.dispose();
  // }
}
