import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/dimensions.dart';
import '../../cart/models/cart_item_model.dart';

/// 주문 요약 카드 위젯
class OrderSummaryCard extends StatelessWidget {
  final List<CartItemModel> items;
  final String deliveryType;
  final int subtotal;
  final int deliveryFee;
  final int? discount;
  final VoidCallback? onEditItems;

  const OrderSummaryCard({
    super.key,
    required this.items,
    required this.deliveryType,
    required this.subtotal,
    this.deliveryFee = 0,
    this.discount,
    this.onEditItems,
  });

  int get totalAmount => subtotal + deliveryFee - (discount ?? 0);

  @override
  Widget build(BuildContext context) {
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
            // 헤더
            Row(
              children: [
                Icon(
                  deliveryType == '배송' ? Icons.local_shipping : Icons.store,
                  color: ColorPalette.primary,
                  size: 20,
                ),
                const SizedBox(width: Dimensions.spacingSm),
                Text(
                  '주문 상품 (${deliveryType == '배송' ? '택배' : '픽업'})',
                  style: TextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onEditItems != null)
                  TextButton(
                    onPressed: onEditItems,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSm,
                        vertical: Dimensions.paddingXs,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '수정',
                      style: TextStyles.bodySmall.copyWith(
                        color: ColorPalette.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Dimensions.spacingMd),

            // 상품 목록
            Column(
              children:
                  items.map((item) => _buildOrderItem(context, item)).toList(),
            ),

            const SizedBox(height: Dimensions.spacingMd),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: Dimensions.spacingSm),

            // 가격 정보
            _buildPriceRow('상품 금액', priceFormat.format(subtotal)),
            if (deliveryFee > 0) ...[
              const SizedBox(height: Dimensions.spacingXs),
              _buildPriceRow('배송비', priceFormat.format(deliveryFee)),
            ],
            if (discount != null && discount! > 0) ...[
              const SizedBox(height: Dimensions.spacingXs),
              _buildPriceRow(
                '할인',
                '-${priceFormat.format(discount!)}',
                textColor: ColorPalette.success,
              ),
            ],
            const SizedBox(height: Dimensions.spacingSm),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: Dimensions.spacingSm),

            // 총 결제 금액
            _buildPriceRow(
              '총 결제 금액',
              priceFormat.format(totalAmount),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, CartItemModel item) {
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품 이미지
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                  ? Image.network(
                      item.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    )
                  : const Icon(Icons.image_not_supported),
            ),
          ),
          const SizedBox(width: Dimensions.spacingMd),

          // 상품 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Dimensions.spacingXs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '수량 ${item.quantity}개',
                      style: TextStyles.bodySmall.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? ColorPalette.textSecondaryDark
                            : ColorPalette.textSecondaryLight,
                      ),
                    ),
                    Text(
                      priceFormat.format(item.productPrice * item.quantity),
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String amount, {
    Color? textColor,
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
                  color: textColor,
                ),
        ),
      ],
    );
  }
}
