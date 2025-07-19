import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_state.dart';
import '../services/kakao_map_service.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/index.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  static const routeName = '/edit-profile';

  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailedAddressController = TextEditingController();
  String? _uid;

  bool _isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // Use AsyncValue.when pattern to safely access user data
    final authState = ref.read(authProvider);

    authState.whenData((state) {
      final user = state.user;
      if (user != null) {
        _nameController.text = user.name;
        _addressController.text = user.roadNameAddress ?? '';
        _detailedAddressController.text = user.detailedAddress ?? '';
        _uid = user.uid;

        // 프로필이 이미 완성되었는지 확인
        setState(() {
          _isProfileComplete = user.roadNameAddress != null;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _detailedAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        centerTitle: true,
        elevation: 0,
      ),
      body: authState.when(
        data: (state) {
          final isLoading = state.isLoading &&
              state.currentAction == AuthActionType.updateProfile;

          return SafeArea(
            child: SingleChildScrollView(
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
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
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
                                '서비스의 모든 기능을 사용하기 위해 주소 정보를 완성해주세요.',
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

                    // 오류 메시지
                    if (state.errorMessage != null &&
                        state.currentAction ==
                            AuthActionType.updateProfile) ...[
                      Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSm),
                        decoration: BoxDecoration(
                          color: ColorPalette.error.withOpacity(0.1),
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

                    // 이름 필드
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '이름',
                        hintText: '실명을 입력해주세요',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이름을 입력해주세요';
                        }
                        return null;
                      },
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: Dimensions.spacingMd),

                    // 주소 필드
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: '주소',
                        hintText: '배송받을 주소를 입력해주세요',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '주소를 입력해주세요';
                        }
                        if (value.length < 5) {
                          return '올바른 주소를 입력해주세요';
                        }
                        return null;
                      },
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: Dimensions.spacingMd),

                    // 상세 주소 필드
                    TextFormField(
                      controller: _detailedAddressController,
                      decoration: InputDecoration(
                        labelText: '상세 주소',
                        hintText: '동/호수 등 (예: 101동 202호)',
                        prefixIcon: const Icon(Icons.home_outlined),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
                        ),
                      ),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: Dimensions.spacingXl),

                    // 저장 버튼
                    ElevatedButton(
                      onPressed: isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.padding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
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
                          : const Text('저장하기'),
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

  Future<void> _updateProfile() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate form
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // Ensure uid is available
    if (_uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 정보를 불러오는데 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: ColorPalette.error,
        ),
      );
      return;
    }

    try {
      // register_screen과 동일한 주소 검증 로직 적용
      final addressText = _addressController.text.trim();
      String? verifiedRoadNameAddress;
      String? verifiedLocationAddress;
      String? locationTagId;
      String? locationTagName;
      String? locationStatus;
      String? pendingLocationName;

      if (addressText.isNotEmpty) {
        final kakaoMapService = KakaoMapService();
        final addressDetails =
            await kakaoMapService.searchAddressDetails(addressText);

        if (addressDetails == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('주소를 정확히 입력해주세요.'),
                backgroundColor: ColorPalette.error,
              ),
            );
          }
          return;
        }

        // 주소 정보 추출
        verifiedRoadNameAddress = addressDetails['roadNameAddress'] as String;
        verifiedLocationAddress = addressDetails['locationAddress'] as String;
        final searchedLocationTag = addressDetails['locationTag'] as String;

        // LocationTag 검증 (register_screen과 동일한 로직)
        final locationTagResult =
            await _validateLocationTagFromFirestore(searchedLocationTag);
        locationTagId = locationTagResult['locationTagId'];
        locationTagName = locationTagResult['locationTagName'];
        locationStatus = locationTagResult['locationStatus'];
        pendingLocationName = locationTagResult['pendingLocationName'];

        // 검증된 주소로 UI 업데이트
        _addressController.text = verifiedRoadNameAddress;
      }

      // Use Riverpod auth provider with all location-related parameters
      await ref.read(authProvider.notifier).updateUserProfile(
            uid: _uid!,
            name: _nameController.text.trim(),
            roadNameAddress:
                verifiedRoadNameAddress ?? _addressController.text.trim(),
            detailedAddress: _detailedAddressController.text.trim().isEmpty
                ? null
                : _detailedAddressController.text.trim(),
            locationAddress: verifiedLocationAddress,
            locationTagId: locationTagId,
            locationTagName: locationTagName,
            locationStatus: locationStatus,
            pendingLocationName: pendingLocationName,
          );

      // 성공 메시지 표시
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필이 성공적으로 업데이트되었습니다'),
          backgroundColor: ColorPalette.success,
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      // 주소 검증 실패 시 특별 처리
      if (error.toString().contains('주소') ||
          error.toString().contains('address')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('주소를 정확히 입력해주세요.'),
              backgroundColor: ColorPalette.error,
            ),
          );
        }
        return;
      }

      // 오류는 이미 AuthState에서 처리됨
      // 추가적인 오류 처리가 필요한 경우 여기에 작성
    }
  }

  // register_screen의 _validateLocationTagFromFirestore와 동일한 로직
  Future<Map<String, dynamic>> _validateLocationTagFromFirestore(
      String locationTagName) async {
    try {
      // LocationTagRepository를 통해 실제 Firestore에서 조회
      final locationTagRepository = ref.read(locationTagRepositoryProvider);
      final locationTag =
          await locationTagRepository.getLocationTagByName(locationTagName);

      if (locationTag != null && locationTag.isActive) {
        return {
          'locationTagId': locationTag.id,
          'locationTagName': locationTag.name,
          'locationStatus': 'active',
          'pendingLocationName': null,
        };
      } else {
        return {
          'locationTagId': null,
          'locationTagName': null,
          'locationStatus': 'pending',
          'pendingLocationName': locationTagName,
        };
      }
    } catch (e) {
      // 오류 발생 시 pending 상태로 설정
      return {
        'locationTagId': null,
        'locationTagName': null,
        'locationStatus': 'pending',
        'pendingLocationName': locationTagName,
      };
    }
  }
}
