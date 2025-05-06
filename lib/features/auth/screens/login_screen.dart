import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/theme/index.dart';
import 'register_screen.dart';
import 'password_reset_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
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
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Login successful - Navigate to home screen
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

  void _navigateToRegister() {
    Navigator.of(context).pushNamed(RegisterScreen.routeName);
  }

  void _navigateToPasswordReset() {
    Navigator.of(context).pushNamed(PasswordResetScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.padding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Dimensions.spacingXl),
                  // App logo or title
                  Center(
                    child: Text(
                      '와치맨',
                      style: TextStyles.displaySmall.copyWith(
                        color: ColorPalette.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingLg),
                  
                  // Welcome text
                  Text(
                    '환영합니다!',
                    style: TextStyles.headlineMedium.copyWith(
                      color: isDarkMode 
                          ? ColorPalette.textPrimaryDark 
                          : ColorPalette.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '로그인하고 와치맨을 이용해보세요',
                    style: TextStyles.bodyLarge.copyWith(
                      color: isDarkMode 
                          ? ColorPalette.textSecondaryDark 
                          : ColorPalette.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spacingXl),
                  
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
                    hintText: '비밀번호를 입력해주세요',
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
                  const SizedBox(height: Dimensions.spacingSm),
                  
                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: AuthButton(
                      text: '비밀번호 찾기',
                      onPressed: _navigateToPasswordReset,
                      type: AuthButtonType.text,
                      isFullWidth: false,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingLg),
                  
                  // Login button
                  AuthButton(
                    text: '로그인',
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: Dimensions.spacingMd),
                  
                  // Register link
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
                      AuthButton(
                        text: '회원가입',
                        onPressed: _navigateToRegister,
                        type: AuthButtonType.text,
                        isFullWidth: false,
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