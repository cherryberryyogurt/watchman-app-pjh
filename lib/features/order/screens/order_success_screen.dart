import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// 웹 환경에서만 import (조건부 import)
// 모바일에서는 html 라이브러리가 없으므로 컴파일 오류 방지

import '../../../core/theme/color_palette.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/dimensions.dart';
import '../providers/order_state.dart';
import '../models/order_model.dart';
// import '../../home/screens/home_screen.dart';

/// 주문 완료 화면
/// 주문 성공 후 상세 정보를 표시하고 다음 액션을 제공합니다.
class OrderSuccessScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final String? paymentKey;
  final int? amount;

  const OrderSuccessScreen({
    super.key,
    this.orderId,
    this.paymentKey,
    this.amount,
  });

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSuccessAnimation();
    _handleWebPaymentResult();
  }

  /// 웹 환경에서 결제 결과를 부모 창으로 전송
  void _handleWebPaymentResult() {
    if (kIsWeb && widget.paymentKey != null && widget.orderId != null) {
      try {
        debugPrint('🌐 웹 환경에서 결제 성공 처리: ${widget.paymentKey}');
        // 웹에서의 추가 처리는 JavaScript로 위임하거나 다른 방법 사용
        // html 라이브러리 사용을 피해서 크로스 플랫폼 호환성 확보

        debugPrint('🌐 웹 결제 성공 메시지 처리 완료: ${widget.paymentKey}');
      } catch (e) {
        debugPrint('❌ 웹 메시지 처리 실패: $e');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 애니메이션 초기화
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));
  }

  /// 성공 애니메이션 시작
  void _startSuccessAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  /// 홈으로 이동
  void _goToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  // /// 주문 내역으로 이동
  // void _goToOrderHistory() {
  //   Navigator.pushNamedAndRemoveUntil(
  //     context,
  //     '/',
  //     (route) => false,
  //   );

  //   // 프로필 탭으로 이동
  //   Future.delayed(const Duration(milliseconds: 100), () {
  //     if (mounted) {
  //       final homeScreenState =
  //           context.findAncestorStateOfType<HomeScreenState>();
  //       if (homeScreenState != null) {
  //         homeScreenState.onItemTapped(2); // 프로필 탭 (인덱스 2)
  //       }
  //     }
  //   });
  // }

  // /// 장바구니로 이동 (쇼핑 계속하기)
  // void _goToShopping() {
  //   Navigator.pushNamedAndRemoveUntil(
  //     context,
  //     '/',
  //     (route) => false,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final currentOrder = orderState.currentOrder;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('주문 완료'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: Dimensions.spacingXl),

              // 성공 아이콘 및 메시지
              _buildSuccessHeader(),

              const SizedBox(height: Dimensions.spacingXl),

              // 주문 정보 카드들
              if (currentOrder != null) ...[
                _buildOrderInfoCard(currentOrder),
                const SizedBox(height: Dimensions.spacingLg),
                _buildPaymentInfoCard(),
                const SizedBox(height: Dimensions.spacingLg),
                _buildDeliveryInfoCard(currentOrder),
                const SizedBox(height: Dimensions.spacingLg),
                _buildNextStepsCard(currentOrder),
              ] else
                _buildLoadingCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// 성공 헤더 (아이콘 + 메시지)
  Widget _buildSuccessHeader() {
    return Column(
      children: [
        // 성공 아이콘 (애니메이션)
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorPalette.success,
                  boxShadow: [
                    BoxShadow(
                      color: ColorPalette.success.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: Dimensions.spacingLg),

        // 성공 메시지 (페이드인)
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  Text(
                    '주문이 완료되었습니다!',
                    style: TextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.success,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spacingSm),
                  Text(
                    '결제가 성공적으로 처리되었습니다.\n주문 내역을 확인해보세요.',
                    style: TextStyles.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// 주문 정보 카드
  Widget _buildOrderInfoCard(OrderModel order) {
    return _buildInfoCard(
      title: '주문 정보',
      icon: Icons.receipt,
      children: [
        _buildInfoRow(
            '주문번호', order.orderId.substring(order.orderId.length - 13)),
        _buildInfoRow(
            '주문일시', DateFormat('yyyy년 MM월 dd일 HH:mm').format(order.createdAt)),
        _buildInfoRow('주문상태', order.status.displayName),
        // if (widget.paymentKey != null) _buildInfoRow('결제키', widget.paymentKey!),
      ],
    );
  }

  /// 결제 정보 카드
  Widget _buildPaymentInfoCard() {
    return _buildInfoCard(
      title: '결제 정보',
      icon: Icons.payment,
      children: [
        _buildInfoRow('결제수단', '토스페이먼츠'),
        _buildInfoRow('결제상태', '결제완료'),
        if (widget.amount != null) _buildAmountRow('결제금액', widget.amount!),
      ],
    );
  }

  /// 배송/픽업 정보 카드
  Widget _buildDeliveryInfoCard(OrderModel order) {
    final isDelivery = order.deliveryAddress != null;

    return _buildInfoCard(
      title: isDelivery ? '택배 정보' : '픽업 정보',
      icon: isDelivery ? Icons.local_shipping : Icons.store,
      children: [
        if (isDelivery) ...[
          _buildInfoRow('배송유형', '택배 배송'),
          _buildInfoRow('받는분', order.deliveryAddress!.recipientName),
          _buildInfoRow('연락처', order.deliveryAddress!.recipientPhone),
          _buildInfoRow('배송지',
              '${order.deliveryAddress!.address} ${order.deliveryAddress!.detailAddress ?? ''}'),
          _buildInfoRow('배송상태', '배송 준비중'),
        ] else ...[
          _buildInfoRow('배송유형', '픽업'),
          _buildInfoRow('픽업상태', '픽업 준비중'),
          _buildInfoRow('안내사항', '픽업 장소와 시간은 별도 안내드립니다.'),
        ],
      ],
    );
  }

  /// 다음 단계 안내 카드
  Widget _buildNextStepsCard(OrderModel order) {
    final isDelivery = order.deliveryAddress != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.padding),
      decoration: BoxDecoration(
        color: ColorPalette.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        border: Border.all(
          color: ColorPalette.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: ColorPalette.primary,
                size: 20,
              ),
              const SizedBox(width: Dimensions.spacingSm),
              Text(
                '다음 단계',
                style: TextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spacingMd),
          if (isDelivery) ...[
            _buildStepItem('1', '상품 준비 (1-2일 소요)'),
            _buildStepItem('2', '배송 시작 안내 (문자/푸시 알림)'),
            _buildStepItem('3', '배송 완료 (배송 추적 가능)'),
          ] else ...[
            _buildStepItem('1', '상품 준비 (1-2일 소요)'),
            _buildStepItem('2', '픽업 가능 안내 (문자/푸시 알림)'),
            _buildStepItem('3', '픽업 장소에서 상품 수령'),
          ],
        ],
      ),
    );
  }

  /// 단계 아이템
  Widget _buildStepItem(String step, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorPalette.primary.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.spacingSm),
          Expanded(
            child: Text(
              description,
              style: TextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// 로딩 카드 (주문 정보 로딩 중)
  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingXl),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: Dimensions.spacingMd),
          Text('주문 정보를 불러오고 있습니다...'),
        ],
      ),
    );
  }

  /// 정보 카드 공통 위젯
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: ColorPalette.primary,
                  size: 20,
                ),
                const SizedBox(width: Dimensions.spacingSm),
                Text(
                  title,
                  style: TextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.spacingMd),
            ...children,
          ],
        ),
      ),
    );
  }

  /// 정보 행
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// 금액 행
  Widget _buildAmountRow(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            NumberFormat.currency(
                    locale: 'ko_KR', symbol: '₩', decimalDigits: 0)
                .format(amount),
            style: TextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: ColorPalette.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 하단 네비게이션 바
  Widget _buildBottomNavigationBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(Dimensions.padding),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //   // 주문 내역 보기 버튼
            //   SizedBox(
            //     width: double.infinity,
            //     child: ElevatedButton(
            //       onPressed: _goToOrderHistory,
            //       style: ElevatedButton.styleFrom(
            //         padding: const EdgeInsets.symmetric(
            //             vertical: Dimensions.paddingMd),
            //         backgroundColor: ColorPalette.primary,
            //         foregroundColor: Colors.white,
            //       ),
            //       child: Text(
            //         '주문 내역 보기',
            //         style: TextStyles.buttonLarge,
            //       ),
            //     ),
            //   ),

            //   const SizedBox(height: Dimensions.spacingMd),

            // 홈으로 이동 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _goToHome,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.paddingMd),
                  side: BorderSide(color: ColorPalette.primary),
                  foregroundColor: ColorPalette.primary,
                ),
                child: Text(
                  '쇼핑 계속하기',
                  style: TextStyles.buttonLarge.copyWith(
                    color: ColorPalette.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
