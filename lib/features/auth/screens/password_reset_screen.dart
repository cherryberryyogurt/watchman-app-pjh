import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_state.dart';
import '../../../core/theme/index.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  static const routeName = '/password-reset';

  const PasswordResetScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 찾기'),
        centerTitle: true,
        elevation: 0,
      ),
      body: authState.when(
        data: (state) {
          final isLoading = state.isLoading && state.currentAction == AuthActionType.passwordReset;
          final isSuccess = state.isPasswordResetSuccess;
          
          return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Dimensions.spacingMd),
                
                // Success message
                if (isSuccess) ...[
                  Container(
                    padding: const EdgeInsets.all(Dimensions.padding),
                    decoration: BoxDecoration(
                      color: ColorPalette.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: ColorPalette.success,
                          size: 48,
                        ),
                        const SizedBox(height: Dimensions.spacingSm),
                        Text(
                          '비밀번호 재설정 이메일이 발송되었습니다',
                          style: TextStyles.bodyMedium.copyWith(
                            color: ColorPalette.success,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Dimensions.spacingSm),
                        Text(
                          '이메일에 포함된 링크를 통해 비밀번호를 재설정해주세요',
                          style: TextStyles.bodySmall.copyWith(
                            color: isDarkMode
                                ? ColorPalette.textPrimaryDark
                                : ColorPalette.textPrimaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingLg),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      foregroundColor: ColorPalette.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.padding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                        side: const BorderSide(color: ColorPalette.primary),
                      ),
                    ),
                    child: const Text('로그인으로 돌아가기'),
                  ),
                ] else ...[
                  Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyles.headlineSmall.copyWith(
                      color: isDarkMode
                          ? ColorPalette.textPrimaryDark
                          : ColorPalette.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spacingSm),
                  Text(
                    '가입하신 이메일 주소를 입력해주세요. 비밀번호 재설정 링크를 보내드립니다.',
                    style: TextStyles.bodyMedium.copyWith(
                      color: isDarkMode
                          ? ColorPalette.textSecondaryDark
                          : ColorPalette.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spacingLg),
                  
                  // 오류 메시지
                      if (state.errorMessage != null && state.currentAction == AuthActionType.passwordReset) ...[
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
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: Dimensions.spacingLg),
                  
                  // Submit button
                  ElevatedButton(
                    onPressed: isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.padding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('비밀번호 재설정 링크 발송'),
                  ),
                  const SizedBox(height: Dimensions.spacingMd),
                  
                  // Back to login link
                  Center(
                    child: TextButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        '로그인으로 돌아가기',
                        style: TextStyles.bodyMedium.copyWith(
                          color: ColorPalette.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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

  Future<void> _resetPassword() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    // Validate form
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    // Use Riverpod auth provider - let AsyncValue handle states
      await ref.read(authProvider.notifier).sendPasswordResetEmail(
        _emailController.text.trim(),
      );
  }
} 