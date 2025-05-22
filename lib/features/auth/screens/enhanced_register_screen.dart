import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/signup_provider.dart';
import '../../../core/theme/index.dart';
import '../widgets/verification_code_input.dart';

class EnhancedRegisterScreen extends ConsumerStatefulWidget {
  static const routeName = '/enhanced-register';

  const EnhancedRegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EnhancedRegisterScreen> createState() => _EnhancedRegisterScreenState();
}

class _EnhancedRegisterScreenState extends ConsumerState<EnhancedRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _smsCodeController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  // SMS 인증번호 발송
  Future<void> _sendSmsVerification() async {
    if (_phoneController.text.isEmpty) {
      return;
    }

    await ref.read(signUpProvider.notifier).sendPhoneVerification();
  }

  // SMS 인증번호 확인
  Future<void> _verifySmsCode() async {
    if (_smsCodeController.text.isEmpty) {
      return;
    }

    await ref.read(signUpProvider.notifier).verifyPhoneWithCode(_smsCodeController.text);
  }

  // 이메일 인증 발송
  Future<void> _sendEmailVerification() async {
    if (_emailController.text.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      return;
    }

    await ref.read(signUpProvider.notifier).sendEmailVerification();
  }

  // 이메일 인증 상태 확인
  Future<void> _checkEmailVerification() async {
    await ref.read(signUpProvider.notifier).checkEmailVerification();
  }

  // 현재 위치 가져오기
  Future<void> _fetchCurrentLocation() async {
    await ref.read(signUpProvider.notifier).fetchCurrentLocation();
  }

  // 회원가입 완료
  Future<void> _completeSignUp() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    await ref.read(signUpProvider.notifier).completeSignUp();
  }

  // 폼 제출 처리
  void _handleFormSubmit() {
    FocusScope.of(context).unfocus();
    
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    final signUpState = ref.read(signUpProvider).value!;
    final signUpNotifier = ref.read(signUpProvider.notifier);
    
    // 현재 단계에 따라 다음 단계로 이동
    switch (signUpState.stage) {
      case SignUpStage.initial:
        // 이름 저장 후 이메일 단계로
        signUpNotifier.updateName(_nameController.text);
        signUpNotifier.moveToStage(SignUpStage.emailInput);
        break;
        
      case SignUpStage.emailInput:
        // 이메일 저장 후 이메일 인증 발송
        signUpNotifier.updateEmail(_emailController.text);
        _sendEmailVerification();
        break;
        
      case SignUpStage.emailVerified:
        // 이메일 인증 완료 후 전화번호 단계로
        signUpNotifier.moveToStage(SignUpStage.phoneInput);
        break;
        
      case SignUpStage.phoneInput:
        // 전화번호 저장 후 SMS 인증 발송
        signUpNotifier.updatePhoneNumber(_phoneController.text);
        _sendSmsVerification();
        break;
        
      case SignUpStage.phoneVerified:
        // 전화번호 인증 완료 후 위치 단계로
        signUpNotifier.moveToStage(SignUpStage.locationInput);
        break;
        
      case SignUpStage.locationVerified:
        // 위치 인증 완료 후 비밀번호 단계로
        signUpNotifier.moveToStage(SignUpStage.passwordInput);
        break;
        
      case SignUpStage.passwordInput:
        // 비밀번호 저장 후 회원가입 완료
        if (_passwordController.text == _passwordConfirmController.text) {
          signUpNotifier.updatePassword(_passwordController.text);
          _completeSignUp();
        }
        break;
        
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final signUpAsyncValue = ref.watch(signUpProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
        elevation: 0,
      ),
      body: signUpAsyncValue.when(
        data: (state) {
          final isLoading = state.isLoading;
          
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.padding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 에러 메시지 표시
                    if (state.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSm),
                        decoration: BoxDecoration(
                          color: ColorPalette.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: TextStyles.bodySmall.copyWith(
                            color: ColorPalette.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spacingMd),
                    ],
                    
                    // 회원가입 진행 단계 표시
                    _buildProgressIndicator(state),
                    const SizedBox(height: Dimensions.spacingMd),
                    
                    // 현재 단계에 따른 입력 폼 표시
                    _buildFormForCurrentStage(state),
                    
                    const SizedBox(height: Dimensions.spacingXl),
                    
                    // 다음 단계 버튼
                    _buildNextButton(state),
                    
                    // 이용약관 안내
                    if (state.stage == SignUpStage.initial) ...[
                      const SizedBox(height: Dimensions.spacingXl),
                      Text(
                        '회원가입 시 와치맨의 이용약관 및 개인정보처리방침에 동의하게 됩니다.',
                        style: TextStyles.bodySmall.copyWith(
                          color: isDarkMode
                              ? ColorPalette.textTertiaryDark
                              : ColorPalette.textTertiaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: ColorPalette.error,
                size: 48,
              ),
              const SizedBox(height: Dimensions.spacingSm),
              Text(
                '오류가 발생했습니다: $error',
                style: TextStyles.bodyMedium.copyWith(
                  color: ColorPalette.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.spacingMd),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 회원가입 진행 단계 표시기
  Widget _buildProgressIndicator(SignUpState state) {
    // 단계별 제목
    final titles = [
      '기본 정보',
      '이메일 인증',
      '전화번호 인증',
      '위치 정보',
      '비밀번호 설정',
    ];

    // 현재 단계
    int currentStep = 0;
    
    switch (state.stage) {
      case SignUpStage.initial:
        currentStep = 0;
        break;
      case SignUpStage.emailInput:
      case SignUpStage.emailVerificationSent:
      case SignUpStage.emailVerified:
        currentStep = 1;
        break;
      case SignUpStage.phoneInput:
      case SignUpStage.phoneVerificationSent:
      case SignUpStage.phoneVerified:
        currentStep = 2;
        break;
      case SignUpStage.locationInput:
      case SignUpStage.locationVerified:
        currentStep = 3;
        break;
      case SignUpStage.passwordInput:
      case SignUpStage.completed:
        currentStep = 4;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 현재 단계 제목
        Text(
          titles[currentStep],
          style: TextStyles.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Dimensions.spacingSm),
        
        // 단계 인디케이터
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            titles.length,
            (index) => Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == currentStep
                    ? ColorPalette.primary
                    : index < currentStep
                        ? ColorPalette.secondary.withOpacity(0.5)
                        : ColorPalette.placeholder,
              ),
            ),
          ),
        ),
        const SizedBox(height: Dimensions.spacingMd),
      ],
    );
  }

  // 현재 단계에 따른 폼 위젯 생성
  Widget _buildFormForCurrentStage(SignUpState state) {
    switch (state.stage) {
      case SignUpStage.initial:
        return _buildNameForm(state);
        
      case SignUpStage.emailInput:
      case SignUpStage.emailVerificationSent:
      case SignUpStage.emailVerified:
        return _buildEmailForm(state);
        
      case SignUpStage.phoneInput:
      case SignUpStage.phoneVerificationSent:
      case SignUpStage.phoneVerified:
        return _buildPhoneForm(state);
        
      case SignUpStage.locationInput:
      case SignUpStage.locationVerified:
        return _buildLocationForm(state);
        
      case SignUpStage.passwordInput:
      case SignUpStage.completed:
        return _buildPasswordForm(state);
        
      default:
        return const SizedBox.shrink();
    }
  }

  // 이름 입력 폼
  Widget _buildNameForm(SignUpState state) {
    _nameController.text = state.name;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '이름을 입력해주세요',
          style: TextStyles.titleMedium,
        ),
        const SizedBox(height: Dimensions.spacingSm),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: '이름',
            hintText: '실명을 입력해주세요',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '이름을 입력해주세요';
            }
            return null;
          },
          enabled: !state.isLoading,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  // 이메일 입력 및 인증 폼
  Widget _buildEmailForm(SignUpState state) {
    _emailController.text = state.email;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '이메일을 인증해주세요',
          style: TextStyles.titleMedium,
        ),
        const SizedBox(height: Dimensions.spacingSm),
        
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: '이메일',
            hintText: 'example@example.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            suffixIcon: state.isEmailVerified
              ? const Icon(Icons.check_circle, color: ColorPalette.success)
              : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '이메일을 입력해주세요';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return '올바른 이메일 형식이 아닙니다';
            }
            return null;
          },
          enabled: !state.isLoading && !state.isEmailVerified,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Dimensions.spacingMd),
        
        // 이메일 인증 상태에 따른 UI
        if (!state.isEmailVerified) ...[
          ElevatedButton.icon(
            onPressed: state.isLoading || !state.isEmailValid 
              ? null 
              : state.stage == SignUpStage.emailVerificationSent
                ? _checkEmailVerification
                : _sendEmailVerification,
            icon: Icon(
              state.stage == SignUpStage.emailVerificationSent
                ? Icons.refresh
                : Icons.send,
            ),
            label: Text(
              state.stage == SignUpStage.emailVerificationSent
                ? '인증 상태 확인하기'
                : '인증 메일 발송하기',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: Dimensions.spacingSm),
          
          if (state.stage == SignUpStage.emailVerificationSent) ...[
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSm),
              decoration: BoxDecoration(
                color: ColorPalette.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              ),
              child: Column(
                children: [
                  Text(
                    '인증 메일이 발송되었습니다.',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.info,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingXs),
                  Text(
                    '메일함을 확인하여 인증 링크를 클릭해주세요.\n인증 완료 후 아래 버튼을 눌러 진행하세요.',
                    style: TextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          // 이메일 인증 완료 상태 표시
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSm),
            decoration: BoxDecoration(
              color: ColorPalette.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: ColorPalette.success,
                ),
                const SizedBox(width: Dimensions.spacingSm),
                Expanded(
                  child: Text(
                    '이메일 인증이 완료되었습니다.',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ColorPalette.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 전화번호 입력 및 인증 폼
  Widget _buildPhoneForm(SignUpState state) {
    _phoneController.text = state.phoneNumber;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '전화번호를 인증해주세요',
          style: TextStyles.titleMedium,
        ),
        const SizedBox(height: Dimensions.spacingSm),
        
        // 전화번호 입력 필드
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: '전화번호',
            hintText: '01012345678',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            suffixIcon: state.isPhoneVerified
              ? const Icon(Icons.check_circle, color: ColorPalette.success)
              : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '전화번호를 입력해주세요';
            }
            final cleanedValue = value.replaceAll('-', '');
            if (!RegExp(r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$').hasMatch(cleanedValue)) {
              return '올바른 전화번호 형식이 아닙니다';
            }
            return null;
          },
          enabled: !state.isLoading && !state.isPhoneVerified,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Dimensions.spacingMd),
        
        // 전화번호 인증 상태에 따른 UI
        if (!state.isPhoneVerified) ...[
          if (state.stage == SignUpStage.phoneInput) ...[
            // SMS 인증번호 발송 버튼
            ElevatedButton.icon(
              onPressed: state.isLoading || !state.isPhoneNumberValid ? null : _sendSmsVerification,
              icon: const Icon(Icons.sms_outlined),
              label: const Text('인증번호 발송하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ] else if (state.stage == SignUpStage.phoneVerificationSent) ...[
            // SMS 인증번호 입력 필드
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'SMS로 전송된 인증번호를 입력해주세요',
                  style: TextStyles.bodyMedium,
                ),
                const SizedBox(height: Dimensions.spacingSm),
                
                // 인증번호 입력
                VerificationCodeInput(
                  controller: _smsCodeController,
                  onCompleted: (value) {
                    _verifySmsCode();
                  },
                  enabled: !state.isLoading,
                ),
                const SizedBox(height: Dimensions.spacingMd),
                
                // 인증번호 확인 버튼
                ElevatedButton(
                  onPressed: state.isLoading || _smsCodeController.text.length < 6 ? null : _verifySmsCode,
                  child: const Text('인증번호 확인하기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: Dimensions.spacingSm),
                
                // 인증번호 재전송 버튼
                TextButton(
                  onPressed: state.isLoading ? null : _sendSmsVerification,
                  child: const Text('인증번호 재전송하기'),
                ),
              ],
            ),
          ],
        ] else ...[
          // 전화번호 인증 완료 상태 표시
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSm),
            decoration: BoxDecoration(
              color: ColorPalette.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: ColorPalette.success,
                ),
                const SizedBox(width: Dimensions.spacingSm),
                Expanded(
                  child: Text(
                    '전화번호 인증이 완료되었습니다.',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ColorPalette.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 위치 정보 입력 및 인증 폼
  Widget _buildLocationForm(SignUpState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '위치 정보를 입력해주세요',
          style: TextStyles.titleMedium,
        ),
        const SizedBox(height: Dimensions.spacingSm),
        
        // 현재 위치 가져오기 버튼
        if (!state.isAddressVerified) ...[
          ElevatedButton.icon(
            onPressed: state.isLoading ? null : _fetchCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('현재 위치 가져오기'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: Dimensions.spacingSm),
          
          Text(
            '또는 직접 주소를 입력해주세요',
            style: TextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.spacingMd),
        ],
        
        // 주소 표시 또는 입력 필드
        if (state.isAddressVerified) ...[
          // 도로명 주소 표시
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSm),
            decoration: BoxDecoration(
              color: ColorPalette.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '도로명 주소',
                  style: TextStyles.bodySmall.copyWith(
                    color: ColorPalette.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: Dimensions.spacingXs),
                Text(
                  state.roadNameAddress,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.spacingSm),
          
          // 지번 주소 표시
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSm),
            decoration: BoxDecoration(
              color: ColorPalette.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '지번 주소',
                  style: TextStyles.bodySmall.copyWith(
                    color: ColorPalette.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: Dimensions.spacingXs),
                Text(
                  state.locationAddress,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.spacingSm),
          
          // 위치 태그 표시
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSm),
            decoration: BoxDecoration(
              color: ColorPalette.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '위치 태그',
                  style: TextStyles.bodySmall.copyWith(
                    color: ColorPalette.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: Dimensions.spacingXs),
                Text(
                  state.locationTag,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.spacingMd),
          
          // 주소 다시 가져오기 버튼
          TextButton.icon(
            onPressed: state.isLoading ? null : _fetchCurrentLocation,
            icon: const Icon(Icons.refresh),
            label: const Text('주소 다시 가져오기'),
          ),
        ] else ...[
          // 아직 주소를 가져오지 않은 경우 안내 메시지
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSm),
            decoration: BoxDecoration(
              color: ColorPalette.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: ColorPalette.info,
                  size: 24,
                ),
                const SizedBox(height: Dimensions.spacingSm),
                Text(
                  '현재 위치를 사용하면 GPS 좌표를 기반으로 주소를 자동으로 가져옵니다.',
                  style: TextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dimensions.spacingXs),
                Text(
                  '위치 서비스를 활성화하고 권한을 허용해주세요.',
                  style: TextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 비밀번호 입력 폼
  Widget _buildPasswordForm(SignUpState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '비밀번호를 설정해주세요',
          style: TextStyles.titleMedium,
        ),
        const SizedBox(height: Dimensions.spacingSm),
        
        // 비밀번호 입력 필드
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: '비밀번호',
            hintText: '8자 이상, 영문+숫자 조합 권장',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '비밀번호를 입력해주세요';
            }
            if (value.length < 6) {
              return '비밀번호는 최소 6자 이상이어야 합니다';
            }
            return null;
          },
          enabled: !state.isLoading,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Dimensions.spacingMd),
        
        // 비밀번호 확인 입력 필드
        TextFormField(
          controller: _passwordConfirmController,
          obscureText: !_isPasswordConfirmVisible,
          decoration: InputDecoration(
            labelText: '비밀번호 확인',
            hintText: '비밀번호를 다시 입력해주세요',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordConfirmVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordConfirmVisible = !_isPasswordConfirmVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '비밀번호 확인을 입력해주세요';
            }
            if (value != _passwordController.text) {
              return '비밀번호가 일치하지 않습니다';
            }
            return null;
          },
          enabled: !state.isLoading,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: Dimensions.spacingMd),
        
        // 비밀번호 강도 안내
        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSm),
          decoration: BoxDecoration(
            color: ColorPalette.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusSm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '안전한 비밀번호 만들기',
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Dimensions.spacingSm),
              Text(
                '• 최소 8자 이상 입력\n• 영문, 숫자, 특수문자 조합 권장\n• 개인정보와 관련없는 문자 조합 권장',
                style: TextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 다음 단계 버튼
  Widget _buildNextButton(SignUpState state) {
    String buttonText = '다음';
    bool isEnabled = true;

    switch (state.stage) {
      case SignUpStage.initial:
        isEnabled = state.name.isNotEmpty;
        break;
        
      case SignUpStage.emailInput:
        buttonText = '이메일 인증하기';
        isEnabled = state.isEmailValid;
        break;
        
      case SignUpStage.emailVerificationSent:
        buttonText = '인증 상태 확인하기';
        break;
        
      case SignUpStage.emailVerified:
        buttonText = '전화번호 인증으로 진행하기';
        break;
        
      case SignUpStage.phoneInput:
        buttonText = '전화번호 인증하기';
        isEnabled = state.isPhoneNumberValid;
        break;
        
      case SignUpStage.phoneVerificationSent:
        buttonText = '인증번호 확인하기';
        isEnabled = _smsCodeController.text.length == 6;
        break;
        
      case SignUpStage.phoneVerified:
        buttonText = '위치 정보 입력으로 진행하기';
        break;
        
      case SignUpStage.locationInput:
        buttonText = '현재 위치 가져오기';
        break;
        
      case SignUpStage.locationVerified:
        buttonText = '비밀번호 설정으로 진행하기';
        break;
        
      case SignUpStage.passwordInput:
        buttonText = '회원가입 완료하기';
        isEnabled = _passwordController.text.isNotEmpty && 
                   _passwordController.text == _passwordConfirmController.text &&
                   _passwordController.text.length >= 6;
        break;
        
      case SignUpStage.completed:
        buttonText = '로그인 화면으로 이동하기';
        break;
    }

    return ElevatedButton(
      onPressed: (state.isLoading || !isEnabled) ? null : _handleFormSubmit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: Dimensions.padding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusSm),
        ),
        backgroundColor: ColorPalette.primary,
        foregroundColor: Colors.white,
      ),
      child: state.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(buttonText),
    );
  }
} 