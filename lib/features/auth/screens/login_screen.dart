import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_state.dart';
import 'register_screen.dart';
import '../../../core/theme/index.dart';
import '../widgets/verification_code_input.dart';

enum LoginStage {
  phoneInput,
  verificationSent,
}

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  bool _rememberMe = true;

  LoginStage _currentStage = LoginStage.phoneInput;
  String? _verificationId;
  int? _resendToken;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastAuthAttempt; // 마지막 인증 시도 시간 추적
  static const Duration _authCooldown = Duration(seconds: 2); // 인증 시도 간 최소 간격

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  // 전화번호를 01012345678 형식으로 정규화
  String _normalizePhoneNumber(String phoneNumber) {
    // 공백, 하이픈 제거
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');

    // +821012345678 → 01012345678
    if (cleaned.startsWith('+82')) {
      cleaned = '0${cleaned.substring(3)}';
    }
    // 1012345678 → 01012345678
    else if (cleaned.length == 10 && cleaned.startsWith('1')) {
      cleaned = '0$cleaned';
    }

    return cleaned;
  }

  // 전화번호로 회원가입 여부 확인
  Future<bool> _checkUserExists(String phoneNumber) async {
    try {
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);
      return await ref
          .read(authProvider.notifier)
          .checkUserExistsByPhoneNumber(normalizedPhone);
    } catch (e) {
      print('🔥 DEBUG: 사용자 조회 오류 - $e');
      // 조회 실패 시 안전하게 진행하기 위해 true 반환
      return true;
    }
  }

  // 미가입자 모달 표시
  void _showUnregisteredUserModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusMd),
          ),
          contentPadding: const EdgeInsets.all(Dimensions.padding),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 이모지와 메인 메시지
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSm),
                decoration: BoxDecoration(
                  color: ColorPalette.info.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '👋',
                  style: TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: Dimensions.spacingMd),

              Text(
                '아직 와치맨 회원이 아니시네요!',
                style: TextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.spacingLg),

              // Text(
              //   '간편하게 회원가입하고\n와치맨을 이용해보세요!',
              //   style: TextStyles.bodyMedium.copyWith(
              //     color: Theme.of(context).brightness == Brightness.dark
              //         ? ColorPalette.textSecondaryDark
              //         : ColorPalette.textSecondaryLight,
              //   ),
              //   textAlign: TextAlign.center,
              // ),
              // const SizedBox(height: Dimensions.spacingLg),

              // 버튼들
              Row(
                children: [
                  // 취소 버튼
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSm),

                  // 회원가입 버튼
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushNamed(context, RegisterScreen.routeName);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
                        ),
                        backgroundColor: ColorPalette.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('회원가입'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 인증 실패 모달 표시
  void _showAuthenticationErrorModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusMd),
          ),
          contentPadding: const EdgeInsets.all(Dimensions.padding),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 에러 아이콘
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSm),
                decoration: BoxDecoration(
                  color: ColorPalette.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 32,
                  color: ColorPalette.error,
                ),
              ),
              const SizedBox(height: Dimensions.spacingMd),

              Text(
                '인증 실패',
                style: TextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.spacingMd),

              Text(
                '인증 번호를 올바르게 입력해주세요.',
                style: TextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? ColorPalette.textSecondaryDark
                      : ColorPalette.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.spacingLg),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.paddingSm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                    ),
                    backgroundColor: ColorPalette.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 전화번호 인증 발송
  Future<void> _sendPhoneVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1️⃣ 먼저 회원가입 여부 확인
      print('🔥 DEBUG: 회원가입 여부 확인 시작');
      final userExists = await _checkUserExists(_phoneController.text);

      if (!userExists) {
        // 미가입자인 경우 모달 표시 후 종료
        setState(() {
          _isLoading = false;
        });
        _showUnregisteredUserModal();
        return;
      }

      // 2️⃣ 가입된 사용자인 경우 전화번호 인증 진행
      print('🔥 DEBUG: 기존 회원 확인, 전화번호 인증 진행');

      // 한국 전화번호를 E.164 형식으로 변환
      String phoneNumber = _phoneController.text.replaceAll('-', '');
      if (phoneNumber.startsWith('01')) {
        phoneNumber = '+82${phoneNumber.substring(1)}';
      } else if (phoneNumber.startsWith('0')) {
        phoneNumber = '+82${phoneNumber.substring(1)}';
      } else {
        phoneNumber = '+82$phoneNumber';
      }

      print('🔥 DEBUG: 전화번호 인증 발송 - $phoneNumber');

      // Verification completed callback
      verificationCompleted(PhoneAuthCredential credential) async {
        print('🔥 DEBUG: 자동 인증 완료');
        await _signInWithCredential(credential);
      }

      // Verification failed callback
      verificationFailed(FirebaseAuthException e) {
        print('🔥 DEBUG: 인증 실패 - ${e.code}: ${e.message}');
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e.code);
        });
      }

      // Code sent callback
      codeSent(String verificationId, int? resendToken) {
        print('🔥 DEBUG: 인증번호 발송 완료');
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _currentStage = LoginStage.verificationSent;
          _isLoading = false;
          _errorMessage = null;
        });
      }

      // Code auto retrieval timeout callback
      codeAutoRetrievalTimeout(String verificationId) {
        print('🔥 DEBUG: 자동 인증 시간 초과');
      }

      // Send verification code
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(minutes: 2),
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      print('🔥 DEBUG: 전화번호 인증 발송 오류 - $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '전화번호 인증 발송 중 오류가 발생했습니다: $e';
      });
    }
  }

  // SMS 인증번호로 로그인
  Future<void> _verifyAndSignIn([String source = 'unknown']) async {
    print('🔥 DEBUG: _verifyAndSignIn called from: $source');

    // 이미 로그인 진행 중이면 중복 실행 방지
    if (_isLoading) {
      print('🔥 DEBUG: 이미 로그인 진행 중, 중복 실행 방지 (source: $source)');
      return;
    }

    // 쿨다운 체크 - 너무 빠른 연속 호출 방지
    final now = DateTime.now();
    if (_lastAuthAttempt != null &&
        now.difference(_lastAuthAttempt!) < _authCooldown) {
      print('🔥 DEBUG: 인증 쿨다운 중, 시도 무시 (source: $source)');
      return;
    }

    _lastAuthAttempt = now;

    if (_smsCodeController.text.length != 6) {
      setState(() {
        _errorMessage = '인증번호 6자리를 모두 입력해주세요.';
      });
      _smsCodeController.clear();
      return;
    }

    if (_verificationId == null) {
      setState(() {
        _errorMessage = '인증 세션이 만료되었습니다. 다시 시도해주세요.';
      });
      _smsCodeController.clear();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // PhoneAuthCredential 생성
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _smsCodeController.text,
      );

      final success = await _signInWithCredential(credential);

      // _signInWithCredential()에서 이미 모든 에러 처리를 했으므로
      // 여기서는 성공 시에만 로딩 상태를 해제
      if (success) {
        setState(() {
          _isLoading = false;
        });
      }
      // 실패 시 로딩 상태 해제는 _signInWithCredential()에서 이미 처리됨
    } catch (e) {
      // PhoneAuthCredential 생성 실패 등 예상치 못한 에러만 여기서 처리
      print('🔥 DEBUG: SMS 인증 오류 - $e');
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });

      _smsCodeController.clear();
      _showAuthenticationErrorModal();
    }
  }

  // Credential로 로그인 처리
  Future<bool> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      // Auth provider를 통해 로그인 시도
      await ref.read(authProvider.notifier).signInWithPhoneNumber(
            _verificationId!,
            _smsCodeController.text,
          );

      // 로그인 성공 시에만 홈 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
      return true; // 성공 시 true 반환
    } catch (e) {
      print('🔥 DEBUG: 로그인 처리 오류 - $e');

      // USER_NOT_FOUND 에러인 경우 회원가입 화면으로 이동
      if (e.toString().contains('USER_NOT_FOUND')) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RegisterScreen.routeName,
            (route) => false,
          );
        }
        return false; // 회원가입 페이지로 이동하는 경우 false 반환
      }

      // 인증 실패 시 로딩 상태 해제하고 SMS 코드 초기화
      setState(() {
        _isLoading = false;
        _errorMessage = null; // 텍스트 에러 메시지 제거
      });

      // SMS 코드 입력 필드 초기화하여 다시 입력할 수 있도록 함
      _smsCodeController.clear();

      // 에러 모달 표시 (invalid-verification-code 등 모든 인증 오류)
      _showAuthenticationErrorModal();
      return false; // 실패 시 false 반환
    }
  }

  // Firebase Auth 에러 코드를 한국어 메시지로 변환
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-phone-number':
        return '올바른 전화번호 형식이 아닙니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 'quota-exceeded':
        return 'SMS 발송 한도가 초과되었습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '인증 중 오류가 발생했습니다. 다시 시도해주세요.';
    }
  }

  // 처음부터 다시 시작
  void _resetToPhoneInput() {
    setState(() {
      _currentStage = LoginStage.phoneInput;
      _verificationId = null;
      _resendToken = null;
      _smsCodeController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.padding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '와치맨',
                    style: TextStyles.displaySmall.copyWith(
                      color: ColorPalette.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spacingXs),
                  Text(
                    '전화번호로 간편하게 로그인하세요',
                    style: TextStyles.bodyMedium.copyWith(
                      color: isDarkMode
                          ? ColorPalette.textSecondaryDark
                          : ColorPalette.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spacingXl),

                  // 에러 메시지 표시
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSm),
                      decoration: BoxDecoration(
                        color: ColorPalette.error.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSm),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyles.bodySmall.copyWith(
                          color: ColorPalette.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: Dimensions.spacingMd),
                  ],

                  // 전화번호 입력 단계
                  if (_currentStage == LoginStage.phoneInput) ...[
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: '전화번호',
                        hintText: '01012345678',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '전화번호를 입력해주세요';
                        }
                        final cleanedValue = value.replaceAll('-', '');
                        if (!RegExp(
                                r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$')
                            .hasMatch(cleanedValue)) {
                          return '올바른 전화번호 형식이 아닙니다';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                    ),
                    const SizedBox(height: Dimensions.spacingSm),

                    // 로그인 상태 유지 체크박스
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? true;
                            });
                          },
                        ),
                        Text(
                          '로그인 상태 유지',
                          style: TextStyles.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.spacingLg),

                    // 인증번호 발송 버튼
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendPhoneVerification,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.padding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('전화번호로 로그인'),
                    ),
                  ],

                  // SMS 인증번호 입력 단계
                  if (_currentStage == LoginStage.verificationSent) ...[
                    Text(
                      'SMS로 전송된 인증번호를 입력해주세요',
                      style: TextStyles.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Dimensions.spacingSm),
                    Text(
                      _phoneController.text,
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Dimensions.spacingLg),

                    // 인증번호 입력
                    VerificationCodeInput(
                      controller: _smsCodeController,
                      onCompleted: (value) {
                        print(
                            '🔥 DEBUG: VerificationCodeInput onCompleted triggered with value: $value');
                        _verifyAndSignIn('VerificationCodeInput.onCompleted');
                      },
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: Dimensions.spacingLg),

                    // 로그인 버튼
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              print('🔥 DEBUG: Login button pressed');
                              _verifyAndSignIn('LoginButton.onPressed');
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.padding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('로그인'),
                    ),
                    const SizedBox(height: Dimensions.spacingMd),

                    // 인증번호 재전송 및 전화번호 변경 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : _sendPhoneVerification,
                          child: Text(
                            '인증번호 재전송',
                            style: TextStyles.bodySmall.copyWith(
                              color: ColorPalette.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _resetToPhoneInput,
                          child: Text(
                            '전화번호 변경',
                            style: TextStyles.bodySmall.copyWith(
                              color: ColorPalette.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: Dimensions.spacingXl),

                  // 회원가입 링크
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '계정이 없으신가요?',
                        style: TextStyles.bodyMedium.copyWith(
                          color: isDarkMode
                              ? ColorPalette.textSecondaryDark
                              : ColorPalette.textSecondaryLight,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  RegisterScreen.routeName,
                                );
                              },
                        child: Text(
                          '회원가입',
                          style: TextStyles.bodyMedium.copyWith(
                            color: ColorPalette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
