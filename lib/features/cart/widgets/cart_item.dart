import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cart_item_model.dart';
import '../../../core/theme/index.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartItem extends StatelessWidget {
  final CartItemModel item;
  final bool isSelected;
  final Function(bool?) onSelectChanged;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  
  const CartItem({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.onSelectChanged,
    required this.onQuantityChanged,
    required this.onRemove,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Format price
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
          
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusSm),
            child: SizedBox(
              width: 80,
              height: 80,
              child: item.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.thumbnailUrl!,
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
                // Delivery Type Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingXs,
                    vertical: Dimensions.paddingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: item.productDeliveryType == '픽업'
                        ? ColorPalette.primary.withOpacity(0.1)
                        : ColorPalette.secondary.withOpacity(0.1),
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
                
                // Product Name
                Text(
                  item.productName,
                  style: TextStyles.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Dimensions.spacingXs),
                
                // Product Price
                Row(
                  children: [
                    Text(
                      priceFormat.format(item.productPrice),
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / ${item.productOrderUnit}',
                      style: TextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.spacingMd),
                
                // Quantity Controls and Remove Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(Dimensions.radiusXs),
                      ),
                      child: Row(
                        children: [
                          // Decrease Button
                          InkWell(
                            onTap: () {
                              if (item.quantity > 1) {
                                onQuantityChanged(item.quantity - 1);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(Dimensions.paddingXs),
                              child: const Icon(
                                Icons.remove,
                                size: 16,
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
                              padding: const EdgeInsets.all(Dimensions.paddingXs),
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
                
                // Total Price
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
} 