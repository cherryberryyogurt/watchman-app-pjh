import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../utils/secure_storage.dart';
import '../services/auth_integrity_service.dart';

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
      isPasswordResetSuccess: isPasswordResetSuccess ?? this.isPasswordResetSuccess,
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
      if (firebaseUser == null) {
        await SecureStorage.deleteAllTokens();
        return const AuthState(user: null, status: AuthStatus.unauthenticated);
      }

      try {
        final rememberMe = await SecureStorage.getRememberMe();
        if (!rememberMe) {
          return const AuthState(user: null, status: AuthStatus.unauthenticated);
        }

        final isTokenValid = await SecureStorage.isTokenValid();
        if (!isTokenValid) {
          throw Exception('로그인 세션이 만료되었습니다. 다시 로그인해주세요.');
        }

        await _authRepository.getIdToken(true);

        final userModel = await _authRepository.getUserModelFromFirestore(firebaseUser.uid);
        if (userModel != null) {
          return AuthState(user: userModel, status: AuthStatus.authenticated);
        } else {
          await _integrityService.logAuthError(
              operation: 'BuildAuthState_FirestoreUserNotFound',
              errorMessage: 'Firestore에서 사용자 모델을 찾을 수 없습니다.',
              userId: firebaseUser.uid);
          throw Exception('사용자 프로필 정보를 찾을 수 없습니다.');
        }
      } catch (e, s) {
        await _integrityService.logAuthError(
            operation: 'BuildAuthState_ProcessingUser',
            errorMessage: e.toString(),
            userId: firebaseUser.uid,
            additionalData: {'stackTrace': s.toString()});
        throw Exception('인증 상태 처리 중 오류: ${e.toString()}');
      }
    }).handleError((error, stackTrace) {
      _integrityService.logAuthError(
          operation: 'AuthStateStream_GlobalError',
          errorMessage: error.toString(),
          additionalData: {'stackTrace': stackTrace.toString()});
      return AuthState(
        user: null, 
        status: AuthStatus.error, 
        errorMessage: error.toString()
      ); 
    });
  }

  // 사용자 정보 초기 로드 메소드 추가
  Future<void> loadCurrentUser() async {
    state = AsyncValue.loading();
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser != null) {
        state = AsyncValue.data(AuthState(
          user: currentUser,
          status: AuthStatus.authenticated
        ));
      } else {
        state = const AsyncValue.data(AuthState(
          user: null,
          status: AuthStatus.unauthenticated
        ));
      }
    } catch (e, s) {
      await _integrityService.logAuthError(
        operation: 'loadCurrentUser',
        errorMessage: e.toString(),
        additionalData: {'stackTrace': s.toString()},
      );
      state = AsyncValue.error(
        e, 
        s
      );
    }
  }

  // 로그인 메소드
  Future<void> signInWithEmailAndPassword(String email, String password, bool rememberMe) async {
    final currentUserState = state.value ?? const AuthState();
    state = AsyncValue.loading();

    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email, 
        password: password, 
        rememberMe: rememberMe
      );
      
      // Update state with authenticated user after successful login
      state = AsyncValue.data(AuthState(
        user: user,
        status: AuthStatus.authenticated
      ));
    } catch (e, s) {
      await _integrityService.logAuthError(
        operation: 'signInWithEmailAndPassword',
        errorMessage: e.toString(),
        additionalData: {'stackTrace': s.toString(), 'email': email},
      );
      state = AsyncValue.error(e, s);
    }
  }

  // 회원가입 메소드
  Future<void> signUp(String email, String password, String name, String? phone, String? roadNameAddress, String? locationAddress, String? locationTag, bool isPhoneVerified, bool isAddressVerified, bool isEmailVerified) async {
    state = AsyncValue.loading();
    
    try {
      final user = await _authRepository.signUp(
        email: email, 
        password: password, 
        name: name,
        phoneNumber: phone,
        roadNameAddress: roadNameAddress,
        locationAddress: locationAddress,
        locationTag: locationTag,
        isPhoneVerified: isPhoneVerified,
        isAddressVerified: isAddressVerified,
        isEmailVerified: isEmailVerified,
      );
      
      // Update state with authenticated user after successful signup
      state = AsyncValue.data(AuthState(
        user: user,
        status: AuthStatus.authenticated
      ));
    } catch (e, s) {
      await _integrityService.logAuthError(
        operation: 'signUp',
        errorMessage: e.toString(),
        additionalData: {'stackTrace': s.toString(), 'email': email, 'name': name},
      );
      state = AsyncValue.error(e, s);
    }
  }
  
  // 로그아웃 메소드
  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      await _authRepository.signOut();
      
      // Update state to unauthenticated after successful logout
      state = const AsyncValue.data(AuthState(
        user: null,
        status: AuthStatus.unauthenticated
      ));
    } catch (e, s) {
      await _integrityService.logAuthError(
        operation: 'signOut',
        errorMessage: e.toString(),
        additionalData: {'stackTrace': s.toString()},
      );
      state = AsyncValue.error(e, s);
    }
  }

  // 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    final currentUserState = state.value ?? const AuthState();
    // 로딩 상태 없이, 작업 진행 중임을 currentAction과 isPasswordResetSuccess로 표시
    state = AsyncValue.data(currentUserState.copyWith(
      currentAction: AuthActionType.passwordReset,
      isPasswordResetSuccess: false
      ));
    try {
      await _authRepository.sendPasswordResetEmail(email);
      // 성공 시 isPasswordResetSuccess를 true로 설정하고 currentAction을 none으로.
      // state.value는 null일 수 있으므로 주의. 이전 user 값을 유지하려면 currentUserState.user 사용.
      state = AsyncValue.data(AuthState(
        user: currentUserState.user,
        currentAction: AuthActionType.none,
        isPasswordResetSuccess: true
      ));
    } catch (e, s) {
      await _integrityService.logAuthError(
        operation: 'sendPasswordResetEmail',
        errorMessage: e.toString(),
        additionalData: {'stackTrace': s.toString(), 'email': email},
      );
      // 실패 시 isPasswordResetSuccess를 false로, currentAction을 none으로.
      state = AsyncValue.data(AuthState(
        user: currentUserState.user, 
        currentAction: AuthActionType.none, 
        isPasswordResetSuccess: false
        ));
      throw e; // UI에서 에러를 인지하고 메시지 표시하도록.
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
    bool? isPhoneVerified,
    bool? isAddressVerified,
    bool? isEmailVerified,
  }) async {
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
        isPhoneVerified: isPhoneVerified,
        isAddressVerified: isAddressVerified,
        isEmailVerified: isEmailVerified,
      );
      // 성공 시 build() 스트림이 갱신된 사용자 정보로 상태를 업데이트 하거나,
      // 여기서 명시적으로 업데이트된 사용자로 상태 설정.
      state = AsyncValue.data(AuthState(
        user: updatedUser, 
        currentAction: AuthActionType.none
        ));
    } catch (e, s) {
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

  // Stream 구독 해제 (AsyncNotifier는 자동으로 처리해줄 수 있음, 또는 ref.onDispose 사용)
  // @override
  // void dispose() {
  //   _authStateSubscription?.cancel();
  //   super.dispose();
  // }
}