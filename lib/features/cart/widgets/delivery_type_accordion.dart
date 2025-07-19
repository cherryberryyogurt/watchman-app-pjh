import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/dimensions.dart';
import '../../../core/theme/color_palette.dart';

enum CartFilterType {
  all,
  delivery,
  pickup,
}

class DeliveryTypeAccordion extends ConsumerWidget {
  final CartFilterType selectedFilter;
  final Function(CartFilterType) onFilterChanged;
  final int allCount;
  final int pickupCount;
  final int deliveryCount;

  const DeliveryTypeAccordion({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.allCount,
    required this.pickupCount,
    required this.deliveryCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Text(
          _getFilterTitle(),
          style: TextStyles.titleSmall,
        ),
        children: [
          Container(
            padding: const EdgeInsets.only(
              left: Dimensions.padding,
              right: Dimensions.padding,
              bottom: Dimensions.padding,
            ),
            child: Column(
              children: [
                _buildFilterOption(
                  context,
                  CartFilterType.all,
                  '전체',
                  allCount,
                  Icons.shopping_basket_outlined,
                ),
                const SizedBox(height: Dimensions.spacingSm),
                _buildFilterOption(
                  context,
                  CartFilterType.pickup,
                  '픽업',
                  pickupCount,
                  Icons.store,
                ),
                const SizedBox(height: Dimensions.spacingSm),
                _buildFilterOption(
                  context,
                  CartFilterType.delivery,
                  '택배',
                  deliveryCount,
                  Icons.local_shipping,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    CartFilterType filterType,
    String label,
    int count,
    IconData icon,
  ) {
    final isSelected = selectedFilter == filterType;

    return InkWell(
      onTap: () => onFilterChanged(filterType),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSm),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorPalette.primary.withValues(alpha: 0.1)
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]
                  : Colors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusSm),
          border: Border.all(
            color: isSelected
                ? ColorPalette.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? ColorPalette.primary
                  : Theme.of(context).brightness == Brightness.dark
                      ? ColorPalette.textPrimaryDark
                      : ColorPalette.textPrimaryLight,
              size: 20,
            ),
            const SizedBox(width: Dimensions.spacingSm),
            Text(
              label,
              style: TextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? ColorPalette.primary
                    : Theme.of(context).brightness == Brightness.dark
                        ? ColorPalette.textPrimaryDark
                        : ColorPalette.textPrimaryLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingXs,
                vertical: Dimensions.paddingXxs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? ColorPalette.primary
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[600]
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(Dimensions.radiusXs),
              ),
              child: Text(
                count.toString(),
                style: TextStyles.labelSmall.copyWith(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).brightness == Brightness.dark
                          ? ColorPalette.textPrimaryDark
                          : ColorPalette.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterTitle() {
    switch (selectedFilter) {
      case CartFilterType.all:
        return '전체 상품';
      case CartFilterType.pickup:
        return '픽업 상품';
      case CartFilterType.delivery:
        return '택배 상품';
    }
  }
}
