import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/delivery_address_model.dart';
import '../services/delivery_address_service.dart';
import '../exceptions/delivery_address_exceptions.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/dimensions.dart';
import '../../../core/services/global_error_handler.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/services/kakao_map_service.dart';

/// 배송지 관리를 위한 위젯
/// CRUD (Create, Read, Update, Delete) 기능을 모두 포함
class DeliveryAddressManager extends ConsumerStatefulWidget {
  final DeliveryAddressModel? selectedAddress;
  final Function(DeliveryAddressModel?) onAddressSelected;
  final VoidCallback? onAddressChanged;

  const DeliveryAddressManager({
    super.key,
    required this.selectedAddress,
    required this.onAddressSelected,
    this.onAddressChanged,
  });

  @override
  ConsumerState<DeliveryAddressManager> createState() =>
      _DeliveryAddressManagerState();
}

class _DeliveryAddressManagerState
    extends ConsumerState<DeliveryAddressManager> {
  List<DeliveryAddressModel> _savedAddresses = [];
  bool _isLoading = false;
  bool _isAddingNewAddress = false;
  DeliveryAddressModel? _editingAddress;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  /// 저장된 배송지 목록 로드
  Future<void> _loadSavedAddresses() async {
    final authState = ref.read(authProvider).value;
    if (authState?.user?.uid == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final deliveryAddressService = ref.read(deliveryAddressServiceProvider);
      final addresses = await deliveryAddressService.getUserDeliveryAddresses(
        authState!.user!.uid,
      );

      setState(() {
        _savedAddresses = addresses;
        // 선택된 주소가 없고 저장된 주소가 있으면 첫 번째 주소 선택
        if (widget.selectedAddress == null && _savedAddresses.isNotEmpty) {
          widget.onAddressSelected(_savedAddresses.first);
        }
      });
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorDialog(
          context,
          e,
          title: '배송지 로드 실패',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 배송지 삭제
  Future<void> _deleteAddress(DeliveryAddressModel address) async {
    // 삭제 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('배송지 삭제'),
        content: Text('${address.recipientName}님의 배송지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authState = ref.read(authProvider).value;
    if (authState?.user?.uid == null) return;

    try {
      final deliveryAddressService = ref.read(deliveryAddressServiceProvider);
      await deliveryAddressService.deleteUserDeliveryAddress(
        authState!.user!.uid,
        address.id,
      );

      // 삭제된 주소가 선택된 주소였으면 선택 해제
      if (widget.selectedAddress?.id == address.id) {
        widget.onAddressSelected(null);
      }

      // 목록 새로고침
      await _loadSavedAddresses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('배송지가 삭제되었습니다.')),
        );
      }

      // 주소 변경 콜백 호출
      widget.onAddressChanged?.call();
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorDialog(
          context,
          e,
          title: '배송지 삭제 실패',
        );
      }
    }
  }

  /// 편집 모드 토글
  void _toggleEditMode(DeliveryAddressModel? address) {
    setState(() {
      _editingAddress = address;
      _isAddingNewAddress = address == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingMd),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 편집/추가 모드
    if (_editingAddress != null || _isAddingNewAddress) {
      return DeliveryAddressForm(
        address: _editingAddress,
        onSaved: (address) async {
          await _loadSavedAddresses();
          setState(() {
            _editingAddress = null;
            _isAddingNewAddress = false;
          });
          widget.onAddressChanged?.call();
        },
        onCancel: () {
          setState(() {
            _editingAddress = null;
            _isAddingNewAddress = false;
          });
        },
      );
    }

    // 주소 목록 표시
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 저장된 주소 목록
        if (_savedAddresses.isNotEmpty) ...[
          ...List.generate(_savedAddresses.length, (index) {
            final address = _savedAddresses[index];
            final isSelected = widget.selectedAddress?.id == address.id;

            return Container(
              margin: const EdgeInsets.only(bottom: Dimensions.spacingSm),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? ColorPalette.primary
                      : Theme.of(context).dividerColor,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              ),
              child: Column(
                children: [
                  RadioListTile<DeliveryAddressModel>(
                    value: address,
                    groupValue: widget.selectedAddress,
                    onChanged: widget.onAddressSelected,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.recipientName,
                            style: TextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // 편집/삭제 버튼
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _toggleEditMode(address),
                          color: ColorPalette.primary,
                          tooltip: '편집',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _deleteAddress(address),
                          color: ColorPalette.error,
                          tooltip: '삭제',
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address.recipientContact),
                        Text(
                          '${address.recipientAddress} ${address.recipientAddressDetail}',
                        ),
                        if (address.requestMemo != null &&
                            address.requestMemo!.isNotEmpty)
                          Text(
                            '배송 요청: ${address.requestMemo}',
                            style: TextStyles.bodySmall.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? ColorPalette.textSecondaryDark
                                  : ColorPalette.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                    activeColor: ColorPalette.primary,
                    contentPadding: const EdgeInsets.only(
                      left: Dimensions.paddingSm,
                      right: 0,
                      top: Dimensions.paddingXs,
                      bottom: Dimensions.paddingXs,
                    ),
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          // 저장된 주소가 없을 때
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingMd),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            child: const Center(
              child: Text('저장된 배송지가 없습니다.'),
            ),
          ),
        ],

        const SizedBox(height: Dimensions.spacingMd),

        // 새 주소 추가 버튼
        OutlinedButton.icon(
          onPressed: () => _toggleEditMode(null),
          icon: const Icon(Icons.add),
          label: const Text('새 배송지 추가'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorPalette.primary,
            side: const BorderSide(color: ColorPalette.primary),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}

/// 배송지 입력/수정 폼
class DeliveryAddressForm extends ConsumerStatefulWidget {
  final DeliveryAddressModel? address;
  final Function(DeliveryAddressModel) onSaved;
  final VoidCallback onCancel;

  const DeliveryAddressForm({
    super.key,
    this.address,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  ConsumerState<DeliveryAddressForm> createState() =>
      _DeliveryAddressFormState();
}

class _DeliveryAddressFormState extends ConsumerState<DeliveryAddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailAddressController = TextEditingController();
  final _memoController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 편집 모드인 경우 기존 데이터로 폼 채우기
    if (widget.address != null) {
      _recipientController.text = widget.address!.recipientName;
      _phoneController.text = widget.address!.recipientContact;
      _postalCodeController.text = widget.address!.postalCode;
      _addressController.text = widget.address!.recipientAddress;
      _detailAddressController.text = widget.address!.recipientAddressDetail;
      _memoController.text = widget.address!.requestMemo ?? '';
    } else {
      // 새 주소 추가 시 사용자 이름 기본값 설정
      final authState = ref.read(authProvider).value;
      _recipientController.text = authState?.user?.name ?? '';
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _phoneController.dispose();
    _postalCodeController.dispose();
    _addressController.dispose();
    _detailAddressController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  /// 카카오 주소 검색
  Future<void> _openAddressSearch() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _AddressSearchDialog(),
    );

    if (result != null && result.isNotEmpty && mounted) {
      try {
        final kakaoMapService = KakaoMapService();
        final addressDetails =
            await kakaoMapService.searchAddressDetails(result);

        if (addressDetails != null) {
          setState(() {
            _addressController.text =
                addressDetails['roadNameAddress'] ?? result;
            _postalCodeController.text = addressDetails['postalCode'] ?? '';
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('주소가 검증되었습니다.')),
            );
          }
        } else {
          setState(() {
            _addressController.text = result;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('주소가 입력되었습니다.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('주소 검색 실패: $e')),
          );
        }
      }
    }
  }

  /// 전화번호 포맷팅
  String _formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 11) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-${cleaned.substring(7)}';
    } else if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phone;
  }

  /// 폼 저장
  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final authState = ref.read(authProvider).value;
    if (authState?.user?.uid == null) return;

    try {
      final deliveryAddressService = ref.read(deliveryAddressServiceProvider);

      // 우편번호가 비어있으면 임시값 설정
      if (_postalCodeController.text.isEmpty) {
        _postalCodeController.text = '00000';
      }

      final address = DeliveryAddressModel(
        id: widget.address?.id ?? '',
        recipientName: _recipientController.text.trim(),
        recipientContact: _formatPhoneNumber(_phoneController.text.trim()),
        postalCode: _postalCodeController.text.trim(),
        recipientAddress: _addressController.text.trim(),
        recipientAddressDetail: _detailAddressController.text.trim(),
        requestMemo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        createdAt: widget.address?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 유효성 검증
      deliveryAddressService.validateDeliveryAddress(address);

      if (widget.address == null) {
        // 새 주소 추가
        final savedAddress = await deliveryAddressService.addDeliveryAddressToUser(
          authState!.user!.uid,
          address,
        );
        widget.onSaved(savedAddress);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('새 배송지가 저장되었습니다.')),
          );
        }
      } else {
        // 기존 주소 수정
        await deliveryAddressService.updateUserDeliveryAddress(
          authState!.user!.uid,
          address,
        );
        widget.onSaved(address);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('배송지가 수정되었습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (e is DeliveryAddressException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: ColorPalette.error,
            ),
          );
        } else {
          GlobalErrorHandler.showErrorDialog(
            context,
            e,
            title: widget.address == null ? '배송지 저장 실패' : '배송지 수정 실패',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Row(
            children: [
              Text(
                widget.address == null ? '새 배송지 추가' : '배송지 수정',
                style: TextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('취소'),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spacingMd),

          // 받는 사람
          TextFormField(
            controller: _recipientController,
            decoration: const InputDecoration(
              labelText: '받는 사람',
              hintText: '받는 분의 성함을 입력해주세요',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '받는 사람을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: Dimensions.spacingMd),

          // 연락처
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: '연락처',
              hintText: '010-0000-0000',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '연락처를 입력해주세요';
              }
              // 한국 전화번호 형식 검증
              final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (!RegExp(r'^01[0-9]{8,9}$').hasMatch(cleaned)) {
                return '올바른 전화번호 형식이 아닙니다';
              }
              return null;
            },
          ),
          const SizedBox(height: Dimensions.spacingMd),

          // 주소 (우편번호 + 주소 검색)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: '주소',
                    hintText: '주소를 검색해주세요',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '주소를 입력해주세요';
                    }
                    return null;
                  },
                  readOnly: true,
                  onTap: _openAddressSearch,
                ),
              ),
              const SizedBox(width: Dimensions.spacingSm),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _openAddressSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('검색'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spacingMd),

          // 상세주소
          TextFormField(
            controller: _detailAddressController,
            decoration: const InputDecoration(
              labelText: '상세주소',
              hintText: '동/호수 등 상세주소를 입력해주세요',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '상세주소를 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: Dimensions.spacingMd),

          // 배송 요청사항
          DropdownButtonFormField<String>(
            value: _memoController.text.isEmpty ? null : _memoController.text,
            items: [
              '문 앞에 놓아주세요',
              '경비실에 맡겨주세요',
              '택배함에 넣어주세요',
              '배송 전 연락바랍니다',
              '부재 시 연락바랍니다',
              '직접 받겠습니다',
            ]
                .map((memo) => DropdownMenuItem(
                      value: memo,
                      child: Text(memo),
                    ))
                .toList(),
            onChanged: (value) {
              _memoController.text = value ?? '';
            },
            decoration: const InputDecoration(
              labelText: '배송 요청사항',
              hintText: '선택사항',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Dimensions.spacingLg),

          // 저장 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(widget.address == null ? '저장' : '수정'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 주소 검색 다이얼로그
class _AddressSearchDialog extends StatefulWidget {
  @override
  _AddressSearchDialogState createState() => _AddressSearchDialogState();
}

class _AddressSearchDialogState extends State<_AddressSearchDialog> {
  final _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('주소 검색'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('배송받을 주소를 입력해주세요.'),
          const SizedBox(height: Dimensions.spacingMd),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              hintText: '예: 서울특별시 강남구 테헤란로',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (value) {
              Navigator.of(context).pop(value.trim());
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_addressController.text.trim());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPalette.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}