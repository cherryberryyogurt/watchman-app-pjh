import 'package:flutter/material.dart';

import '../../../core/theme/index.dart';
import '../models/order_enums.dart';

/// 주문 상태별 필터 위젯
class OrderStatusFilter extends StatelessWidget {
  final OrderStatus? currentFilter;
  final Function(OrderStatus?) onFilterChanged;
  final Map<OrderStatus, int> orderCounts;

  const OrderStatusFilter({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.orderCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSm),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.padding),
        children: [
          _buildFilterChip(
            context: context,
            label: '전체',
            count: _getTotalCount(),
            isSelected: currentFilter == null,
            onTap: () => onFilterChanged(null),
          ),
          const SizedBox(width: Dimensions.spacingSm),
          ..._getFilterChips(context),
        ],
      ),
    );
  }

  /// 필터 칩 목록 생성
  List<Widget> _getFilterChips(BuildContext context) {
    /*
    결제대기: 결제 진행 과정에서 주문서에 근거하여 Order 컬렉션 생성 시 상태
    주문확인: 결제 요청 및 결제 승인까지 완료된 상태; 관리자 확인 전
    준비중: 관리자가 주문을 확인한 후 준비 중인 상태
    배송중: 준비가 완료된 주문이 배송 중인 상태 (배송 상품 only: 준비중 -> 배송중)
    픽업대기: 픽업지로 상품이 전달되었으며, 픽업 대기 중인 상태 (픽업 상품 only: 준비중 -> 픽업대기)
    배송완료: 배송이 완료된 주문의 상태 (배송 상품 only: 배송중 -> 배송완료)
    픽업완료: 픽업이 완료되고 사용자가 인증을 진행한 상태 (픽업 상품 only: 픽업대기 -> 픽업완료)
    완료: 주문이 완료된 상태; 픽업 완료 상품에 대하여 관리자가 픽업 인증 승인을 한 상태
    취소: 주문이 취소된 상태; 주문이 취소/환불된 상태
    */
    final filters = [
      _FilterItem(OrderStatus.pending, '결제대기'),
      _FilterItem(OrderStatus.confirmed, '주문확인'),
      _FilterItem(OrderStatus.preparing, '준비중'),
      _FilterItem(OrderStatus.shipped, '배송중'),
      _FilterItem(OrderStatus.readyForPickup, '픽업대기'),
      _FilterItem(OrderStatus.delivered, '배송완료'),
      _FilterItem(OrderStatus.pickedUp, '픽업완료'),
      _FilterItem(OrderStatus.finished, '완료'),
      _FilterItem(OrderStatus.cancelled, '취소'),
    ];

    return filters.map((filter) {
      final count = orderCounts[filter.status] ?? 0;

      return Padding(
        padding: const EdgeInsets.only(right: Dimensions.spacingSm),
        child: _buildFilterChip(
          context: context,
          label: filter.label,
          count: count,
          isSelected: currentFilter == filter.status,
          onTap: () => onFilterChanged(filter.status),
        ),
      );
    }).toList();
  }

  /// 개별 필터 칩 빌드
  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingMd,
          vertical: Dimensions.paddingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorPalette.primary
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
          border: Border.all(
            color: isSelected
                ? ColorPalette.primary
                : Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: Dimensions.spacingXs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : ColorPalette.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 전체 주문 개수 계산
  int _getTotalCount() {
    return orderCounts.values.fold(0, (sum, count) => sum + count);
  }
}

/// 필터 아이템 클래스
class _FilterItem {
  final OrderStatus status;
  final String label;

  const _FilterItem(this.status, this.label);
}
