import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_state.dart';
import '../widgets/cart_item.dart';
import '../../../core/theme/index.dart';
import '../../order/screens/checkout_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  static const String routeName = '/cart';

  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Add listener to refresh UI when tab changes
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Load cart items when screen is first shown with a slight delay
    // to ensure authentication state is fully propagated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to allow auth state to propagate fully
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadCartItems();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      await ref
          .read(cartProvider.notifier)
          .updateCartItemQuantity(cartItemId, quantity);
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

  void _toggleSelectAllForCurrentTab(bool value) {
    final currentTabIndex = _tabController.index;
    final deliveryType = currentTabIndex == 0 ? '배송' : '픽업';

    if (value) {
      ref
          .read(cartProvider.notifier)
          .selectAllItemsByDeliveryType(deliveryType);
    } else {
      ref
          .read(cartProvider.notifier)
          .unselectAllItemsByDeliveryType(deliveryType);
    }
  }

  // Get selected items for current tab
  List<dynamic> _getCurrentTabSelectedItems(
      List<dynamic> deliveryItems, List<dynamic> pickupItems) {
    final currentTabIndex = _tabController.index;
    if (currentTabIndex == 0) {
      // 택배 탭: deliveryItems에서 선택된 것만
      return deliveryItems.where((item) => item.isSelected).toList();
    } else {
      // 픽업 탭: pickupItems에서 선택된 것만
      return pickupItems.where((item) => item.isSelected).toList();
    }
  }

  // Get current tab delivery type
  String _getCurrentTabDeliveryType() {
    return _tabController.index == 0 ? '배송' : '픽업';
  }

  // Get current tab display name
  String _getCurrentTabDisplayName() {
    return _tabController.index == 0 ? '택배' : '픽업';
  }

  void _proceedToCheckout() {
    final cartState = ref.read(cartProvider);
    final allCartItems = cartState.cartItems;

    // Separate items by delivery type
    final deliveryItems =
        allCartItems.where((item) => item.productDeliveryType == '배송').toList();
    final pickupItems =
        allCartItems.where((item) => item.productDeliveryType == '픽업').toList();

    // Get selected items for current tab only
    final selectedItems =
        _getCurrentTabSelectedItems(deliveryItems, pickupItems);
    final deliveryType = _getCurrentTabDeliveryType();
    final displayName = _getCurrentTabDisplayName();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$displayName 상품을 선택해주세요.'),
          backgroundColor: ColorPalette.warning,
        ),
      );
      return;
    }

    // Navigate to checkout screen with selected items and delivery type
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          items: selectedItems.cast<CartItemModel>(),
          deliveryType: deliveryType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final allCartItems = cartState.cartItems;
    final isLoading = cartState.isLoading;
    final status = cartState.status;
    final errorMessage = cartState.errorMessage;

    // Separate items by delivery type
    final deliveryItems =
        allCartItems.where((item) => item.productDeliveryType == '배송').toList();
    final pickupItems =
        allCartItems.where((item) => item.productDeliveryType == '픽업').toList();

    // Get selected items for current tab
    final currentTabSelectedItems =
        _getCurrentTabSelectedItems(deliveryItems, pickupItems);
    final currentTabDisplayName = _getCurrentTabDisplayName();

    // Calculate total price for current tab selected items
    final currentTabTotalPrice = currentTabSelectedItems.fold<double>(
      0.0,
      (prev, item) => prev + (item.productPrice * item.quantity),
    );

    // Format price
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('장바구니'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_shipping),
                    const SizedBox(width: 8),
                    Text('택배 (${deliveryItems.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store),
                    const SizedBox(width: 8),
                    Text('픽업 (${pickupItems.length})'),
                  ],
                ),
              ),
            ],
            labelColor: ColorPalette.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: ColorPalette.primary,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // 택배 탭
            _buildCartTabContent(
              cartItems: deliveryItems,
              deliveryType: '배송',
              isLoading: isLoading,
              status: status,
              errorMessage: errorMessage,
              cartState: cartState,
            ),
            // 픽업 탭
            _buildCartTabContent(
              cartItems: pickupItems,
              deliveryType: '픽업',
              isLoading: isLoading,
              status: status,
              errorMessage: errorMessage,
              cartState: cartState,
            ),
          ],
        ),
        persistentFooterButtons: currentTabSelectedItems.isEmpty
            ? null
            : [
                SafeArea(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.padding,
                      vertical: Dimensions.paddingSm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Total price row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$currentTabDisplayName 총 ${currentTabSelectedItems.length}개 상품',
                              style: TextStyles.bodyMedium,
                            ),
                            Text(
                              priceFormat.format(currentTabTotalPrice),
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
                              '$currentTabDisplayName 상품 주문하기 (${currentTabSelectedItems.length}개)',
                              style: TextStyles.buttonLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
        bottomNavigationBar: null,
      ),
    );
  }

  Widget _buildCartTabContent({
    required List cartItems,
    required String deliveryType,
    required bool isLoading,
    required CartLoadStatus status,
    required String? errorMessage,
    required dynamic cartState,
  }) {
    // Calculate if all items of this delivery type are selected
    final areAllTabItemsSelected =
        cartItems.isNotEmpty && cartItems.every((item) => item.isSelected);

    return RefreshIndicator(
      onRefresh: _loadCartItems,
      child: Stack(
        children: [
          if (isLoading && status == CartLoadStatus.loading)
            // 로딩 상태 - 스크롤 가능하게 만들기
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (status == CartLoadStatus.error)
            // 에러 상태 - 스크롤 가능하게 만들기
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: Center(
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
                ),
              ),
            )
          else if (cartItems.isEmpty && !isLoading)
            // 빈 상태 - 스크롤 가능하게 만들기
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: ColorPalette.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            deliveryType == '배송'
                                ? Icons.local_shipping
                                : Icons.store,
                            size: 64,
                            color: ColorPalette.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.spacingLg),
                      Text(
                        '${deliveryType == '배송' ? '택배' : '픽업'} 상품이 없습니다',
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
                      const SizedBox(height: Dimensions.spacingXl),
                      Text(
                        '아래로 드래그하여 새로고침할 수 있습니다',
                        style: TextStyles.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? ColorPalette.textSecondaryDark
                              : ColorPalette.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // 아이템이 있는 상태
            Column(
              children: [
                // Tab-specific Select All Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.padding,
                    vertical: Dimensions.paddingSm,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: areAllTabItemsSelected,
                        onChanged: (value) =>
                            _toggleSelectAllForCurrentTab(value ?? false),
                        activeColor: ColorPalette.primary,
                      ),
                      Text(
                        areAllTabItemsSelected
                            ? '${deliveryType == '배송' ? '택배' : '픽업'} 전체 해제'
                            : '${deliveryType == '배송' ? '택배' : '픽업'} 전체 선택',
                        style: TextStyles.bodyMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${cartItems.length}개 상품',
                        style: TextStyles.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? ColorPalette.textSecondaryDark
                              : ColorPalette.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return CartItem(
                        item: item,
                        isSelected: item.isSelected,
                        onSelectChanged: (_) => _toggleSelect(item.id),
                        onQuantityChanged: (quantity) =>
                            _updateQuantity(item.id, quantity),
                        onRemove: () => _removeItem(item.id),
                      );
                    },
                  ),
                ),
              ],
            ),

          // Loading indicator for additional loading states
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
    );
  }
}
