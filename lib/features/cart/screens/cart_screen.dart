import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_state.dart';
import '../widgets/cart_item.dart';
import '../widgets/delivery_type_accordion.dart';
import '../../../core/theme/index.dart';

class CartScreen extends ConsumerStatefulWidget {
  static const String routeName = '/cart';

  const CartScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Load cart items when screen is first shown with a slight delay
    // to ensure authentication state is fully propagated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to allow auth state to propagate fully
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadCartItems();
      });
    });
  }

  Future<void> _loadCartItems() async {
    try {
      await ref.read(cartProvider.notifier).loadCartItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('장바구니를 불러오는데 실패했습니다: $e'),
            backgroundColor: ColorPalette.error,
          ),
        );
      }
    }
  }

  void _updateQuantity(String cartItemId, int quantity) async {
    try {
      await ref.read(cartProvider.notifier).updateCartItemQuantity(cartItemId, quantity);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수량을 업데이트하는데 실패했습니다: $e'),
            backgroundColor: ColorPalette.error,
          ),
        );
      }
    }
  }

  void _removeItem(String cartItemId) async {
    try {
      await ref.read(cartProvider.notifier).removeCartItem(cartItemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('상품이 장바구니에서 제거되었습니다.'),
            backgroundColor: ColorPalette.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상품을 제거하는데 실패했습니다: $e'),
            backgroundColor: ColorPalette.error,
          ),
        );
      }
    }
  }

  void _toggleSelect(String cartItemId) {
    ref.read(cartProvider.notifier).toggleItemSelection(cartItemId);
  }

  void _toggleSelectAll(bool value) {
    if (value) {
      ref.read(cartProvider.notifier).selectAllItems();
    } else {
      ref.read(cartProvider.notifier).unselectAllItems();
    }
  }

  void _setFilterType(CartFilterType filterType) {
    ref.read(cartProvider.notifier).setFilterType(filterType);
  }

  void _proceedToCheckout() {
    final cartState = ref.read(cartProvider);
    final selectedItems = cartState.selectedItems;
    
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('상품을 선택해주세요.'),
          backgroundColor: ColorPalette.warning,
        ),
      );
      return;
    }
    
    // Prevent mixed delivery types
    if (cartState.hasMixedDeliveryTypesSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('픽업 상품과 배송 상품은 함께 결제할 수 없습니다.'),
          backgroundColor: ColorPalette.warning,
        ),
      );
      return;
    }
    
    // Here you would navigate to checkout screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedItems.length}개 상품 결제를 진행합니다.'),
        backgroundColor: ColorPalette.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartItems = cartState.filteredCartItems;
    final isLoading = cartState.isLoading;
    final status = cartState.status;
    final errorMessage = cartState.errorMessage;
    
    // Get counts for each filter type
    final allCount = cartState.cartItems.length;
    final pickupCount = cartState.cartItems.where((item) => item.productDeliveryType == '픽업').length;
    final deliveryCount = cartState.cartItems.where((item) => item.productDeliveryType == '배송').length;
    
    // Format price
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        actions: [
          // Select all / Deselect all toggle
          Row(
            children: [
              Checkbox(
                value: cartState.areAllItemsSelected,
                onChanged: (value) => _toggleSelectAll(value ?? false),
                activeColor: ColorPalette.primary,
              ),
              Text(
                cartState.areAllItemsSelected ? '전체 해제' : '전체 선택',
                style: TextStyles.bodySmall,
              ),
              const SizedBox(width: Dimensions.spacingMd),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isLoading && status == CartLoadStatus.loading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (status == CartLoadStatus.error)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '오류가 발생했습니다',
                    style: TextStyles.titleMedium,
                  ),
                  const SizedBox(height: Dimensions.spacingSm),
                  Text(
                    errorMessage ?? '알 수 없는 오류',
                    style: TextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spacingMd),
                  ElevatedButton(
                    onPressed: _loadCartItems,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          else if (cartItems.isEmpty && !isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: ColorPalette.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: ColorPalette.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingLg),
                  Text(
                    '장바구니가 비어있습니다',
                    style: TextStyles.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spacingSm),
                  Text(
                    '상품을 담아보세요!',
                    style: TextStyles.bodyLarge.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? ColorPalette.textSecondaryDark
                          : ColorPalette.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                // Delivery Type Filter Accordion
                DeliveryTypeAccordion(
                  currentFilter: cartState.filterType,
                  onFilterChanged: _setFilterType,
                  allCount: allCount,
                  pickupCount: pickupCount,
                  deliveryCount: deliveryCount,
                ),
                
                // Cart Items List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadCartItems,
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return CartItem(
                          item: item,
                          isSelected: item.isSelected,
                          onSelectChanged: (_) => _toggleSelect(item.id),
                          onQuantityChanged: (quantity) => _updateQuantity(item.id, quantity),
                          onRemove: () => _removeItem(item.id),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            
          // Loading indicator
          if (isLoading && status != CartLoadStatus.loading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Colors.transparent,
                color: ColorPalette.primary,
              ),
            ),
        ],
      ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : BottomAppBar(
              child: Container(
                padding: const EdgeInsets.all(Dimensions.padding),
                height: 100,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total price row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '총 ${cartState.selectedItems.length}개 상품',
                          style: TextStyles.bodyMedium,
                        ),
                        Text(
                          priceFormat.format(cartState.totalSelectedPrice),
                          style: TextStyles.titleLarge.copyWith(
                            color: ColorPalette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.spacingSm),
                    
                    // Checkout button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _proceedToCheckout,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingMd,
                          ),
                          backgroundColor: ColorPalette.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          '주문하기',
                          style: TextStyles.buttonLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 