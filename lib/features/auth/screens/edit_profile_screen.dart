import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/theme/index.dart';
import '../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  static const routeName = '/edit-profile';

  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber ?? '';
      _addressController.text = user.address ?? '';
      
      // 프로필이 이미 완성되었는지 확인
      _isProfileComplete = user.phoneNumber != null && user.address != null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateUserProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      // 성공 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 성공적으로 업데이트되었습니다'),
            backgroundColor: ColorPalette.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
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
                  // 프로필 완성 상태 표시
                  if (!_isProfileComplete) ...[
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSm),
                      decoration: BoxDecoration(
                        color: ColorPalette.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: ColorPalette.info,
                            size: 20,
                          ),
                          const SizedBox(width: Dimensions.spacingSm),
                          Expanded(
                            child: Text(
                              '서비스의 모든 기능을 사용하기 위해 프로필 정보를 완성해주세요.',
                              style: TextStyles.bodySmall.copyWith(
                                color: isDarkMode
                                    ? ColorPalette.textPrimaryDark
                                    : ColorPalette.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimensions.spacingMd),
                  ],
                  
                  // 오류 메시지 표시
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

                  // 이름 필드
                  AuthTextField(
                    label: '이름',
                    hintText: '실명을 입력해주세요',
                    controller: _nameController,
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: Dimensions.spacingMd),

                  // 전화번호 필드
                  AuthTextField(
                    label: '전화번호',
                    hintText: '010-0000-0000',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhoneNumber,
                  ),
                  const SizedBox(height: Dimensions.spacingMd),

                  // 주소 필드
                  AuthTextField(
                    label: '주소',
                    hintText: '배송받을 주소를 입력해주세요',
                    controller: _addressController,
                    validator: Validators.validateAddress,
                  ),
                  const SizedBox(height: Dimensions.spacingXl),

                  // 저장 버튼
                  AuthButton(
                    text: '저장하기',
                    onPressed: _handleUpdateProfile,
                    isLoading: _isLoading,
                  ),
                  
                  const SizedBox(height: Dimensions.spacingMd),
                  
                  // 주의 사항
                  Text(
                    '모든 정보는 서비스 이용 및 배송을 위해 사용됩니다.',
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