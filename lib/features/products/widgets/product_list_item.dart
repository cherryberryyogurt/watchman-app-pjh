import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../../../core/theme/index.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductListItem extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  // 재고 임계값 상수 정의
  static const int _lowStockThreshold = 10;

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
                  // 1. 상품명 (가장 중요)
                  Text(
                    product.name,
                    style: TextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.spacingXs),

                  // 2. 가격 정보
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

                  // 3. 면세/재고 정보 (부가 정보)
                  _buildAdditionalInfo(context),

                  // 4. 배송 타입 (메타 정보) - 최하단
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
            ),
          ],
        ),
      ),
    );
  }

  /// 면세 상품과 재고 정보를 표시하는 위젯
  Widget _buildAdditionalInfo(BuildContext context) {
    final bool isTaxFree = product.isTaxFree;
    final bool isLowStock = product.stock <= _lowStockThreshold;

    // 둘 다 표시할 내용이 없으면 빈 위젯 반환
    if (!isTaxFree && !isLowStock) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 재고 부족 알림
            if (isLowStock) _buildLowStockWarning(context),
            // 두 정보가 모두 있을 때 간격 추가
            if (isTaxFree && isLowStock)
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
        color: ColorPalette.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusXs),
        border: Border.all(
          color: ColorPalette.primary.withOpacity(0.3),
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

  /// 재고 부족 경고
  Widget _buildLowStockWarning(BuildContext context) {
    return Text(
      '잔여 수량: ${product.stock}개',
      style: TextStyles.bodySmall.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFFF9500) // 다크모드용 주황색
            : const Color(0xFFFF8C00), // 라이트모드용 주황색 (warning 색상)
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
