import 'package:flutter/material.dart';
import 'package:gonggoo_app/core/config/app_config.dart';
import 'package:gonggoo_app/core/theme/index.dart';
import 'package:gonggoo_app/features/products/models/product_model.dart';
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
            _buildProductInfo(context),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 상품명
                  Text(
                    product.name,
                    style: TextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.spacingXs),

                  // 2. 상품 설명
                  Text(
                    product.description,
                    style: TextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? ColorPalette.textSecondaryDark
                          : ColorPalette.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.spacingXs),

                  // 3. 면세/재고 정보 (부가 정보)
                  _buildAdditionalInfo(context),

                  // 4. 주문단위, 가격 정보 (최저가 정보로 제공), 배송 타입 (메타 정보) - 최하단
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLowestPriceInfo(context),
                      _buildDeliveryTypeInfo(context),
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

  Widget _buildProductInfo(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSm),
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                // 상품 이미지
                CachedNetworkImage(
                  imageUrl: product.mainImageUrl ?? '',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  // 메모리 캐시 최적화
                  memCacheWidth: 160,
                  memCacheHeight: 160,
                  // 디스크 캐시 최적화
                  maxWidthDiskCache: 320,
                  maxHeightDiskCache: 320,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: Dimensions.spacingMd),
      ],
    );
  }

  /// 최저가 정보 표시
  Widget _buildLowestPriceInfo(BuildContext context) {
    if (product.orderUnits.isEmpty) {
      return const SizedBox(width: Dimensions.spacingSm);
    }

    final lowestOrderUnit =
        product.orderUnits.reduce((a, b) => a.price < b.price ? a : b);
    final lowestPrice = lowestOrderUnit.price;
    final lowestQuantity = lowestOrderUnit.unit;

    return Text(
      '$lowestQuantity 당 $lowestPrice원',
      style: TextStyles.bodyMedium.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? ColorPalette.textPrimaryDark
            : ColorPalette.textPrimaryLight,
      ),
    );
  }

  Widget _buildDeliveryTypeInfo(BuildContext context) {
    return Row(
      children: [
        Icon(
          product.deliveryType == '픽업' ? Icons.store : Icons.local_shipping,
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
    );
  }

  /// 면세 상품과 재고 정보를 표시하는 위젯
  Widget _buildAdditionalInfo(BuildContext context) {
    final bool isTaxFree = product.isTaxFree;
    final bool isOutOfStock = product.stock == 0;
    // Check if any order unit has stock below threshold
    final bool isLowStock = product.orderUnits.any(
        (unit) => unit.stock > 0 && unit.stock <= AppConfig.lowStockThreshold);

    // 표시할 내용이 없으면 빈 위젯 반환
    if (!isTaxFree && !isLowStock && !isOutOfStock) {
      return const SizedBox(height: Dimensions.spacingXs);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 품절 알림 (최우선)
            if (isOutOfStock) _buildOutOfStockBadge(context),
            // 재고 부족 알림 (품절이 아닐 때만)
            if (!isOutOfStock && isLowStock) _buildLowStockWarning(context),
            // 간격 추가
            if ((isOutOfStock || isLowStock) && isTaxFree)
              const SizedBox(width: Dimensions.spacingSm),
            // 면세 상품 배지
            if (isTaxFree) _buildTaxFreeBadge(context),
          ],
        ),
        const SizedBox(height: Dimensions.spacingXs),
      ],
    );
  }

  /// 면세 상품 배지
  Widget _buildTaxFreeBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: ColorPalette.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusXs),
        border: Border.all(
          color: ColorPalette.primary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '면세 상품',
        style: TextStyles.bodySmall.copyWith(
          color: ColorPalette.primary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  /// 재고 부족 경고 배지
  Widget _buildLowStockWarning(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFFF9500).withOpacity(0.2)
            : const Color(0xFFFF8C00).withOpacity(0.2),
        borderRadius: BorderRadius.circular(Dimensions.radiusXs),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFF9500).withOpacity(0.5)
              : const Color(0xFFFF8C00).withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        '품절 임박',
        style: TextStyles.bodySmall.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFF9500)
              : const Color(0xFFFF8C00),
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  /// 품절 배지
  Widget _buildOutOfStockBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(Dimensions.radiusXs),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[600]!
              : Colors.grey[400]!,
          width: 0.5,
        ),
      ),
      child: Text(
        '품절',
        style: TextStyles.bodySmall.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}
