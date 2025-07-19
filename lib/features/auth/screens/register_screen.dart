import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/signup_provider.dart';
import '../../../core/theme/index.dart';
import '../widgets/verification_code_input.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  static const routeName = '/register';

  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() {
    debugPrint('🏗️ RegisterScreen createState() called');
    return _RegisterScreenState();
  }
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController(); // 주소 입력 컨트롤러
  final _detailedAddressController = TextEditingController(); // 상세 주소 입력 컨트롤러
  final _smsCodeController = TextEditingController();

  // 이전 단계 추적으로 컨트롤러 업데이트 시점 제어
  SignUpStage? _previousStage;

  _RegisterScreenState() {
    debugPrint('🎯 _RegisterScreenState constructor called');
  }

  @override
  void initState() {
    debugPrint('🚀 RegisterScreen initState() called');
    super.initState();
    debugPrint('📱 Adding SMS code listener...');
    _smsCodeController.addListener(_onSmsCodeChanged);

    // 주소 입력 컨트롤러 리스너 추가
    debugPrint('🏠 Adding address controller listener...');
    _addressController.addListener(() {
      debugPrint('🏠 Address controller changed: ${_addressController.text}');
      setState(() {});
    });

    // 상세 주소 입력 컨트롤러 리스너 추가
    debugPrint('🏡 Adding detailed address controller listener...');
    _detailedAddressController.addListener(() {
      debugPrint(
          '🏡 Detailed address controller changed: ${_detailedAddressController.text}');
      setState(() {});
    });

    // 초기 상태에서 컨트롤러 초기화는 제거 - watch를 통해 자동으로 처리됨
  }

  @override
  void dispose() {
    debugPrint('🗑️ RegisterScreen dispose() called');
    _smsCodeController.removeListener(_onSmsCodeChanged);

    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose(); // 주소 컨트롤러 dispose
    _detailedAddressController.dispose(); // 상세 주소 컨트롤러 dispose
    _smsCodeController.dispose();
    super.dispose();
  }

  // 컨트롤러와 provider 상태 동기화
  void _syncControllersWithState(SignUpState state) {
    if (!mounted) return;
    
    if (_previousStage != state.stage) {
      _nameController.text = state.name;
      _phoneController.text = state.phoneNumber;
      _addressController.text = state.address;
      _detailedAddressController.text = state.detailedAddress;
      _previousStage = state.stage;
      debugPrint('🔄 Controllers synced for stage: ${state.stage}');
    }
  }

  void _onSmsCodeChanged() {
    // 🔥 최적화: SMS 코드 길이 변경 시에만 UI 업데이트
    if (mounted) {
      setState(() {
        // SMS 코드 입력 시 버튼 상태 업데이트
      });
    }
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

    await ref
        .read(signUpProvider.notifier)
        .verifyPhoneWithCode(_smsCodeController.text);
  }

  // 주소 검증 및 등록 처리
  Future<void> _validateAndRegisterAddress() async {
    if (_addressController.text.trim().isEmpty) {
      return;
    }

    await ref
        .read(signUpProvider.notifier)
        .validateAndRegisterAddress(_addressController.text.trim());
  }

  // 회원가입 완료
  Future<void> _completeSignUp() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    await ref.read(signUpProvider.notifier).completeSignUp();
  }

  // 폼 제출 처리
  Future<void> _handleFormSubmit() async {
    debugPrint('📝 _handleFormSubmit() called');
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) {
      debugPrint('❌ Form validation failed');
      return;
    }

    final currentState = ref.read(signUpProvider);
    if (!currentState.hasValue) {
      debugPrint('❌ SignUp provider has no value');
      return;
    }

    final signUpState = currentState.value!;
    final signUpNotifier = ref.read(signUpProvider.notifier);
    debugPrint('📝 Form submit - current stage: ${signUpState.stage}');

    // 현재 단계에 따라 다음 단계로 이동
    switch (signUpState.stage) {
      case SignUpStage.initial:
        // 이름 저장 후 위치 단계로
        signUpNotifier.updateName(_nameController.text);
        signUpNotifier.moveToStage(SignUpStage.locationInput);
        break;

      case SignUpStage.locationInput:
        // 위치 정보 입력 단계에서 주소 검증 호출
        _validateAndRegisterAddress();
        break;

      case SignUpStage.locationVerified:
        // 위치 인증 완료 후 전화번호 단계로
        signUpNotifier.moveToStage(SignUpStage.phoneInput);
        break;

      case SignUpStage.phoneInput:
        // 전화번호 저장 후 SMS 인증 발송
        signUpNotifier.updatePhoneNumber(_phoneController.text);
        _sendSmsVerification();
        break;

      case SignUpStage.phoneVerified:
        // 전화번호 인증 완료 후 회원가입 완료
        _completeSignUp();
        break;

      case SignUpStage.completed:
        // 홈 화면으로 이동
        _navigateToHome();
        break;

      case SignUpStage.phoneVerificationSent:
        break;
    }
  }

  // 홈 화면 이동 메서드 - 로그인 화면 대신 홈으로 바로 이동
  void _navigateToHome() {
    // 모든 이전 화면을 제거하고 홈 화면으로 이동
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false, // 모든 이전 화면 제거
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ RegisterScreen build() called');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    debugPrint('🎨 isDarkMode: $isDarkMode');

    debugPrint('📡 About to watch signUpProvider...');
    try {
      final signUpAsyncValue = ref.watch(signUpProvider);
      debugPrint(
          '📡 signUpProvider watched successfully: ${signUpAsyncValue.runtimeType}');

      return Scaffold(
        appBar: AppBar(
          title: const Text('회원가입'),
          centerTitle: true,
          elevation: 0,
        ),
        body: signUpAsyncValue.when(
          data: (state) {
            debugPrint(
                '✅ signUpAsyncValue.when data callback - stage: ${state.stage}');
            
            // 컨트롤러 동기화
            _syncControllersWithState(state);

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
                            color: ColorPalette.error.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusSm),
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
          loading: () {
            debugPrint('⏳ signUpAsyncValue.when loading callback');
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
          error: (error, stack) {
            debugPrint('❌ signUpAsyncValue.when error callback: $error');
            debugPrint('❌ Stack trace: $stack');
            return Center(
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
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error watching signUpProvider: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      return Scaffold(
        appBar: AppBar(
          title: const Text('회원가입'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Provider 초기화 오류: $e',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      );
    }
  }

  // 회원가입 진행 단계 표시기 - 4단계로 축소
  Widget _buildProgressIndicator(SignUpState state) {
    // 단계별 제목 - 이메일/비밀번호 단계 제거
    final titles = [
      '기본 정보',
      '위치 정보',
      '전화번호 인증',
      '회원가입 완료',
    ];

    // 현재 단계
    int currentStep = 0;

    switch (state.stage) {
      case SignUpStage.initial:
        currentStep = 0;
        break;
      case SignUpStage.locationInput:
      case SignUpStage.locationVerified:
        currentStep = 1;
        break;
      case SignUpStage.phoneInput:
      case SignUpStage.phoneVerificationSent:
      case SignUpStage.phoneVerified:
        currentStep = 2;
        break;
      case SignUpStage.completed:
        currentStep = 3;
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
                        ? ColorPalette.secondary.withValues(alpha: 0.5)
                        : ColorPalette.placeholder,
              ),
            ),
          ),
        ),
        const SizedBox(height: Dimensions.spacingMd),
      ],
    );
  }

  // 현재 단계에 따른 폼 위젯 생성 - 이메일/비밀번호 단계 제거
  Widget _buildFormForCurrentStage(SignUpState state) {
    switch (state.stage) {
      case SignUpStage.initial:
        return _buildNameForm(state);

      case SignUpStage.phoneInput:
      case SignUpStage.phoneVerificationSent:
      case SignUpStage.phoneVerified:
        return _buildPhoneForm(state);

      case SignUpStage.locationInput:
      case SignUpStage.locationVerified:
        return _buildLocationForm(state);

      case SignUpStage.completed:
        return _buildCompletionForm(state);
    }
  }

  // 이름 입력 폼
  Widget _buildNameForm(SignUpState state) {
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
          onChanged: (value) {
            print(
                '📝 Name onChanged: "$value", controller: "${_nameController.text}"'); // TODO: 디버깅용
            setState(() {
              // 버튼 상태 실시간 업데이트
            });
          },
        ),
        const SizedBox(height: Dimensions.spacingMd),
      ],
    );
  }

  // 전화번호 입력 및 인증 폼
  Widget _buildPhoneForm(SignUpState state) {
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
            if (!RegExp(r'^01([0|1|6|7|8|9])-?([0-9]{3,4})-?([0-9]{4})$')
                .hasMatch(cleanedValue)) {
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
          onChanged: (value) {
            print('📞 Phone onChanged: "$value"'); // TODO: 디버깅용

            ref.read(signUpProvider.notifier).updatePhoneNumber(value);
            setState(() {});
          },
        ),
        const SizedBox(height: Dimensions.spacingMd),

        // 전화번호 인증 상태에 따른 UI
        if (!state.isPhoneVerified) ...[
          if (state.stage == SignUpStage.phoneVerificationSent) ...[
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
              color: ColorPalette.success.withValues(alpha: 0.1),
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

  bool _isPhoneNumberValid() {
    final phone = _phoneController.text.replaceAll('-', '');
    return phone.isNotEmpty &&
        RegExp(r'^01([0|1|6|7|8|9])([0-9]{3,4})([0-9]{4})$').hasMatch(phone);
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

        // GPS 권한 안내 메시지
        if (!state.isAddressVerified) ...[
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSm),
            decoration: BoxDecoration(
              color: ColorPalette.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: ColorPalette.info, size: 20),
                const SizedBox(width: Dimensions.spacingSm),
                Expanded(
                  child: Text(
                    '동네 인증을 위해 현재 위치 정보가 필요합니다',
                    style: TextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.spacingMd),

          // 주소 입력 필드
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: '도로명 주소',
              hintText: '예: 서울특별시 강남구 테헤란로 123',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '주소를 입력해주세요';
              }
              return null;
            },
            onChanged: (value) {
              ref.read(signUpProvider.notifier).updateAddress(value);
            },
            enabled: !state.isLoading && !state.isAddressVerified,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: Dimensions.spacingMd),

          // 상세 주소 입력 필드
          TextFormField(
            controller: _detailedAddressController,
            decoration: InputDecoration(
              labelText: '상세 주소',
              hintText: '동/호수 등 (예: 101동 202호)',
              prefixIcon: const Icon(Icons.home_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              ),
            ),
            onChanged: (value) {
              ref.read(signUpProvider.notifier).updateDetailedAddress(value);
            },
            enabled: !state.isLoading && !state.isAddressVerified,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: Dimensions.spacingMd),
        ],

        // 주소 표시 또는 입력 필드
        if (state.isAddressVerified) ...[
          // 도로명 주소 표시
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSm),
            decoration: BoxDecoration(
              color: ColorPalette.info.withValues(alpha: 0.1),
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

          // // 지번 주소 표시
          // Container(
          //   padding: const EdgeInsets.all(Dimensions.paddingSm),
          //   decoration: BoxDecoration(
          //     color: ColorPalette.info.withValues(alpha: 0.1),
          //     borderRadius: BorderRadius.circular(Dimensions.radiusSm),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         '지번 주소',
          //         style: TextStyles.bodySmall.copyWith(
          //           color: ColorPalette.textSecondaryLight,
          //         ),
          //       ),
          //       const SizedBox(height: Dimensions.spacingXs),
          //       Text(
          //         state.locationAddress,
          //         style: TextStyles.bodyMedium.copyWith(
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: Dimensions.spacingSm),

          // // 위치 태그 표시
          // Container(
          //   padding: const EdgeInsets.all(Dimensions.paddingSm),
          //   decoration: BoxDecoration(
          //     color: ColorPalette.info.withValues(alpha: 0.1),
          //     borderRadius: BorderRadius.circular(Dimensions.radiusSm),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         '위치 태그',
          //         style: TextStyles.bodySmall.copyWith(
          //           color: ColorPalette.textSecondaryLight,
          //         ),
          //       ),
          //       const SizedBox(height: Dimensions.spacingXs),
          //       Text(
          //         state.locationTag,
          //         style: TextStyles.bodyMedium.copyWith(
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: Dimensions.spacingMd),

          // 주소 다시 입력하기 버튼
          TextButton.icon(
            onPressed: state.isLoading ? null : _resetAddressInput,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('주소 다시 입력하기'),
          ),
        ] else ...[
          // 아직 주소를 가져오지 않은 경우 안내 메시지
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSm),
            decoration: BoxDecoration(
              color: ColorPalette.info.withValues(alpha: 0.1),
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
                  '입력하신 주소를 검증하여 현재 위치와의 거리를 확인합니다.',
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

  Widget _buildCompletionForm(SignUpState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 완료 아이콘
        Container(
          padding: const EdgeInsets.all(Dimensions.spacingXl),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: ColorPalette.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: Dimensions.spacingLg),

              // 완료 메시지
              Text(
                '회원가입이 완료되었습니다!',
                style: TextStyles.headlineMedium.copyWith(
                  color: ColorPalette.success,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.spacingSm),

              Text(
                '와치맨의 다양한 서비스를 이용해보세요',
                style: TextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: Dimensions.spacingLg),

        // 등록된 정보 요약
        Container(
          padding: const EdgeInsets.all(Dimensions.padding),
          decoration: BoxDecoration(
            color: ColorPalette.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            border: Border.all(
              color: ColorPalette.success.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '등록 정보',
                style: TextStyles.titleSmall.copyWith(
                  color: ColorPalette.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Dimensions.spacingSm),
              _buildInfoRow('이름', state.name),
              _buildInfoRow('전화번호', state.phoneNumber),
              if (state.locationTagName.isNotEmpty)
                _buildInfoRow('지역', state.locationTagName),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyles.bodySmall.copyWith(
                color: ColorPalette.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(SignUpState state) {
    String buttonText = '다음';
    bool isEnabled = true;

    switch (state.stage) {
      case SignUpStage.initial:
        isEnabled = _nameController.text.trim().isNotEmpty;
        print(
            '🔘 Button state - Name: "${_nameController.text}", Enabled: $isEnabled'); // TODO: 디버깅용
        break;

      case SignUpStage.phoneInput:
        buttonText = '전화번호 인증하기';
        isEnabled = _isPhoneNumberValid();
        print(
            '🔘 Button state - Phone: "${_phoneController.text}", Valid: $isEnabled'); // TODO: 디버깅용
        break;

      case SignUpStage.phoneVerificationSent:
        buttonText = '인증번호 확인하기';
        isEnabled = _smsCodeController.text.length == 6;
        print(
            '🔘 Button state - SMS: "${_smsCodeController.text}", Valid: $isEnabled'); // TODO: 디버깅용
        break;

      case SignUpStage.phoneVerified:
        buttonText = '회원가입 완료하기';

        break;

      case SignUpStage.locationInput:
        buttonText = '내 주소 등록하기';
        isEnabled = _addressController.text.trim().isNotEmpty &&
            !state.isAddressVerified;
        break;

      case SignUpStage.locationVerified:
        buttonText = '전화번호 입력으로 진행하기';
        isEnabled = state.isAddressVerified;
        break;

      case SignUpStage.completed:
        buttonText = '시작하기';
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

  // 주소 검증 상태를 리셋하고 다시 입력하도록 하는 메서드
  void _resetAddressInput() {
    // Provider의 resetAddressVerification 메서드 호출
    ref.read(signUpProvider.notifier).resetAddressVerification();

    // 주소 입력 컨트롤러 초기화
    _addressController.clear();
    _detailedAddressController.clear();

    // UI 업데이트
    setState(() {});
  }
}
