import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/index.dart';
import '../models/order_model.dart';
import '../models/order_enums.dart';
import '../repositories/order_repository.dart';
import '../widgets/order_status_badge.dart';

/// 주문 상세 화면
class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  OrderModel? _order;
  List<OrderedProduct>? _orderedProducts;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  /// 주문 상세 정보 로드
  Future<void> _loadOrderDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final orderRepository = ref.read(orderRepositoryProvider);
      final orderData =
          await orderRepository.getOrderWithProducts(widget.orderId);

      if (orderData != null) {
        setState(() {
          _order = orderData['order'] as OrderModel;
          _orderedProducts =
              orderData['orderedProducts'] as List<OrderedProduct>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '주문을 찾을 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '주문 정보를 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 🆕 환불 정책 다이얼로그 표시
  void _showRefundPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '<와치맨 공동구매 반품/교환/환불 정책>',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '''1. 기본 원칙
당사는 『전자상거래 등에서의 소비자보호에 관한 법률』에 따라, 소비자의 권리를 보호하며 다음과 같은 기준으로 반품, 교환, 환불을 처리합니다.

2. 반품 및 교환 가능 기간
- 신선식품(농수축산물)의 경우 수령일로부터 2일 이내, 영업시간 내에 접수된 경우만 가능
- 가공식품 등 기타 상품의 경우 수령일로부터 7일 이내, 영업시간 내에 접수된 경우만 가능
- 수령일이 불분명한 경우, 배송완료를 공지한 날(픽업/직접배송) 또는 배송완료로 표시된 날(택배발송) 기준으로 산정

3. 반품 및 교환이 가능한 경우
- 상품에 하자가 있는 경우 (파손, 부패, 오배송 등)
- 제품이 소비자의 과실 없이 변질·손상된 경우
- 판매자의 귀책사유로 인해 제품에 하자가 발생한 경우
- 표시·광고 내용과 다르거나, 계약 내용과 다르게 이행된 경우
- 동일 상품으로의 교환 요청이 어려울 경우, 환불로 처리
- 농수산물의 경우, 당일 수령 후 2일 이내 상태 이상 발견 시 사진과 함께 영업시간 내 고객센터로 연락

4. 반품 및 교환이 불가능한 경우
- 소비자 귀책 사유로 상품이 멸실·훼손된 경우
- 소비자의 사용 또는 일부 소비로 상품의 가치가 현저히 감소한 경우
- 신선식품(농산물 등) 특성상 단순 변심, 외관 또는 맛과 같은 주관적인 요소가 반영될 수 있는 사유로 인한 반품은 불가
- 공동구매 특성상 수령 장소 및 시간에 맞춰 수령하지 않아 발생한 품질 저하 또는 유통문제

5. 환불 처리
- 환불은 카드결제 취소 또는 계좌환불 방식으로 진행됩니다.
- PG사 결제 취소 기준에 따라 영업일 기준 3~7일 이내 처리됩니다.
- 카드결제의 경우, 승인 취소는 카드사 정책에 따라 시일이 소요될 수 있습니다.
- 현금결제(무통장 입금) 환불 시, 정확한 계좌 정보를 고객이 제공해야 하며, 제공된 계좌 정보 오류로 인한 불이익은 책임지지 않습니다.

6. 고객 문의처
- 어플 내 [고객문의] 메뉴
- 각 오픈채팅방 내 CS담당자
- 카카오톡 '와치맨컴퍼니'
- 고객센터 010-6486-2591
- 운영시간: 오전 10시 ~ 오후 6시
- 문의 접수 후 영업일 기준 1~2일 내 회신 드립니다.

7. 기타
본 정책은 소비자 보호와 서비스 신뢰 유지를 위한 기준이며, 공동구매 특성상 일부 사항은 사전 고지 없이 변경될 수 있습니다. 변경 시, 어플 공지사항 및 약관 페이지를 통해 고지합니다.''',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 상세'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ColorPalette.error,
            ),
            const SizedBox(height: Dimensions.spacingMd),
            Text(
              '오류가 발생했습니다',
              style: TextStyles.titleMedium,
            ),
            const SizedBox(height: Dimensions.spacingSm),
            Text(
              _errorMessage!,
              style: TextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.spacingLg),
            ElevatedButton(
              onPressed: _loadOrderDetail,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_order == null) {
      return const Center(
        child: Text('주문 정보가 없습니다.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrderDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(),
            const SizedBox(height: Dimensions.spacingLg),
            _buildOrderStatus(),
            const SizedBox(height: Dimensions.spacingLg),
            _buildOrderedProducts(),
            const SizedBox(height: Dimensions.spacingLg),
            _buildPaymentInfo(),
            if (_order!.deliveryAddress != null) ...[
              const SizedBox(height: Dimensions.spacingLg),
              _buildDeliveryInfo(),
            ],
            if (_order!.deliveryType == DeliveryType.pickup &&
                _order!.selectedPickupPoint != null) ...[
              const SizedBox(height: Dimensions.spacingLg),
              _buildPickupPointInfo(),
            ],
            const SizedBox(height: Dimensions.spacingXl),
            _buildPolicyLink(),
            const SizedBox(height: Dimensions.spacingLg),
          ],
        ),
      ),
    );
  }

  /// 주문 헤더 정보
  Widget _buildOrderHeader() {
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '주문 정보',
                  style: TextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                OrderStatusBadge(status: _order!.status),
              ],
            ),
            const SizedBox(height: Dimensions.spacingMd),
            _buildInfoRow('주문번호', _formatOrderId(_order!.orderId)),
            _buildInfoRow('주문일시', _formatOrderDate(_order!.createdAt)),
            _buildInfoRow('총 결제금액', priceFormat.format(_order!.totalAmount)),
          ],
        ),
      ),
    );
  }

  /// 주문 상태 타임라인
  Widget _buildOrderStatus() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '주문 진행 상황',
              style: TextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.spacingMd),
            // TODO: 실제 타임라인 위젯 구현
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingMd),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              ),
              child: Text(
                '현재 상태: ${_order!.status.displayName}',
                style: TextStyles.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 주문 상품 목록
  Widget _buildOrderedProducts() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '주문 상품',
              style: TextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.spacingMd),
            if (_orderedProducts != null && _orderedProducts!.isNotEmpty)
              ..._orderedProducts!.map((product) => _buildProductItem(product))
            else
              const Text('주문 상품 정보가 없습니다.'),
          ],
        ),
      ),
    );
  }

  /// 개별 상품 아이템
  Widget _buildProductItem(OrderedProduct product) {
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingMd),
      padding: const EdgeInsets.all(Dimensions.paddingMd),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(Dimensions.radiusSm),
      ),
      child: Row(
        children: [
          // 상품 이미지 (임시)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            ),
            child: const Icon(Icons.image, color: Colors.grey),
          ),
          const SizedBox(width: Dimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Dimensions.spacingXs),
                Text(
                  '${priceFormat.format(product.unitPrice)} × ${product.quantity}개',
                  style: TextStyles.bodySmall,
                ),
                const SizedBox(height: Dimensions.spacingXs),
                Text(
                  '소계: ${priceFormat.format(product.totalPrice)}',
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 결제 정보
  Widget _buildPaymentInfo() {
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    // 🆕 최종 결제 금액 계산
    int finalAmountPaid = _order!.totalAmount;
    if (_order!.status == OrderStatus.cancelled) {
      finalAmountPaid = 0;
    } else if (_order!.paymentInfo?.balanceAmount != null) {
      finalAmountPaid = _order!.paymentInfo!.balanceAmount!;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '결제 정보',
              style: TextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.spacingMd),
            if (_order!.paymentInfo != null) ...[
              ..._buildPaymentStatusDetails(_order!, priceFormat),
              const Divider(height: Dimensions.spacingLg),
              _buildInfoRow(
                  '상품 금액', priceFormat.format(_order!.totalProductAmount)),
              if (_order!.totalDeliveryFee > 0)
                _buildInfoRow(
                    '배송비', priceFormat.format(_order!.totalDeliveryFee)),
              const Divider(height: Dimensions.spacingLg),
              _buildInfoRow(
                '총 결제금액',
                priceFormat.format(finalAmountPaid),
                isTotal: true,
              ),
            ] else
              const Text('결제 정보가 없습니다.'),
          ],
        ),
      ),
    );
  }

  /// 🆕 결제 상태에 따른 상세 정보 위젯 목록 생성
  List<Widget> _buildPaymentStatusDetails(
      OrderModel order, NumberFormat priceFormat) {
    // 취소된 주문
    if (order.status == OrderStatus.cancelled) {
      return [
        _buildInfoRow(
          '결제 상태',
          '결제 취소',
          valueColor: ColorPalette.error,
        ),
        if (order.canceledAt != null)
          _buildInfoRow('취소 일시', _formatOrderDate(order.canceledAt)),
        if (order.cancelReason != null)
          _buildInfoRow('취소 사유', order.cancelReason!),
        _buildInfoRow('취소 금액', priceFormat.format(order.totalAmount)),
      ];
    }

    // 환불된 주문 (전액 또는 부분)
    final paymentInfo = order.paymentInfo;
    if (paymentInfo != null) {
      final totalAmount = paymentInfo.totalAmount;
      final balanceAmount = paymentInfo.balanceAmount ?? totalAmount;
      final refundedAmount = totalAmount - balanceAmount;

      if (refundedAmount > 0) {
        final isFullRefund = balanceAmount == 0;
        return [
          _buildInfoRow(
            '결제 상태',
            isFullRefund ? '전액 환불' : '부분 환불',
            valueColor: ColorPalette.warning,
          ),
          _buildInfoRow('결제 금액', priceFormat.format(totalAmount)),
          _buildInfoRow(
            '환불된 금액',
            priceFormat.format(refundedAmount),
            valueColor: ColorPalette.warning,
          ),
          if (paymentInfo.cancels != null)
            for (var cancel in paymentInfo.cancels!)
              _buildInfoRow(
                '  - (${_formatOrderDate(DateTime.tryParse(cancel['canceledAt']))})',
                '-${priceFormat.format(cancel['cancelAmount'])}',
              ),
        ];
      }
    }

    // 정상 결제 완료된 주문
    return [
      _buildInfoRow(
        '결제 상태',
        '결제 완료',
        valueColor: ColorPalette.success,
      ),
      if (order.paymentInfo?.method != null)
        _buildInfoRow('결제 수단', order.paymentInfo!.method!.displayName),
      if (order.paymentInfo?.approvedAt != null)
        _buildInfoRow(
            '결제 완료일시', _formatOrderDate(order.paymentInfo!.approvedAt)),
    ];
  }

  /// 픽업 정보
  Widget _buildPickupPointInfo() {
    final pickupPoint = _order!.selectedPickupPoint!;

    return Card(
      margin: EdgeInsets.zero,
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
            _buildInfoRow('픽업 장소', pickupPoint.placeName),
            _buildInfoRow('주소', pickupPoint.address),
            _buildInfoRow('운영 시간', pickupPoint.operatingHours),
            if (pickupPoint.hasContact)
              _buildInfoRow('연락처', pickupPoint.contact!),
            if (pickupPoint.hasInstructions)
              _buildInfoRow('안내사항', pickupPoint.instructions!),
          ],
        ),
      ),
    );
  }

  /// 배송 정보
  Widget _buildDeliveryInfo() {
    return Card(
      margin: EdgeInsets.zero,
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
            _buildInfoRow('수령인', _order!.deliveryAddress!.recipientName),
            _buildInfoRow('연락처', _order!.deliveryAddress!.recipientPhone),
            _buildInfoRow('배송지', _order!.deliveryAddress!.fullAddress),
            if (_order!.deliveryAddress!.deliveryNote != null)
              _buildInfoRow('배송 메모', _order!.deliveryAddress!.deliveryNote!),
          ],
        ),
      ),
    );
  }

  /// 정보 행 위젯
  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyles.bodyMedium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? ColorPalette.textSecondaryDark
                    : ColorPalette.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isTotal
                  ? TextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)
                  : TextStyles.bodyMedium.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  /// 주문번호 포맷팅
  String _formatOrderId(String orderId) {
    if (orderId.length > 13) {
      return orderId.substring(orderId.length - 13);
    }
    return orderId;
  }

  /// 날짜 포맷팅
  String _formatOrderDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy.MM.dd HH:mm').format(date);
  }

  /// 🆕 환불 정책 링크 위젯
  Widget _buildPolicyLink() {
    return Center(
      child: GestureDetector(
        onTap: _showRefundPolicyDialog,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.spacingSm),
          child: Text(
            '와치맨 공동구매 반품/교환/환불 정책 보기',
            style: TextStyles.bodySmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? ColorPalette.textSecondaryDark
                  : ColorPalette.textSecondaryLight,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}
