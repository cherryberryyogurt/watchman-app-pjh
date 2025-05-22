import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/kakao_map_service.dart';
import 'auth_providers.dart';

part 'signup_provider.g.dart';

// Sign up process stages
enum SignUpStage {
  initial,        // Starting state
  emailInput,     // Email entered, ready for verification
  emailVerificationSent, // Verification email sent
  emailVerified,  // Email successfully verified
  phoneInput,     // Phone number entered, ready for verification
  phoneVerificationSent, // SMS verification code sent
  phoneVerified,  // Phone successfully verified
  locationInput,  // Ready to input location
  locationVerified, // Location verified
  passwordInput,  // Ready to create password
  completed,      // All steps completed
}

// Sign up action types
enum SignUpActionType {
  none,
  verifyingEmail,
  verifyingPhone,
  fetchingLocation,
  updatingFields,
  submitting,
}

// Sign up state class
class SignUpState {
  final String name;
  final String email;
  final String phoneNumber;
  final String roadNameAddress;
  final String locationAddress;
  final String locationTag;
  final bool isPhoneVerified;
  final bool isAddressVerified;
  final bool isEmailVerified;
  final SignUpStage stage;
  final SignUpActionType currentAction;
  final String? errorMessage;
  final bool isLoading;
  final String? verificationId; // For SMS verification
  final int? resendToken; // For SMS resend
  final String? password; // Stored temporarily during registration process

  const SignUpState({
    this.name = '',
    this.email = '',
    this.phoneNumber = '',
    this.roadNameAddress = '',
    this.locationAddress = '',
    this.locationTag = '',
    this.isPhoneVerified = false,
    this.isAddressVerified = false,
    this.isEmailVerified = false,
    this.stage = SignUpStage.initial,
    this.currentAction = SignUpActionType.none,
    this.errorMessage,
    this.isLoading = false,
    this.verificationId,
    this.resendToken,
    this.password,
  });

  // copyWith method for immutability
  SignUpState copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? roadNameAddress,
    String? locationAddress,
    String? locationTag,
    bool? isPhoneVerified,
    bool? isAddressVerified,
    bool? isEmailVerified,
    SignUpStage? stage,
    SignUpActionType? currentAction,
    String? errorMessage,
    bool? isLoading,
    String? verificationId,
    int? resendToken,
    String? password,
  }) {
    return SignUpState(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roadNameAddress: roadNameAddress ?? this.roadNameAddress,
      locationAddress: locationAddress ?? this.locationAddress,
      locationTag: locationTag ?? this.locationTag,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isAddressVerified: isAddressVerified ?? this.isAddressVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      stage: stage ?? this.stage,
      currentAction: currentAction ?? this.currentAction,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      password: password ?? this.password,
    );
  }

  // Method to clear error message
  SignUpState clearError() {
    return copyWith(errorMessage: null);
  }

  // Convert to UserModel
  UserModel toUserModel() {
    return UserModel(
      uid: '', // Will be set by Firebase Auth
      email: email,
      name: name,
      phoneNumber: phoneNumber,
      roadNameAddress: roadNameAddress,
      locationAddress: locationAddress,
      locationTag: locationTag,
      isPhoneVerified: isPhoneVerified,
      isAddressVerified: isAddressVerified,
      isEmailVerified: isEmailVerified,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Validation methods
  bool get isNameValid => name.isNotEmpty;
  bool get isEmailValid => email.isNotEmpty && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  bool get isPhoneNumberValid => phoneNumber.isNotEmpty && RegExp(r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$').hasMatch(phoneNumber);
  bool get isLocationValid => locationAddress.isNotEmpty && locationTag.isNotEmpty;
  bool get isPasswordValid => password != null && password!.length >= 6;

  // Check if ready for each stage
  bool get canVerifyEmail => isEmailValid && !isEmailVerified;
  bool get canVerifyPhone => isPhoneNumberValid && !isPhoneVerified;
  bool get canVerifyLocation => !isAddressVerified;
  bool get canCompleteSignUp => isNameValid && isEmailVerified && isPhoneVerified && isAddressVerified && isPasswordValid;
}

// Kakao Map Service Provider
@riverpod
KakaoMapService kakaoMapService(KakaoMapServiceRef ref) {
  return KakaoMapService();
}

// Sign up notifier class
@riverpod
class SignUp extends _$SignUp {
  late final AuthRepository _authRepository;
  late final FirebaseAuth _auth;
  Timer? _emailVerificationTimer;

  @override
  FutureOr<SignUpState> build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _auth = FirebaseAuth.instance;
    
    // Cleanup on dispose
    ref.onDispose(() {
      _emailVerificationTimer?.cancel();
    });
    
    return const SignUpState();
  }

  // Update name
  void updateName(String name) {
    state = AsyncValue.data(state.value!.copyWith(
      name: name,
      errorMessage: null,
    ));
  }

  // Update email
  void updateEmail(String email) {
    state = AsyncValue.data(state.value!.copyWith(
      email: email,
      isEmailVerified: false, // Reset verification if email changes
      errorMessage: null,
    ));
  }

  // Update phone number
  void updatePhoneNumber(String phoneNumber) {
    // Format phone number (remove hyphens if present)
    phoneNumber = phoneNumber.replaceAll('-', '');
    
    state = AsyncValue.data(state.value!.copyWith(
      phoneNumber: phoneNumber,
      isPhoneVerified: false, // Reset verification if phone changes
      errorMessage: null,
    ));
  }

  // Update password
  void updatePassword(String password) {
    state = AsyncValue.data(state.value!.copyWith(
      password: password,
      errorMessage: null,
    ));
  }

  // Update location fields
  void updateLocationFields({
    String? roadNameAddress,
    String? locationAddress,
    String? locationTag,
  }) {
    state = AsyncValue.data(state.value!.copyWith(
      roadNameAddress: roadNameAddress,
      locationAddress: locationAddress,
      locationTag: locationTag,
      isAddressVerified: (roadNameAddress != null || locationAddress != null || locationTag != null),
      errorMessage: null,
    ));
  }

  // Move to next stage
  void moveToStage(SignUpStage stage) {
    state = AsyncValue.data(state.value!.copyWith(
      stage: stage,
      errorMessage: null,
    ));
  }

  // Clear error message
  void clearError() {
    state = AsyncValue.data(state.value!.clearError());
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    state = AsyncValue.data(state.value!.copyWith(
      currentAction: SignUpActionType.verifyingEmail,
      isLoading: true,
      errorMessage: null,
    ));

    try {
      // Create a temporary user for email verification
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: state.value!.email,
        password: 'temporary-password-${DateTime.now().millisecondsSinceEpoch}',
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('사용자 계정 생성에 실패했습니다.');
      }

      // Send verification email
      await user.sendEmailVerification();
      
      // Start polling for email verification
      _startEmailVerificationPolling(user);

      state = AsyncValue.data(state.value!.copyWith(
        stage: SignUpStage.emailVerificationSent,
        currentAction: SignUpActionType.none,
        isLoading: false,
      ));
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = '이미 사용 중인 이메일입니다.';
          break;
        case 'invalid-email':
          errorMessage = '올바른 이메일 형식이 아닙니다.';
          break;
        default:
          errorMessage = '이메일 인증 발송에 실패했습니다: ${e.message}';
      }
      
      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: errorMessage,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: '이메일 인증 발송 중 오류가 발생했습니다: $e',
      ));
    }
  }

  // Start polling for email verification
  void _startEmailVerificationPolling(User user) {
    // Cancel any existing timer
    _emailVerificationTimer?.cancel();
    
    // Poll every 5 seconds
    _emailVerificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        // Reload user to get latest email verification status
        await user.reload();
        final updatedUser = _auth.currentUser;
        
        // Check if email is verified
        if (updatedUser != null && updatedUser.emailVerified) {
          timer.cancel();
          
          // Delete the temporary user as we'll create the real one later
          await updatedUser.delete();
          
          // Update state to reflect email verification
          state = AsyncValue.data(state.value!.copyWith(
            isEmailVerified: true,
            stage: SignUpStage.emailVerified,
          ));
        }
      } catch (e) {
        debugPrint('Error checking email verification: $e');
      }
    });
  }

  // Manually check email verification status
  Future<void> checkEmailVerification() async {
    state = AsyncValue.data(state.value!.copyWith(
      currentAction: SignUpActionType.verifyingEmail,
      isLoading: true,
      errorMessage: null,
    ));

    try {
      // Reload current user
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = _auth.currentUser;
        
        if (updatedUser != null && updatedUser.emailVerified) {
          // Delete the temporary user as we'll create the real one later
          await updatedUser.delete();
          
          state = AsyncValue.data(state.value!.copyWith(
            isEmailVerified: true,
            stage: SignUpStage.emailVerified,
            currentAction: SignUpActionType.none,
            isLoading: false,
          ));
        } else {
          state = AsyncValue.data(state.value!.copyWith(
            currentAction: SignUpActionType.none,
            isLoading: false,
            errorMessage: '이메일이 아직 인증되지 않았습니다. 인증 이메일을 확인해주세요.',
          ));
        }
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          currentAction: SignUpActionType.none,
          isLoading: false,
          errorMessage: '인증 상태를 확인할 수 없습니다. 다시 시도해주세요.',
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: '이메일 인증 확인 중 오류가 발생했습니다: $e',
      ));
    }
  }

  // Send phone verification code
  Future<void> sendPhoneVerification() async {
    state = AsyncValue.data(state.value!.copyWith(
      currentAction: SignUpActionType.verifyingPhone,
      isLoading: true,
      errorMessage: null,
    ));

    try {
      // Format phone number for Firebase (add +82)
      final phoneNumber = '+82${state.value!.phoneNumber.startsWith('0') ? state.value!.phoneNumber.substring(1) : state.value!.phoneNumber}';
      
      // Verification completed callback
      final verificationCompleted = (PhoneAuthCredential credential) {
        debugPrint('Phone verification completed automatically!');
        // Auto-verification is handled here
        _verifyPhoneCredential(credential);
      };
      
      // Verification failed callback
      final verificationFailed = (FirebaseAuthException e) {
        String errorMessage;
        switch (e.code) {
          case 'invalid-phone-number':
            errorMessage = '올바른 전화번호 형식이 아닙니다.';
            break;
          case 'too-many-requests':
            errorMessage = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
            break;
          default:
            errorMessage = '전화번호 인증에 실패했습니다: ${e.message}';
        }
        
        state = AsyncValue.data(state.value!.copyWith(
          currentAction: SignUpActionType.none,
          isLoading: false,
          errorMessage: errorMessage,
        ));
      };
      
      // Code sent callback
      final codeSent = (String verificationId, int? resendToken) {
        state = AsyncValue.data(state.value!.copyWith(
          verificationId: verificationId,
          resendToken: resendToken,
          stage: SignUpStage.phoneVerificationSent,
          currentAction: SignUpActionType.none,
          isLoading: false,
        ));
      };
      
      // Code auto retrieval timeout callback
      final codeAutoRetrievalTimeout = (String verificationId) {
        debugPrint('Code auto retrieval timed out');
      };
      
      // Send verification code
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(minutes: 2),
        forceResendingToken: state.value!.resendToken,
      );
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: '전화번호 인증 발송 중 오류가 발생했습니다: $e',
      ));
    }
  }

  // Verify phone with code
  Future<void> verifyPhoneWithCode(String smsCode) async {
    state = AsyncValue.data(state.value!.copyWith(
      currentAction: SignUpActionType.verifyingPhone,
      isLoading: true,
      errorMessage: null,
    ));

    try {
      final verificationId = state.value!.verificationId;
      if (verificationId == null) {
        throw Exception('인증 ID가 없습니다. 다시 시도해주세요.');
      }
      
      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId, 
        smsCode: smsCode,
      );
      
      await _verifyPhoneCredential(credential);
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: '인증번호 확인 중 오류가 발생했습니다: $e',
      ));
    }
  }

  // Helper method to verify phone credential
  Future<void> _verifyPhoneCredential(PhoneAuthCredential credential) async {
    try {
      // Sign in with credential to verify
      await _auth.signInWithCredential(credential);
      
      // Sign out immediately (we're just verifying, not logging in)
      await _auth.signOut();
      
      // Update state
      state = AsyncValue.data(state.value!.copyWith(
        isPhoneVerified: true,
        stage: SignUpStage.phoneVerified,
        currentAction: SignUpActionType.none,
        isLoading: false,
      ));
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = '올바르지 않은 인증번호입니다.';
          break;
        case 'invalid-verification-id':
          errorMessage = '인증 세션이 만료되었습니다. 다시 시도해주세요.';
          break;
        default:
          errorMessage = '전화번호 인증에 실패했습니다: ${e.message}';
      }
      
      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: errorMessage,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: '전화번호 인증 확인 중 오류가 발생했습니다: $e',
      ));
    }
  }

  // Fetch current location and convert to address
  Future<void> fetchCurrentLocation() async {
    state = AsyncValue.data(state.value!.copyWith(
      currentAction: SignUpActionType.fetchingLocation,
      isLoading: true,
      errorMessage: null,
    ));

    try {
      final kakaoMapService = ref.read(kakaoMapServiceProvider);
      
      // Get current position
      final position = await kakaoMapService.getCurrentPosition();
      
      // Convert position to address using Kakao API
      final addressInfo = await kakaoMapService.getAddressFromCoords(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      // Update state with address information
      state = AsyncValue.data(state.value!.copyWith(
        roadNameAddress: addressInfo.roadNameAddress,
        locationAddress: addressInfo.locationAddress,
        locationTag: addressInfo.locationTag,
        isAddressVerified: true,
        stage: SignUpStage.locationVerified,
        currentAction: SignUpActionType.none,
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: '위치 정보 확인 중 오류가 발생했습니다: $e',
      ));
    }
  }

  // Complete signup process
  Future<void> completeSignUp() async {
    state = AsyncValue.data(state.value!.copyWith(
      currentAction: SignUpActionType.submitting,
      isLoading: true,
      errorMessage: null,
    ));

    try {
      final currentState = state.value!;
      
      if (!currentState.canCompleteSignUp) {
        throw Exception('모든 필수 정보를 입력하고 인증을 완료해주세요.');
      }
      
      if (currentState.password == null) {
        throw Exception('비밀번호를 입력해주세요.');
      }
    // ------------------------------------------------------------
    // 구형 회원가입 로직 (추후 삭제 예정)
    // ------------------------------------------------------------
    //   // Register with email and password
    //   final user = await _authRepository.signUpWithEmailAndPassword(
    //     email: currentState.email,
    //     password: currentState.password!,
    //     name: currentState.name,
    //   );
      
    //   // Update additional fields in Firestore
    //   await _authRepository.updateUserProfile(
    //     uid: user.uid,
    //     phoneNumber: currentState.phoneNumber,
    //     address: currentState.locationAddress,
    //   );

    // ------------------------------------------------------------
    // 신형 회원가입 로직
    // ------------------------------------------------------------
      final user = await _authRepository.signUp(
        email: currentState.email,
        password: currentState.password!,
        name: currentState.name,
        phoneNumber: currentState.phoneNumber,
        roadNameAddress: currentState.roadNameAddress,
        locationAddress: currentState.locationAddress,
        locationTag: currentState.locationTag,
        isPhoneVerified: currentState.isPhoneVerified,
        isAddressVerified: currentState.isAddressVerified,
        isEmailVerified: currentState.isEmailVerified,
      );
    
      
      // Set phone verified status
      await _authRepository.setPhoneVerified(
        uid: user.uid,
        verified: currentState.isPhoneVerified,
      );
      
      // Update state to completed
      state = AsyncValue.data(currentState.copyWith(
        stage: SignUpStage.completed,
        currentAction: SignUpActionType.none,
        isLoading: false,
      ));
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = '이미 사용 중인 이메일입니다.';
          break;
        case 'invalid-email':
          errorMessage = '올바른 이메일 형식이 아닙니다.';
          break;
        case 'weak-password':
          errorMessage = '비밀번호가 너무 약합니다.';
          break;
        default:
          errorMessage = '회원가입에 실패했습니다: ${e.message}';
      }
      
      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: errorMessage,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: '회원가입 중 오류가 발생했습니다: $e',
      ));
    }
  }

  // Reset state (used when navigating away or cancelling)
  void resetState() {
    state = const AsyncValue.data(SignUpState());
  }
} 