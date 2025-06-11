import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/dimensions.dart';
import '../../../core/config/payment_config.dart';
import '../providers/order_state.dart';
import '../models/order_model.dart';
import '../widgets/toss_payments_webview.dart';

/// 결제 화면
/// 단계별 UI: 결제 정보 확인 → 결제 수단 선택 → 결제 진행
class PaymentScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final int? amount;

  const PaymentScreen({
    super.key,
    this.orderId,
    this.amount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  // 결제 단계
  PaymentStep _currentStep = PaymentStep.confirmation;

  // 선택된 결제 수단
  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.card;

  // 웹뷰 로딩 상태
  bool _isWebViewLoading = false;

  @override
  void initState() {
    super.initState();
    _validatePaymentData();
  }

  /// 결제 데이터 유효성 검사
  void _validatePaymentData() {
    final orderState = ref.read(orderProvider);

    if (orderState.currentOrder == null || widget.amount == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorAndGoBack('결제 정보가 올바르지 않습니다.');
      });
    }
  }

  /// 에러 표시 후 이전 화면으로 이동
  void _showErrorAndGoBack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorPalette.error,
      ),
    );
    Navigator.pop(context);
  }

  /// 다음 단계로 진행
  void _goToNextStep() {
    setState(() {
      switch (_currentStep) {
        case PaymentStep.confirmation:
          _currentStep = PaymentStep.methodSelection;
          break;
        case PaymentStep.methodSelection:
          _currentStep = PaymentStep.processing;
          _startPaymentProcess();
          break;
        case PaymentStep.processing:
          // 결제 진행 중에는 단계 변경 불가
          break;
      }
    });
  }

  /// 이전 단계로 이동
  void _goToPreviousStep() {
    setState(() {
      switch (_currentStep) {
        case PaymentStep.confirmation:
          Navigator.pop(context);
          break;
        case PaymentStep.methodSelection:
          _currentStep = PaymentStep.confirmation;
          break;
        case PaymentStep.processing:
          _currentStep = PaymentStep.methodSelection;
          break;
      }
    });
  }

  /// 결제 프로세스 시작
  void _startPaymentProcess() {
    setState(() {
      _isWebViewLoading = true;
    });
  }

  /// 결제 성공 처리
  void _onPaymentSuccess(String paymentKey) async {
    try {
      await ref.read(orderProvider.notifier).processPayment(
            paymentKey: paymentKey,
            amount: widget.amount!,
          );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/order-success',
          arguments: {
            'orderId': widget.orderId,
            'paymentKey': paymentKey,
            'amount': widget.amount,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorAndGoBack('결제 처리 중 오류가 발생했습니다: ${e.toString()}');
      }
    }
  }

  /// 결제 실패/취소 처리
  void _onPaymentFailure(String? errorMessage) {
    setState(() {
      _isWebViewLoading = false;
      _currentStep = PaymentStep.methodSelection;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage ?? '결제가 취소되었습니다.'),
        backgroundColor: ColorPalette.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final currentOrder = orderState.currentOrder;

    if (currentOrder == null || widget.amount == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToPreviousStep,
        ),
      ),
      body: Column(
        children: [
          // 진행 단계 표시
          _buildProgressIndicator(),

          // 단계별 컨텐츠
          Expanded(
            child: _buildStepContent(currentOrder),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// 앱바 제목
  String _getAppBarTitle() {
    switch (_currentStep) {
      case PaymentStep.confirmation:
        return '결제 정보 확인';
      case PaymentStep.methodSelection:
        return '결제 수단 선택';
      case PaymentStep.processing:
        return '결제 진행';
    }
  }

  /// 진행 단계 표시
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStepDot(1, _currentStep.index >= 0, '정보확인'),
          _buildStepLine(_currentStep.index >= 1),
          _buildStepDot(2, _currentStep.index >= 1, '결제수단'),
          _buildStepLine(_currentStep.index >= 2),
          _buildStepDot(3, _currentStep.index >= 2, '결제완료'),
        ],
      ),
    );
  }

  /// 단계 점 표시
  Widget _buildStepDot(int step, bool isActive, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? ColorPalette.primary : Colors.grey[300],
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyles.bodySmall.copyWith(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.spacingXs),
          Text(
            label,
            style: TextStyles.bodySmall.copyWith(
              color: isActive ? ColorPalette.primary : Colors.grey[600],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// 단계 연결선
  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? ColorPalette.primary : Colors.grey[300],
      ),
    );
  }

  /// 단계별 컨텐츠
  Widget _buildStepContent(OrderModel order) {
    switch (_currentStep) {
      case PaymentStep.confirmation:
        return _buildConfirmationStep(order);
      case PaymentStep.methodSelection:
        return _buildMethodSelectionStep();
      case PaymentStep.processing:
        return _buildProcessingStep(order);
    }
  }

  /// 1단계: 결제 정보 확인
  Widget _buildConfirmationStep(OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 주문 정보
          _buildOrderInfoCard(order),
          const SizedBox(height: Dimensions.spacingLg),

          // 결제 금액 상세
          _buildPaymentAmountCard(),
          const SizedBox(height: Dimensions.spacingLg),

          // 배송/픽업 정보
          if (order.deliveryAddress != null)
            _buildDeliveryInfoCard(order.deliveryAddress!)
          else
            _buildPickupInfoCard(),
        ],
      ),
    );
  }

  /// 2단계: 결제 수단 선택
  Widget _buildMethodSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '결제 수단을 선택해주세요',
            style: TextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Dimensions.spacingLg),

          // 카드 결제
          _buildPaymentMethodTile(
            PaymentMethodType.card,
            Icons.credit_card,
            '카드 결제',
            '신용카드, 체크카드',
          ),

          const SizedBox(height: Dimensions.spacingMd),

          // 계좌이체
          _buildPaymentMethodTile(
            PaymentMethodType.transfer,
            Icons.account_balance,
            '계좌이체',
            '실시간 계좌이체',
          ),
        ],
      ),
    );
  }

  /// 3단계: 결제 진행
  Widget _buildProcessingStep(OrderModel order) {
    if (_isWebViewLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: Dimensions.spacingMd),
            Text('결제창을 준비중입니다...'),
          ],
        ),
      );
    }

    return TossPaymentsWebView(
      orderId: order.orderId,
      amount: widget.amount!,
      customerName: order.userId, // TODO: 실제 사용자 이름으로 변경
      customerEmail: '${order.userId}@example.com', // TODO: 실제 이메일로 변경
      paymentMethod: _selectedPaymentMethod,
      onSuccess: _onPaymentSuccess,
      onFailure: _onPaymentFailure,
      onLoaded: () {
        setState(() {
          _isWebViewLoading = false;
        });
      },
    );
  }

  /// 주문 정보 카드
  Widget _buildOrderInfoCard(OrderModel order) {
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
            Text(
              '주문 정보',
              style: TextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.spacingMd),
            _buildInfoRow('주문번호', order.orderId),
            _buildInfoRow(
                '주문일시', DateFormat('yyyy.MM.dd HH:mm').format(order.createdAt)),
            _buildInfoRow(
                '배송유형', order.deliveryAddress != null ? '택배 배송' : '픽업'),
          ],
        ),
      ),
    );
  }

  /// 결제 금액 카드
  Widget _buildPaymentAmountCard() {
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
            Text(
              '결제 금액',
              style: TextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.spacingMd),

            _buildAmountRow(
                '상품 금액', widget.amount! - 3000), // TODO: 실제 상품 금액 계산
            _buildAmountRow('배송비', 3000), // TODO: 실제 배송비 적용
            const Divider(),
            _buildAmountRow(
              '총 결제 금액',
              widget.amount!,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  /// 배송 정보 카드
  Widget _buildDeliveryInfoCard(DeliveryAddress deliveryAddress) {
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
            Text(
              '배송 정보',
              style: TextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.spacingMd),
            _buildInfoRow('받는 사람', deliveryAddress.recipientName),
            _buildInfoRow('연락처', deliveryAddress.recipientPhone),
            _buildInfoRow('주소',
                '${deliveryAddress.address} ${deliveryAddress.detailAddress ?? ''}'),
          ],
        ),
      ),
    );
  }

  /// 픽업 정보 카드
  Widget _buildPickupInfoCard() {
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
            Text(
              '픽업 정보',
              style: TextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.spacingMd),
            Text(
              '주문 완료 후 픽업 장소와 시간을 안내드립니다.',
              style: TextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// 결제 수단 선택 타일
  Widget _buildPaymentMethodTile(
    PaymentMethodType method,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(Dimensions.padding),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? ColorPalette.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(Dimensions.radiusMd),
          color:
              isSelected ? ColorPalette.primary.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? ColorPalette.primary : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(width: Dimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? ColorPalette.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ColorPalette.primary,
              ),
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
  Widget _buildAmountRow(String label, int amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
                : TextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
          Text(
            NumberFormat.currency(
                    locale: 'ko_KR', symbol: '₩', decimalDigits: 0)
                .format(amount),
            style: isTotal
                ? TextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.primary,
                  )
                : TextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// 하단 네비게이션 바
  Widget? _buildBottomNavigationBar() {
    if (_currentStep == PaymentStep.processing) {
      return null; // 결제 진행 중에는 버튼 숨김
    }

    return SafeArea(
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
            onPressed: _goToNextStep,
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: Dimensions.paddingMd),
              backgroundColor: ColorPalette.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _getNextButtonText(),
              style: TextStyles.buttonLarge,
            ),
          ),
        ),
      ),
    );
  }

  /// 다음 버튼 텍스트
  String _getNextButtonText() {
    switch (_currentStep) {
      case PaymentStep.confirmation:
        return '결제 수단 선택하기';
      case PaymentStep.methodSelection:
        return '${NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0).format(widget.amount!)} 결제하기';
      case PaymentStep.processing:
        return '결제 진행 중...';
    }
  }
}

/// 결제 단계
enum PaymentStep {
  confirmation, // 결제 정보 확인
  methodSelection, // 결제 수단 선택
  processing, // 결제 진행
}

/// 결제 수단 타입
enum PaymentMethodType {
  card, // 카드 결제
  transfer, // 계좌이체
}
