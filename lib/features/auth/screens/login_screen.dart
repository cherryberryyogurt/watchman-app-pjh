import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_state.dart';
import 'register_screen.dart';
import 'password_reset_screen.dart';
import '../../../core/theme/index.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/login';

  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Watch auth state using AsyncValue
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
                    '로그인하고 와치맨의 다양한 서비스를 이용해보세요',
                    style: TextStyles.bodyMedium.copyWith(
                      color: isDarkMode
                          ? ColorPalette.textSecondaryDark
                          : ColorPalette.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spacingXl),
                  
                  // Display error message if there is one
                  authState.when(
                    data: (state) {
                      if (state.errorMessage != null) {
                        return Column(
                          children: [
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
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (error, stack) => Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(Dimensions.paddingSm),
                          decoration: BoxDecoration(
                            color: ColorPalette.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                          ),
                          child: Text(
                            error.toString(),
                            style: TextStyles.bodySmall.copyWith(
                              color: ColorPalette.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: Dimensions.spacingMd),
                      ],
                    ),
                  ),
                  
                  // Email field
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
                    // Disable fields when loading
                    enabled: !authState.isLoading,
                  ),
                  const SizedBox(height: Dimensions.spacingMd),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
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
                    enabled: !authState.isLoading,
                  ),
                  const SizedBox(height: Dimensions.spacingSm),
                  
                  // Remember me & Forgot password row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      TextButton(
                        onPressed: authState.isLoading ? null : () {
                          Navigator.pushNamed(
                            context,
                            PasswordResetScreen.routeName,
                          );
                        },
                        child: Text(
                          '비밀번호 찾기',
                          style: TextStyles.bodySmall.copyWith(
                            color: ColorPalette.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spacingLg),
                  
                  // Login button
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.padding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                      ),
                    ),
                    child: authState.isLoading
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
                      TextButton(
                        onPressed: authState.isLoading ? null : () {
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

  Future<void> _login() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    // Validate form
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
      // Use Riverpod auth provider with "로그인 상태 유지" 설정
    // The AsyncValue handling will be done by the provider and the build method
      await ref.read(authProvider.notifier).signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
      _rememberMe,
      );
  }
} 