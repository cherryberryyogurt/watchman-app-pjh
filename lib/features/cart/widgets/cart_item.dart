import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cart_item_model.dart';
import '../../../core/theme/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CartItem extends StatelessWidget {
  final CartItemModel item;
  final bool isSelected;
  final Function(bool?) onSelectChanged;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onSelectChanged,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Format price with null safety
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Checkbox(
              value: isSelected,
              onChanged: onSelectChanged,
              activeColor: ColorPalette.primary,
            ),
          ),

          // Product Image with improved error handling
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            child: SizedBox(
              width: 80,
              height: 80,
              child: _buildProductImage(),
            ),
          ),
          const SizedBox(width: Dimensions.spacingMd),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Type Tag with null safety
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingXs,
                    vertical: Dimensions.paddingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: item.productDeliveryType == '픽업'
                        ? ColorPalette.primary.withValues(alpha: 0.1)
                        : ColorPalette.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusXs),
                  ),
                  child: Text(
                    item.productDeliveryType,
                    style: TextStyles.labelSmall.copyWith(
                      color: item.productDeliveryType == '픽업'
                          ? ColorPalette.primary
                          : ColorPalette.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.spacingSm),

                // Product Name with null safety
                Text(
                  item.productName.isNotEmpty ? item.productName : '상품명 없음',
                  style: TextStyles.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Dimensions.spacingXs),

                // Product Price with null safety
                Row(
                  children: [
                    Text(
                      priceFormat.format(item.productPrice),
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / ${item.productOrderUnit.isNotEmpty ? item.productOrderUnit : '개'}',
                      style: TextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.spacingMd),

                // Quantity Controls and Remove Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Controls with improved UX
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusXs),
                      ),
                      child: Row(
                        children: [
                          // Decrease Button
                          InkWell(
                            onTap: item.quantity > 1
                                ? () => onQuantityChanged(item.quantity - 1)
                                : null,
                            child: Container(
                              padding:
                                  const EdgeInsets.all(Dimensions.paddingXs),
                              child: Icon(
                                Icons.remove,
                                size: 16,
                                color: item.quantity > 1
                                    ? null
                                    : Theme.of(context).disabledColor,
                              ),
                            ),
                          ),

                          // Quantity
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSm,
                            ),
                            child: Text(
                              item.quantity.toString(),
                              style: TextStyles.bodyMedium,
                            ),
                          ),

                          // Increase Button
                          InkWell(
                            onTap: () {
                              onQuantityChanged(item.quantity + 1);
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.all(Dimensions.paddingXs),
                              child: const Icon(
                                Icons.add,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Remove Button
                    TextButton(
                      onPressed: onRemove,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSm,
                          vertical: Dimensions.paddingXxs,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '삭제',
                        style: TextStyles.labelSmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? ColorPalette.textSecondaryDark
                              : ColorPalette.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),

                // Total Price with null safety
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: Dimensions.spacingSm),
                    child: Text(
                      '합계: ${priceFormat.format(item.priceSum)}',
                      style: TextStyles.titleSmall.copyWith(
                        color: ColorPalette.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    // 이미지 URL이 유효한지 확인
    final hasValidUrl = item.thumbnailUrl != null &&
        item.thumbnailUrl!.isNotEmpty &&
        Uri.tryParse(item.thumbnailUrl!) != null;

    if (hasValidUrl) {
      return CachedNetworkImage(
        imageUrl: item.thumbnailUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 160,
        memCacheHeight: 160,
        maxWidthDiskCache: 320,
        maxHeightDiskCache: 320,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) {
          debugPrint('🖼️ 이미지 로드 실패: $url, 오류: $error');
          return _buildErrorWidget();
        },
        // 추가 에러 처리
        httpHeaders: const {
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
        },
      );
    } else {
      return _buildErrorWidget();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: ColorPalette.placeholder,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ColorPalette.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: ColorPalette.placeholder,
      child: Center(
        child: SvgPicture.asset(
          'assets/images/placeholder_product.svg',
          width: 80,
          height: 80,
          fit: BoxFit.contain,
          // SVG 로드 실패 시 fallback
          placeholderBuilder: (context) => const Icon(
            Icons.image_not_supported,
            color: Colors.grey,
            size: 32,
          ),
        ),
      ),
    );
  }
}
