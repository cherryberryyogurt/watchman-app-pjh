import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../../../core/theme/index.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductListItem extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Format price
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    // Calculate time ago
    final timeAgo = _getTimeAgo(product.createdAt);

    return InkWell(
      onTap: onTap,
      child: Container(
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
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              child: SizedBox(
                width: 100,
                height: 100,
                child: product.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: ColorPalette.placeholder,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: ColorPalette.placeholder,
                          child: const Icon(Icons.error),
                        ),
                      )
                    : Container(
                        color: ColorPalette.placeholder,
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            const SizedBox(width: Dimensions.spacingMd),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.spacingXs),
                  Text(
                    product.locationTagName ?? '위치 정보 없음',
                    style: TextStyles.bodySmall.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? ColorPalette.textSecondaryDark
                          : ColorPalette.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingXs),
                  Row(
                    children: [
                      Text(
                        priceFormat.format(product.price),
                        style: TextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' / ${product.orderUnit}',
                        style: TextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spacingXs),

                  // Bottom row with time and delivery type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeAgo,
                        style: TextStyles.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? ColorPalette.textTertiaryDark
                              : ColorPalette.textTertiaryLight,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            product.deliveryType == '픽업'
                                ? Icons.store
                                : Icons.local_shipping,
                            size: 16,
                            color: ColorPalette.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.deliveryType,
                            style: TextStyles.bodySmall.copyWith(
                              color: ColorPalette.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
