import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/index.dart';
import '../models/order_model.dart';
import '../models/order_enums.dart';
import 'order_status_badge.dart';

/// 주문 목록 아이템 위젯
class OrderListItem extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderListItem({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 주문번호, 날짜, 상태
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '주문번호 ${_formatOrderId(order.orderId)}',
                          style: TextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: Dimensions.spacingXs),
                        Text(
                          _formatOrderDate(order.createdAt),
                          style: TextStyles.bodySmall.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? ColorPalette.textSecondaryDark
                                    : ColorPalette.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),

              const SizedBox(height: Dimensions.spacingMd),

              // 주문 정보: 상품 수량, 배송 타입
              Row(
                children: [
                  Icon(
                    _getDeliveryIcon(),
                    size: 16,
                    color: ColorPalette.primary,
                  ),
                  const SizedBox(width: Dimensions.spacingXs),
                  Text(
                    _getDeliveryTypeText(),
                    style: TextStyles.bodySmall.copyWith(
                      color: ColorPalette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingMd),
                  Text(
                    '상품 ${_getProductCount()}개',
                    style: TextStyles.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.spacingSm),

              // 가격 정보
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '총 결제금액',
                    style: TextStyles.bodyMedium,
                  ),
                  Text(
                    priceFormat.format(order.totalAmount),
                    style: TextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.primary,
                    ),
                  ),
                ],
              ),

              // 배송지 정보 (배송인 경우만)
              if (order.deliveryAddress != null) ...[
                const SizedBox(height: Dimensions.spacingSm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? ColorPalette.textSecondaryDark
                            : ColorPalette.textSecondaryLight,
                      ),
                      const SizedBox(width: Dimensions.spacingXs),
                      Expanded(
                        child: Text(
                          '${order.deliveryAddress!.recipientName} | ${order.deliveryAddress!.address}',
                          style: TextStyles.bodySmall.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? ColorPalette.textSecondaryDark
                                    : ColorPalette.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 액션 버튼들
              if (_shouldShowActionButtons()) ...[
                const SizedBox(height: Dimensions.spacingMd),
                Row(
                  children: [
                    if (order.isCancellable) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showCancelDialog(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorPalette.error,
                            side: const BorderSide(color: ColorPalette.error),
                          ),
                          child: const Text('주문 취소'),
                        ),
                      ),
                      const SizedBox(width: Dimensions.spacingSm),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalette.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('상세 보기'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 주문번호 포맷팅 (뒤 8자리만 표시)
  String _formatOrderId(String orderId) {
    if (orderId.length > 8) {
      return orderId.substring(orderId.length - 8);
    }
    return orderId;
  }

  /// 주문 날짜 포맷팅
  String _formatOrderDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '오늘 ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays == 1) {
      return '어제 ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return DateFormat('MM.dd').format(date);
    }
  }

  /// 배송 타입 아이콘
  IconData _getDeliveryIcon() {
    if (order.deliveryAddress != null) {
      return Icons.local_shipping;
    } else {
      return Icons.store;
    }
  }

  /// 배송 타입 텍스트
  String _getDeliveryTypeText() {
    if (order.deliveryAddress != null) {
      return '택배';
    } else {
      return '픽업';
    }
  }

  /// 상품 개수 (실제로는 OrderedProduct 개수를 가져와야 함)
  String _getProductCount() {
    // TODO: 실제 주문 상품 개수 계산
    // 현재는 임시로 1개로 표시
    return '1';
  }

  /// 액션 버튼을 표시할지 여부
  bool _shouldShowActionButtons() {
    return order.isCancellable || order.status.isInProgress;
  }

  /// 주문 취소 다이얼로그
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주문 취소'),
        content: const Text('정말로 주문을 취소하시겠습니까?\n취소된 주문은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 주문 취소 로직 구현
              _cancelOrder(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: ColorPalette.error,
            ),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
  }

  /// 주문 취소 실행
  void _cancelOrder(BuildContext context) {
    // TODO: 실제 주문 취소 API 호출
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('주문 취소 기능은 곧 제공될 예정입니다.'),
        backgroundColor: ColorPalette.warning,
      ),
    );
  }
}
