import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/dimensions.dart';
import '../../../core/config/app_config.dart';
import '../widgets/order_summary_card.dart';
import '../providers/order_state.dart';
import '../models/order_model.dart';
import '../../cart/models/cart_item_model.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/services/kakao_map_service.dart';
import '../../location/models/pickup_info_model.dart';
import '../../location/repositories/location_tag_repository.dart';
import '../../common/providers/repository_providers.dart';

/// 주문서 작성 화면
class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItemModel> items;
  final String deliveryType;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.deliveryType,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // 배송지 입력 컨트롤러들
  final _recipientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailAddressController = TextEditingController();
  final _orderNoteController = TextEditingController();

  // 폼 유효성 검사를 위한 키
  final _formKey = GlobalKey<FormState>();

  // 배송비 설정 (AppConfig에서 중앙 관리)
  int get _deliveryFeeAmount => AppConfig.deliveryFee;
  int get _pickupFeeAmount => AppConfig.pickupFee;

  // 픽업 정보
  List<PickupInfoModel> _pickupInfoList = [];
  bool _isLoadingPickupInfo = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    // 픽업 상품인 경우 픽업 정보 로드
    if (widget.deliveryType == '픽업') {
      _loadPickupInfo();
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _detailAddressController.dispose();
    _orderNoteController.dispose();
    super.dispose();
  }

  /// 사용자 정보 로드
  void _loadUserInfo() {
    final authState = ref.read(authProvider).value;
    if (authState?.user != null) {
      // 사용자 정보에서 기본값 설정 (추후 UserProfile에서 가져오도록 수정)
      _recipientController.text = authState!.user!.name;
      // _phoneController.text = authState.user.phoneNumber ?? '';
    }
  }

  /// 픽업 정보 로드 (개선된 버전)
  Future<void> _loadPickupInfo() async {
    if (widget.deliveryType != '픽업' || widget.items.isEmpty) return;

    setState(() {
      _isLoadingPickupInfo = true;
    });

    try {
      final locationTagRepository = ref.read(locationTagRepositoryProvider);
      final Set<PickupInfoModel> allPickupInfos = {};

      // 🔄 CartItem의 픽업 정보를 통해 실제 데이터 조회
      for (final item in widget.items) {
        if (item.isPickupItem && item.locationTagId != null) {
          // 해당 지역의 모든 픽업 정보 조회
          final pickupInfos =
              await item.getAvailablePickupInfos(locationTagRepository);
          allPickupInfos.addAll(pickupInfos);
        }
      }

      setState(() {
        _pickupInfoList = allPickupInfos.toList();
      });

      // 픽업 정보가 없는 경우 알림
      if (_pickupInfoList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('해당 지역의 픽업 정보를 찾을 수 없습니다. 관리자에게 문의해주세요.'),
              backgroundColor: ColorPalette.warning,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('픽업 정보 로드 실패: $e');

      // 🔄 실패 시 임시 픽업 정보 사용 (fallback)
      setState(() {
        _pickupInfoList = [
          PickupInfoModel(
            id: 'temp_pickup_1',
            placeName: '옥수역 1번 출구 (임시)',
            address: '서울시 성동구 옥수동 310-1',
            detailAddress: '1번 출구 앞 편의점',
            contactName: '픽업 담당자',
            contactPhone: '010-1234-5678',
            operatingHours: ['평일 09:00-18:00', '토요일 09:00-15:00'],
            availableDays: [1, 2, 3, 4, 5, 6], // 월~토
            specialInstructions: '편의점 직원에게 주문번호를 말씀해주세요.',
            latitude: 37.5414,
            longitude: 127.0167,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('픽업 정보 로드 중 문제가 발생했습니다. 임시 정보를 표시합니다.'),
            backgroundColor: ColorPalette.warning,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingPickupInfo = false;
      });
    }
  }

  /// 카카오 주소 검색
  Future<void> _searchAddress() async {
    try {
      final kakaoMapService = KakaoMapService();
      final addressDetails =
          await kakaoMapService.searchAddressDetails(_addressController.text);

      if (addressDetails != null) {
        setState(() {
          _addressController.text = addressDetails['roadNameAddress'] ?? '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주소가 검증되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('유효하지 않은 주소입니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주소 검증 실패: $e')),
      );
    }
  }

  /// 상품 총 금액 계산
  int get _subtotal {
    return widget.items.fold<int>(
      0,
      (prev, item) => prev + (item.productPrice * item.quantity).toInt(),
    );
  }

  /// 배송비 계산
  int get _deliveryFee {
    return widget.deliveryType == '배송' ? _deliveryFeeAmount : _pickupFeeAmount;
  }

  /// 총 결제 금액
  int get _totalAmount => _subtotal + _deliveryFee;

  /// 주문하기 버튼 클릭
  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // 배송지 정보 생성 (배송인 경우만)
      DeliveryAddress? deliveryAddress;
      if (widget.deliveryType == '배송') {
        // 주소 유효성 검증
        final addressText = _addressController.text.trim();
        if (addressText.isNotEmpty) {
          final kakaoMapService = KakaoMapService();
          final addressDetails =
              await kakaoMapService.searchAddressDetails(addressText);

          if (addressDetails == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('배송받을 주소를 정확히 입력해주세요.'),
                  backgroundColor: ColorPalette.error,
                ),
              );
            }
            return;
          }

          // 검증된 주소로 업데이트
          _addressController.text =
              addressDetails['roadNameAddress'] ?? addressText;
        }

        deliveryAddress = DeliveryAddress(
          recipientName: _recipientController.text.trim(),
          recipientPhone: _phoneController.text.trim(),
          postalCode: '', // 우편번호는 주소 API 연동 시 추가
          address: _addressController.text.trim(),
          detailAddress: _detailAddressController.text.trim(),
        );
      }

      // 주문 생성
      await ref.read(orderProvider.notifier).createOrderFromCart(
            cartItems: widget.items,
            deliveryType: widget.deliveryType,
            deliveryAddress: deliveryAddress,
            orderNote: _orderNoteController.text.trim().isNotEmpty
                ? _orderNoteController.text.trim()
                : null,
          );

      // 결제 화면으로 이동
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/payment',
          arguments: {
            'orderId': ref.read(orderProvider).currentOrder?.orderId,
            'amount': _totalAmount,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('주문 생성 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: ColorPalette.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final isLoading = orderState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.deliveryType == '배송' ? '택배' : '픽업'} 주문서',
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 주문 상품 정보
              OrderSummaryCard(
                items: widget.items,
                deliveryType: widget.deliveryType,
                subtotal: _subtotal,
                deliveryFee: _deliveryFee,
                onEditItems: () => Navigator.pop(context),
              ),
              const SizedBox(height: Dimensions.spacingLg),

              // 배송지 정보 또는 픽업 정보
              if (widget.deliveryType == '배송') ...[
                _buildDeliverySection(),
                const SizedBox(height: Dimensions.spacingLg),
              ] else ...[
                _buildPickupSection(),
                const SizedBox(height: Dimensions.spacingLg),
              ],

              // 주문자 메모
              _buildOrderNoteSection(),
              const SizedBox(height: Dimensions.spacingLg),

              // 결제 정보
              _buildPaymentSection(),
              const SizedBox(height: Dimensions.spacingXl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(Dimensions.padding),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _processOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: Dimensions.paddingMd,
                ),
                backgroundColor: ColorPalette.primary,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      '${NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0).format(_totalAmount)} 결제하기',
                      style: TextStyles.buttonLarge,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// 배송지 입력 섹션
  Widget _buildDeliverySection() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: ColorPalette.primary,
                  size: 20,
                ),
                const SizedBox(width: Dimensions.spacingSm),
                Text(
                  '배송지 정보',
                  style: TextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                // 간단한 전화번호 형식 검증
                if (!RegExp(r'^[0-9-+().\s]+$').hasMatch(value)) {
                  return '올바른 전화번호 형식이 아닙니다';
                }
                return null;
              },
            ),
            const SizedBox(height: Dimensions.spacingMd),

            // 주소
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '주소',
                hintText: '주소를 입력해주세요',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '주소를 입력해주세요';
                }
                return null;
              },
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
            ),
          ],
        ),
      ),
    );
  }

  /// 픽업 정보 섹션
  Widget _buildPickupSection() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.store,
                  color: ColorPalette.primary,
                  size: 20,
                ),
                const SizedBox(width: Dimensions.spacingSm),
                Text(
                  '픽업 정보',
                  style: TextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.spacingMd),

            // 픽업 장소 정보
            if (_isLoadingPickupInfo)
              const Center(child: CircularProgressIndicator())
            else if (_pickupInfoList.isNotEmpty)
              ..._pickupInfoList.map((pickupInfo) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: Dimensions.spacingMd),
                    padding: const EdgeInsets.all(Dimensions.paddingMd),
                    decoration: BoxDecoration(
                      color: ColorPalette.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickupInfo.placeName,
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: Dimensions.spacingXs),
                        Text(
                          pickupInfo.fullAddress,
                          style: TextStyles.bodyMedium,
                        ),
                        if (pickupInfo.contactName != null ||
                            pickupInfo.contactPhone != null)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: Dimensions.spacingXs),
                            child: Text(
                              '담당자: ${pickupInfo.formattedContactInfo}',
                              style: TextStyles.bodySmall,
                            ),
                          ),
                        const SizedBox(height: Dimensions.spacingXs),
                        Text(
                          '운영시간: ${pickupInfo.operatingHours.join(", ")}',
                          style: TextStyles.bodySmall,
                        ),
                        Text(
                          '픽업 가능요일: ${pickupInfo.availableDayNames.join(", ")}',
                          style: TextStyles.bodySmall,
                        ),
                        if (pickupInfo.specialInstructions != null)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: Dimensions.spacingXs),
                            child: Text(
                              '특별안내: ${pickupInfo.specialInstructions}',
                              style: TextStyles.bodySmall.copyWith(
                                color: ColorPalette.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ))
            else if (_pickupInfoList.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingMd),
                decoration: BoxDecoration(
                  color: ColorPalette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '픽업 장소',
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Dimensions.spacingXs),
                    ..._pickupInfoList.map(
                      (pickupInfo) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: Dimensions.spacingXs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pickupInfo.placeName,
                              style: TextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              pickupInfo.fullAddress,
                              style: TextStyles.bodySmall,
                            ),
                            if (pickupInfo.operatingHours.isNotEmpty)
                              Text(
                                '운영시간: ${pickupInfo.operatingHours.join(', ')}',
                                style: TextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? ColorPalette.textSecondaryDark
                                      : ColorPalette.textSecondaryLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingMd),
                decoration: BoxDecoration(
                  color: ColorPalette.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                ),
                child: Text(
                  '픽업 정보가 없습니다. 판매자에게 문의해주세요.',
                  style: TextStyles.bodyMedium.copyWith(
                    color: ColorPalette.warning,
                  ),
                ),
              ),

            const SizedBox(height: Dimensions.spacingMd),

            // 픽업 안내
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingMd),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '픽업 안내',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingXs),
                  Text(
                    '• 주문 완료 후 픽업 가능 시간을 별도로 안내드립니다\n'
                    '• 신분증을 지참해 주세요\n'
                    '• 픽업 시간을 꼭 지켜주세요',
                    style: TextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 주문자 메모 섹션
  Widget _buildOrderNoteSection() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note_add,
                  color: ColorPalette.primary,
                  size: 20,
                ),
                const SizedBox(width: Dimensions.spacingSm),
                Text(
                  '주문 메모',
                  style: TextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: Dimensions.spacingSm),
                Text(
                  '(선택사항)',
                  style: TextStyles.bodySmall.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? ColorPalette.textSecondaryDark
                        : ColorPalette.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.spacingMd),
            TextFormField(
              controller: _orderNoteController,
              decoration: const InputDecoration(
                hintText: '배송 시 요청사항이나 기타 메모를 입력해주세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: AppConfig.maxOrderMemoLength,
            ),
          ],
        ),
      ),
    );
  }

  /// 결제 정보 섹션
  Widget _buildPaymentSection() {
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: ColorPalette.primary,
                  size: 20,
                ),
                const SizedBox(width: Dimensions.spacingSm),
                Text(
                  '결제 정보',
                  style: TextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.spacingMd),

            // 가격 상세
            _buildPriceRow('상품 금액', priceFormat.format(_subtotal)),
            if (_deliveryFee > 0) ...[
              const SizedBox(height: Dimensions.spacingXs),
              _buildPriceRow('배송비', priceFormat.format(_deliveryFee)),
            ],
            const SizedBox(height: Dimensions.spacingSm),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: Dimensions.spacingSm),
            _buildPriceRow(
              '총 결제 금액',
              priceFormat.format(_totalAmount),
              isTotal: true,
            ),

            const SizedBox(height: Dimensions.spacingMd),

            // 결제 방법 안내
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingMd),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    color: ColorPalette.primary,
                    size: 16,
                  ),
                  const SizedBox(width: Dimensions.spacingSm),
                  Text(
                    'Toss Payments를 통해 안전하게 결제됩니다',
                    style: TextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String amount, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? TextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                )
              : TextStyles.bodyMedium,
        ),
        Text(
          amount,
          style: isTotal
              ? TextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.primary,
                )
              : TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
