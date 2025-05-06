import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/theme/index.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';

  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );

      // Registration successful - Navigate to home or profile completion
      // This will be handled by the app's wrapper based on auth state
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.padding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error message if any
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSm),
                      decoration: BoxDecoration(
                        color: ColorPalette.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusSm),
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

                  // Name field
                  AuthTextField(
                    label: '이름',
                    hintText: '실명을 입력해주세요',
                    controller: _nameController,
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: Dimensions.spacingMd),

                  // Email field
                  AuthTextField(
                    label: '이메일',
                    hintText: 'example@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: Dimensions.spacingMd),

                  // Password field
                  AuthTextField(
                    label: '비밀번호',
                    hintText: '8자 이상, 대소문자 및 특수문자 포함',
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    validator: Validators.validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDarkMode
                            ? ColorPalette.textTertiaryDark
                            : ColorPalette.textTertiaryLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingMd),

                  // Password confirm field
                  AuthTextField(
                    label: '비밀번호 확인',
                    hintText: '비밀번호를 다시 입력해주세요',
                    controller: _passwordConfirmController,
                    obscureText: !_isPasswordConfirmVisible,
                    validator: (value) => Validators.validatePasswordConfirm(
                      value,
                      _passwordController.text,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordConfirmVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: isDarkMode
                            ? ColorPalette.textTertiaryDark
                            : ColorPalette.textTertiaryLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordConfirmVisible = !_isPasswordConfirmVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingXl),

                  // Register button
                  AuthButton(
                    text: '회원가입',
                    onPressed: _handleRegister,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: Dimensions.spacingMd),

                  // Back to login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미 계정이 있으신가요?',
                        style: TextStyles.bodyMedium.copyWith(
                          color: isDarkMode
                              ? ColorPalette.textSecondaryDark
                              : ColorPalette.textSecondaryLight,
                        ),
                      ),
                      AuthButton(
                        text: '로그인',
                        onPressed: _navigateBack,
                        type: AuthButtonType.text,
                        isFullWidth: false,
                      ),
                    ],
                  ),
                  
                  // Terms and conditions
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
              ),
            ),
          ),
        ),
      ),
    );
  }
} 