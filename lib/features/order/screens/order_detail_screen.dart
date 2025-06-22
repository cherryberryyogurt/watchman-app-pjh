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
            const SizedBox(height: Dimensions.spacingXl),
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
              _buildInfoRow('결제 상태', _order!.paymentInfo!.status.displayName),
              if (_order!.paymentInfo!.method != null)
                _buildInfoRow(
                    '결제 수단', _order!.paymentInfo!.method!.displayName),
              if (_order!.paymentInfo!.approvedAt != null)
                _buildInfoRow('결제 완료일시',
                    _formatOrderDate(_order!.paymentInfo!.approvedAt)),
            ] else
              const Text('결제 정보가 없습니다.'),
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
  Widget _buildInfoRow(String label, String value) {
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
              style: TextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// 주문번호 포맷팅
  String _formatOrderId(String orderId) {
    if (orderId.length > 8) {
      return orderId.substring(orderId.length - 8);
    }
    return orderId;
  }

  /// 날짜 포맷팅
  String _formatOrderDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy.MM.dd HH:mm').format(date);
  }
}
