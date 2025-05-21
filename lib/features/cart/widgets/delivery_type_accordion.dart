import 'package:flutter/material.dart';
import '../../../core/theme/index.dart';
import '../providers/cart_state.dart';

class DeliveryTypeAccordion extends StatelessWidget {
  final CartFilterType currentFilter;
  final Function(CartFilterType) onFilterChanged;
  final int allCount;
  final int pickupCount;
  final int deliveryCount;
  
  const DeliveryTypeAccordion({
    Key? key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.allCount,
    required this.pickupCount,
    required this.deliveryCount,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
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
                  '배송',
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
    final isSelected = currentFilter == filterType;
    
    return InkWell(
      onTap: () => onFilterChanged(filterType),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSm),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorPalette.primary.withOpacity(0.1)
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
    switch (currentFilter) {
      case CartFilterType.all:
        return '전체 상품';
      case CartFilterType.pickup:
        return '픽업 상품';
      case CartFilterType.delivery:
        return '배송 상품';
    }
  }
} 