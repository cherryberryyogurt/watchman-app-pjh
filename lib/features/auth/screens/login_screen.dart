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

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
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
  Future<void> _verifyAndSignIn() async {
    if (_smsCodeController.text.length != 6) {
      setState(() {
        _errorMessage = '인증번호 6자리를 모두 입력해주세요.';
      });
      return;
    }

    if (_verificationId == null) {
      setState(() {
        _errorMessage = '인증 세션이 만료되었습니다. 다시 시도해주세요.';
      });
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

      await _signInWithCredential(credential);
    } catch (e) {
      print('🔥 DEBUG: SMS 인증 오류 - $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '인증번호가 올바르지 않습니다.';
      });
    }
  }

  // Credential로 로그인 처리
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      // Auth provider를 통해 로그인 시도
      await ref.read(authProvider.notifier).signInWithPhoneNumber(
            _verificationId!,
            _smsCodeController.text,
          );

      // 로그인 성공 시 홈 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
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
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = '로그인 중 오류가 발생했습니다: $e';
      });
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
                        color: ColorPalette.error.withOpacity(0.1),
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
                        _verifyAndSignIn();
                      },
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: Dimensions.spacingLg),

                    // 로그인 버튼
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyAndSignIn,
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
