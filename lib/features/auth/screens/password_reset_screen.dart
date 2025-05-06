import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/theme/index.dart';

class PasswordResetScreen extends StatefulWidget {
  static const routeName = '/password-reset';

  const PasswordResetScreen({Key? key}) : super(key: key);

  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSuccess = false;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .sendPasswordResetEmail(_emailController.text.trim());
      
      setState(() {
        _isSuccess = true;
      });
    } catch (e) {
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
        title: const Text('비밀번호 찾기'),
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
                  const SizedBox(height: Dimensions.spacingMd),
                  
                  // Success message
                  if (_isSuccess) ...[
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
                    AuthButton(
                      text: '로그인으로 돌아가기',
                      onPressed: _navigateBack,
                      type: AuthButtonType.secondary,
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
                    const SizedBox(height: Dimensions.spacingLg),
                    
                    // Submit button
                    AuthButton(
                      text: '비밀번호 재설정 링크 발송',
                      onPressed: _handlePasswordReset,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: Dimensions.spacingMd),
                    
                    // Back to login link
                    Center(
                      child: AuthButton(
                        text: '로그인으로 돌아가기',
                        onPressed: _navigateBack,
                        type: AuthButtonType.text,
                        isFullWidth: false,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 