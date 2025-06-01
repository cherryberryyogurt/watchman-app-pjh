import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/kakao_map_service.dart';
import 'auth_providers.dart';
import '../../../core/constants/error_messages.dart';
import '../utils/secure_storage.dart';
import 'auth_state.dart' as auth_state_imports;

part 'signup_provider.g.dart';

// Sign up process stages - 이메일/비밀번호 단계 제거
enum SignUpStage {
  initial, // Starting state - 이름 입력
  phoneInput, // Phone number entered, ready for verification
  phoneVerificationSent, // SMS verification code sent
  phoneVerified, // Phone successfully verified
  locationInput, // Ready to input location
  locationVerified, // Location verified
  completed, // All steps completed
}

// Sign up action types
enum SignUpActionType {
  none,
  verifyingPhone,
  fetchingLocation,
  updatingFields,
  submitting,
}

// Sign up state class - 이메일/비밀번호 필드 제거
class SignUpState {
  final String name;
  final String phoneNumber;
  final String address; // 사용자 입력 주소
  final String roadNameAddress;
  final String locationAddress;
  final String locationTag;
  final bool isPhoneVerified;
  final bool isAddressVerified;
  final SignUpStage stage;
  final SignUpActionType currentAction;
  final String? errorMessage;
  final bool isLoading;
  final String? verificationId; // For SMS verification
  final int? resendToken; // For SMS resend

  const SignUpState({
    this.name = '',
    this.phoneNumber = '',
    this.address = '', // 사용자 입력 주소 필드
    this.roadNameAddress = '',
    this.locationAddress = '',
    this.locationTag = '',
    this.isPhoneVerified = false,
    this.isAddressVerified = false,
    this.stage = SignUpStage.initial,
    this.currentAction = SignUpActionType.none,
    this.errorMessage,
    this.isLoading = false,
    this.verificationId,
    this.resendToken,
  });

  // copyWith method for immutability - 이메일/비밀번호 필드 제거
  SignUpState copyWith({
    String? name,
    String? phoneNumber,
    String? address, // 사용자 입력 주소
    String? roadNameAddress,
    String? locationAddress,
    String? locationTag,
    bool? isPhoneVerified,
    bool? isAddressVerified,
    SignUpStage? stage,
    SignUpActionType? currentAction,
    String? errorMessage,
    bool? isLoading,
    String? verificationId,
    int? resendToken,
  }) {
    return SignUpState(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address, // 사용자 입력 주소 필드
      roadNameAddress: roadNameAddress ?? this.roadNameAddress,
      locationAddress: locationAddress ?? this.locationAddress,
      locationTag: locationTag ?? this.locationTag,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isAddressVerified: isAddressVerified ?? this.isAddressVerified,
      stage: stage ?? this.stage,
      currentAction: currentAction ?? this.currentAction,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
    );
  }

  // Method to clear error message
  SignUpState clearError() {
    return copyWith(errorMessage: null);
  }

  // Convert to UserModel - 이메일/비밀번호 필드 제거하고 실제 UserModel 구조에 맞춤
  UserModel toUserModel() {
    return UserModel(
      uid: '', // Will be set by Firebase Auth
      name: name,
      phoneNumber: phoneNumber,
      roadNameAddress: roadNameAddress,
      locationAddress: locationAddress,
      locationTag: locationTag,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Validation methods - 이메일/비밀번호 검증 제거
  bool get isNameValid => name.isNotEmpty;
  bool get isPhoneNumberValid =>
      phoneNumber.isNotEmpty &&
      RegExp(r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$')
          .hasMatch(phoneNumber);
  bool get isAddressInputValid => address.isNotEmpty; // 사용자 입력 주소 검증
  bool get isLocationValid =>
      locationAddress.isNotEmpty && locationTag.isNotEmpty;

  // Check if ready for each stage - 이메일/비밀번호 검증 제거
  bool get canVerifyPhone => isPhoneNumberValid && !isPhoneVerified;
  bool get canVerifyLocation => !isAddressVerified;
  bool get canCompleteSignUp =>
      isNameValid && isPhoneVerified && isAddressVerified;
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

  @override
  FutureOr<SignUpState> build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _auth = FirebaseAuth.instance;

    return const SignUpState();
  }

  // Update name
  void updateName(String name) {
    state = AsyncValue.data(state.value!.copyWith(
      name: name,
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

  // Update address (사용자 입력 주소)
  void updateAddress(String address) {
    state = AsyncValue.data(state.value!.copyWith(
      address: address,
      isAddressVerified: false, // 주소 변경 시 검증 상태 리셋
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
      isAddressVerified: (roadNameAddress != null ||
          locationAddress != null ||
          locationTag != null),
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

  // Send phone verification code
  Future<void> sendPhoneVerification() async {
    if (kDebugMode) {
      print('📝 SignUp: sendPhoneVerification() - 시작');
    }

    state = AsyncValue.data(state.value!.copyWith(
      currentAction: SignUpActionType.verifyingPhone,
      isLoading: true,
      errorMessage: null,
    ));

    try {
      print('🔥 DEBUG: sendPhoneVerification 시작'); // TODO : 디버깅용
      print(
          '🔥 DEBUG: state.value!.phoneNumber = "${state.value!.phoneNumber}"');

      // 한국 전화번호를 E.164 형식으로 변환 (add +82)
      String phoneNumber = state.value!.phoneNumber;

      // 010, 011, 016, 017, 018, 019로 시작하는 한국 휴대폰 번호 처리
      if (phoneNumber.startsWith('01')) {
        phoneNumber = '+82${phoneNumber.substring(1)}';
      } else if (phoneNumber.startsWith('0')) {
        // 일반 전화번호 (02, 031, 032 등)
        phoneNumber = '+82${phoneNumber.substring(1)}';
      } else {
        // 이미 국가 코드가 있거나 다른 형식
        phoneNumber = '+82$phoneNumber';
      }

      if (kDebugMode) {
        print('📝 SignUp: sendPhoneVerification() - 변환된 전화번호: $phoneNumber');
      }

      // Verification completed callback
      verificationCompleted(PhoneAuthCredential credential) {
        if (kDebugMode) {
          print('📝 SignUp: sendPhoneVerification() - 자동 인증 완료');
        }
        debugPrint('Phone verification completed automatically!');
        // Auto-verification is handled here
        _verifyPhoneCredential(credential);
      }

      // Verification failed callback
      verificationFailed(FirebaseAuthException e) {
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

        if (kDebugMode) {
          print('📝 SignUp: sendPhoneVerification() - 인증 실패: $errorMessage');
        }

        state = AsyncValue.data(state.value!.copyWith(
          currentAction: SignUpActionType.none,
          isLoading: false,
          errorMessage: errorMessage,
        ));
      }

      // Code sent callback
      codeSent(String verificationId, int? resendToken) {
        if (kDebugMode) {
          print('📝 SignUp: sendPhoneVerification() - SMS 코드 발송 완료');
        }

        state = AsyncValue.data(state.value!.copyWith(
          verificationId: verificationId,
          resendToken: resendToken,
          stage: SignUpStage.phoneVerificationSent,
          currentAction: SignUpActionType.none,
          isLoading: false,
        ));
      }

      // Code auto retrieval timeout callback
      codeAutoRetrievalTimeout(String verificationId) {
        if (kDebugMode) {
          print('📝 SignUp: sendPhoneVerification() - 자동 복구 타임아웃');
        }
        debugPrint('Code auto retrieval timed out');
      }

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
      if (kDebugMode) {
        print('📝 SignUp: sendPhoneVerification() - 예외 발생: $e');
      }

      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: '전화번호 인증 발송 중 오류가 발생했습니다: $e',
      ));
    }
  }

  // Verify phone with code
  Future<void> verifyPhoneWithCode(String smsCode) async {
    if (kDebugMode) {
      print('📝 SignUp: verifyPhoneWithCode() - 시작: $smsCode');
    }

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
      if (kDebugMode) {
        print('📝 SignUp: verifyPhoneWithCode() - 에러: $e');
      }

      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: '인증번호 확인 중 오류가 발생했습니다: $e',
      ));
    }
  }

  // Helper method to verify phone credential
  Future<void> _verifyPhoneCredential(PhoneAuthCredential credential) async {
    if (kDebugMode) {
      print('📝 SignUp: _verifyPhoneCredential() - 시작');
    }

    try {
      // Sign in with credential - 회원가입 플로우에서는 직접 로그인
      await _auth.signInWithCredential(credential);

      if (kDebugMode) {
        print('📝 SignUp: _verifyPhoneCredential() - Firebase Auth 로그인 성공');
      }

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

      if (kDebugMode) {
        print(
            '📝 SignUp: _verifyPhoneCredential() - Firebase Auth 에러: $errorMessage');
      }

      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: errorMessage,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('📝 SignUp: _verifyPhoneCredential() - 일반 에러: $e');
      }

      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: '전화번호 인증 확인 중 오류가 발생했습니다: $e',
      ));
    }
  }

  // 주소 입력 및 검증 (기존 fetchCurrentLocation 대체)
  Future<void> validateAndRegisterAddress(String inputAddress) async {
    print('📍 validateAndRegisterAddress() 시작');
    print('📍 입력 주소: $inputAddress');

    state = AsyncValue.data(state.value!.copyWith(
      currentAction: SignUpActionType.fetchingLocation,
      isLoading: true,
      errorMessage: null,
    ));

    try {
      final kakaoMapService = ref.read(kakaoMapServiceProvider);
      print('📍 KakaoMapService 인스턴스 생성 완료');

      // 1. 사용자가 입력한 도로명 주소로 카카오 API 검색
      print('📍 주소 검색 시작...');
      final addressDetails =
          await kakaoMapService.searchAddressDetails(inputAddress);

      if (addressDetails == null) {
        // 검색 결과가 없으면 에러 메시지 표시
        state = AsyncValue.data(state.value!.copyWith(
          currentAction: SignUpActionType.none,
          isLoading: false,
          errorMessage: AddressErrorMessages.addressNotFound,
        ));
        return;
      }

      print('📍 ✅ 주소 검색 성공');

      // 검색 결과에서 정보 추출
      final searchedRoadNameAddress =
          addressDetails['roadNameAddress'] as String;
      final searchedLocationAddress =
          addressDetails['locationAddress'] as String;
      final searchedLocationTag = addressDetails['locationTag'] as String;
      final searchedLatitude = addressDetails['latitude'] as double;
      final searchedLongitude = addressDetails['longitude'] as double;

      // 2. 현재 디바이스 GPS 위치 획득 (권한 확인 포함)
      print('📍 현재 위치 확인 시작...');
      Position? currentPosition;

      try {
        // GPS 서비스 활성화 확인
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          state = AsyncValue.data(state.value!.copyWith(
            currentAction: SignUpActionType.none,
            isLoading: false,
            errorMessage: AddressErrorMessages.locationServiceDisabled,
          ));
          return;
        }

        // 위치 권한 확인
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            state = AsyncValue.data(state.value!.copyWith(
              currentAction: SignUpActionType.none,
              isLoading: false,
              errorMessage: AddressErrorMessages.locationPermissionDenied,
            ));
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          state = AsyncValue.data(state.value!.copyWith(
            currentAction: SignUpActionType.none,
            isLoading: false,
            errorMessage: AddressErrorMessages.locationPermissionDeniedForever,
          ));
          return;
        }

        // 현재 위치 가져오기
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
        print(
            '📍 ✅ 현재 위치 획득 성공: ${currentPosition.latitude}, ${currentPosition.longitude}');
      } catch (e) {
        print('📍 ❌ GPS 위치 획득 실패: $e');
        state = AsyncValue.data(state.value!.copyWith(
          currentAction: SignUpActionType.none,
          isLoading: false,
          errorMessage: AddressErrorMessages.locationPermissionDenied,
        ));
        return;
      }

      // 3. 두 위치 간 거리 계산
      print('📍 거리 계산 시작...');
      final distance = kakaoMapService.calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        searchedLatitude,
        searchedLongitude,
      );

      // 4. 거리 검증 (10km 초과 시 에러)
      const double maxDistance = 10.0; // 10km
      if (distance > maxDistance) {
        print('📍 ❌ 거리 초과: ${distance.toStringAsFixed(1)}km');
        state = AsyncValue.data(state.value!.copyWith(
          currentAction: SignUpActionType.none,
          isLoading: false,
          errorMessage: AddressErrorMessages.distanceTooFar(distance),
        ));
        return;
      }

      // 5. 10km 이내인 경우 주소 정보 저장
      print('📍 ✅ 주소 검증 완료 - 거리: ${distance.toStringAsFixed(1)}km');
      state = AsyncValue.data(state.value!.copyWith(
        roadNameAddress: searchedRoadNameAddress,
        locationAddress: searchedLocationAddress,
        locationTag: searchedLocationTag,
        isAddressVerified: true,
        stage: SignUpStage.locationVerified,
        currentAction: SignUpActionType.none,
        isLoading: false,
      ));
    } catch (e) {
      print('📍 ❌ 주소 검증 실패: $e');

      String errorMessage;
      final errorString = e.toString();

      if (errorString.contains(AddressErrorMessages.addressNotFound)) {
        errorMessage = AddressErrorMessages.addressNotFound;
      } else if (errorString
          .contains(AddressErrorMessages.locationServiceDisabled)) {
        errorMessage = AddressErrorMessages.locationServiceDisabled;
      } else if (errorString
          .contains(AddressErrorMessages.locationPermissionDenied)) {
        errorMessage = AddressErrorMessages.locationPermissionDenied;
      } else if (errorString
          .contains(AddressErrorMessages.locationPermissionDeniedForever)) {
        errorMessage = AddressErrorMessages.locationPermissionDeniedForever;
      } else if (errorString.contains(AddressErrorMessages.network)) {
        errorMessage = AddressErrorMessages.network;
      } else if (errorString.contains(AddressErrorMessages.kakaoApi)) {
        errorMessage = AddressErrorMessages.kakaoApi;
      } else {
        errorMessage = '주소 검증 중 오류가 발생했습니다: ${e.toString()}';
      }

      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: errorMessage,
      ));
    }
  }

  // Complete signup process - 이메일/비밀번호 로직 제거
  Future<void> completeSignUp() async {
    if (kDebugMode) {
      print('📝 SignUp: completeSignUp() - 시작');
    }

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

      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('인증된 사용자를 찾을 수 없습니다.');
      }

      if (kDebugMode) {
        print(
            '📝 SignUp: completeSignUp() - Firebase Auth 사용자 확인: ${user.uid}');
        print(
            '📝 SignUp: completeSignUp() - 사용자 정보: ${currentState.name}, ${currentState.phoneNumber}');
      }

      // 사용자 프로필 업데이트
      await user.updateDisplayName(currentState.name);

      // 🔐 Phone Auth 사용자로 설정하고 rememberMe를 true로 자동 설정
      await SecureStorage.setPhoneAuthUser(true);
      await SecureStorage.savePhoneAuthSession();
      await SecureStorage.saveRememberMe(true);

      if (kDebugMode) {
        print('📝 SignUp: completeSignUp() - Phone Auth 설정 완료');
      }

      // Firestore에 사용자 정보 저장
      await _authRepository.saveUserProfileForExistingUser(
        uid: user.uid,
        name: currentState.name,
        phoneNumber: currentState.phoneNumber,
        roadNameAddress: currentState.roadNameAddress,
        locationAddress: currentState.locationAddress,
        locationTag: currentState.locationTag,
      );

      if (kDebugMode) {
        print('📝 SignUp: completeSignUp() - Firestore 저장 완료');
      }

      // Update state to completed
      state = AsyncValue.data(currentState.copyWith(
        stage: SignUpStage.completed,
        currentAction: SignUpActionType.none,
        isLoading: false,
      ));

      // 🔥 Auth State 강제 새로고침 - 회원가입 완료 후 즉시 사용자 정보 반영
      try {
        await ref
            .read(auth_state_imports.authProvider.notifier)
            .refreshAuthState();
        if (kDebugMode) {
          print('📝 SignUp: completeSignUp() - Auth State 새로고침 완료');
        }
      } catch (refreshError) {
        if (kDebugMode) {
          print(
              '📝 SignUp: completeSignUp() - Auth State 새로고침 실패: $refreshError');
        }
        // 새로고침 실패해도 회원가입 자체는 성공으로 처리
      }

      if (kDebugMode) {
        print('📝 SignUp: completeSignUp() - 회원가입 완료');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        default:
          errorMessage = '회원가입에 실패했습니다: ${e.message}';
      }

      if (kDebugMode) {
        print('📝 SignUp: completeSignUp() - Firebase Auth 에러: $errorMessage');
      }

      state = AsyncValue.data(state.value!.copyWith(
        currentAction: SignUpActionType.none,
        isLoading: false,
        errorMessage: errorMessage,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('📝 SignUp: completeSignUp() - 일반 에러: $e');
      }

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

  // 주소 검증 상태를 리셋하고 다시 입력할 수 있게 하는 메서드
  void resetAddressVerification() {
    state = AsyncValue.data(state.value!.copyWith(
      isAddressVerified: false,
      roadNameAddress: '',
      locationAddress: '',
      locationTag: '',
      address: '', // 사용자 입력 주소도 초기화
      stage: SignUpStage.locationInput, // ⭐ 중요: stage를 다시 locationInput으로 되돌림
    ));
  }
}
