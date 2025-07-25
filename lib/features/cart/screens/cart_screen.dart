import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_state.dart';
import '../widgets/cart_item.dart';
import '../../../core/theme/index.dart';
import '../../order/screens/checkout_screen.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/global_error_handler.dart';
import '../../order/models/payment_error_model.dart';
import '../../../core/widgets/error_snack_bar.dart';

class CartScreen extends ConsumerStatefulWidget {
  static const String routeName = '/cart';

  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Add listener to refresh UI when tab changes
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
        
        // When tab changes, select all items in the new tab
        if (_isInitialLoadComplete) {
          _selectAllItemsInCurrentTab();
        }
      }
    });

    // Load cart items when screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 지연 시간을 줄임 (500ms -> 100ms)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _loadCartItems();
        }
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
      
      // After loading, select all items in the current tab
      if (mounted && !_isInitialLoadComplete) {
        _isInitialLoadComplete = true;
        // Short delay to ensure UI is updated
        await Future.delayed(const Duration(milliseconds: 50));
        _selectAllItemsInCurrentTab();
      }
    } catch (e) {
      if (mounted) {
        // 🚨 글로벌 에러 핸들러 사용
        final paymentError = PaymentError(
          code: 'CART_LOAD_FAILED',
          message: '장바구니를 불러오는데 실패했습니다.',
          context: {
            'operation': 'loadCartItems',
            'originalError': e.toString(),
          },
        );
        GlobalErrorHandler.showErrorSnackBar(
          context,
          paymentError,
          onRetry: () => _loadCartItems(),
        );
      }
    }
  }
  
  void _selectAllItemsInCurrentTab() {
    final currentTabIndex = _tabController.index;
    final deliveryType = currentTabIndex == 0 ? '택배' : '픽업';
    ref.read(cartProvider.notifier).selectAllItemsByDeliveryType(deliveryType);
  }

  void _updateQuantity(String cartItemId, int quantity) async {
    try {
      await ref
          .read(cartProvider.notifier)
          .updateCartItemQuantity(cartItemId, quantity);
      
      // 수량이 변경되면 재고부족 플래그를 리셋 (재확인 필요하므로)
      ref.read(cartProvider.notifier).updateItemStockStatus(cartItemId, false);
    } catch (e) {
      if (mounted) {
        // 🚨 글로벌 에러 핸들러 사용
        final paymentError = PaymentError(
          code: 'CART_UPDATE_FAILED',
          message: '수량을 업데이트하는데 실패했습니다.',
          context: {
            'operation': 'updateQuantity',
            'cartItemId': cartItemId,
            'quantity': quantity,
            'originalError': e.toString(),
          },
        );
        GlobalErrorHandler.showErrorSnackBar(
          context,
          paymentError,
          onRetry: () => _updateQuantity(cartItemId, quantity),
        );
      }
    }
  }

  void _removeItem(String cartItemId) async {
    try {
      await ref.read(cartProvider.notifier).removeCartItem(cartItemId);
      if (mounted) {
        ErrorSnackBar.showSuccess(
          context,
          '상품이 장바구니에서 제거되었습니다.',
        );
      }
    } catch (e) {
      if (mounted) {
        // 🚨 글로벌 에러 핸들러 사용
        final paymentError = PaymentError(
          code: 'CART_REMOVE_FAILED',
          message: '상품을 제거하는데 실패했습니다.',
          context: {
            'operation': 'removeItem',
            'cartItemId': cartItemId,
            'originalError': e.toString(),
          },
        );
        GlobalErrorHandler.showErrorSnackBar(
          context,
          paymentError,
          onRetry: () => _removeItem(cartItemId),
        );
      }
    }
  }

  void _toggleSelect(String cartItemId) {
    ref.read(cartProvider.notifier).toggleItemSelection(cartItemId);
  }

  void _toggleSelectAllForCurrentTab(bool value) {
    final currentTabIndex = _tabController.index;
    final deliveryType = currentTabIndex == 0 ? '택배' : '픽업';

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
    return _tabController.index == 0 ? '택배' : '픽업';
  }

  // Get current tab display name
  String _getCurrentTabDisplayName() {
    return _tabController.index == 0 ? '택배' : '픽업';
  }

  /// 재고 확인 및 부족한 상품 표시
  Future<bool> _verifyStockAndUpdateUI(List<dynamic> selectedItems) async {
    try {
      bool hasInsufficientStock = false;
      final updatedItems = <CartItemModel>[];

      for (final item in selectedItems) {
        final cartItem = item as CartItemModel;
        
        // 상품 정보 조회하여 현재 재고 확인
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(cartItem.productId)
            .get();
            
        if (!productDoc.exists) {
          // 상품이 존재하지 않으면 재고 부족으로 처리
          updatedItems.add(cartItem.copyWith(hasInsufficientStock: true));
          hasInsufficientStock = true;
          continue;
        }
        
        final productData = productDoc.data() as Map<String, dynamic>;
        final orderUnits = productData['orderUnits'] as List<dynamic>? ?? [];
        
        // 해당 OrderUnit 찾기
        bool unitFound = false;
        bool stockSufficient = true;
        
        for (final unitData in orderUnits) {
          final unitMap = unitData as Map<String, dynamic>;
          if (unitMap['unit'] == cartItem.productOrderUnit && 
              unitMap['price'] == cartItem.productPrice) {
            unitFound = true;
            final currentStock = unitMap['stock'] as int? ?? 0;
            
            if (currentStock < cartItem.quantity) {
              stockSufficient = false;
              hasInsufficientStock = true;
            }
            break;
          }
        }
        
        // OrderUnit을 찾지 못했거나 재고가 부족한 경우
        final hasInsufficientStockFlag = !unitFound || !stockSufficient;
        updatedItems.add(cartItem.copyWith(hasInsufficientStock: hasInsufficientStockFlag));
        
        if (hasInsufficientStockFlag) {
          hasInsufficientStock = true;
        }
      }
      
      // 재고 상태가 변경된 아이템들 업데이트
      for (final updatedItem in updatedItems) {
        if (updatedItem.hasInsufficientStock != 
            selectedItems.firstWhere((item) => item.id == updatedItem.id).hasInsufficientStock) {
          ref.read(cartProvider.notifier).updateItemStockStatus(
            updatedItem.id, 
            updatedItem.hasInsufficientStock
          );
        }
      }
      
      return hasInsufficientStock;
    } catch (e) {
      debugPrint('❌ 재고 확인 중 오류 발생: $e');
      return true; // 오류 발생 시 안전하게 재고 부족으로 처리
    }
  }

  /// 재고 부족 모달 표시
  Future<void> _showInsufficientStockModal() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('재고 부족'),
        content: const Text('주문 수량 대비 재고가 부족한 상품이 있습니다.\n수량을 조정해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 🆕 환불 정책 다이얼로그 표시
  void _showRefundPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '<와치맨 공동구매 반품/교환/환불 정책>',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '''1. 기본 원칙
당사는 『전자상거래 등에서의 소비자보호에 관한 법률』에 따라, 소비자의 권리를 보호하며 다음과 같은 기준으로 반품, 교환, 환불을 처리합니다.

2. 반품 및 교환 가능 기간
- 신선식품(농수축산물)의 경우 수령일로부터 2일 이내, 영업시간 내에 접수된 경우만 가능
- 가공식품 등 기타 상품의 경우 수령일로부터 7일 이내, 영업시간 내에 접수된 경우만 가능
- 수령일이 불분명한 경우, 배송완료를 공지한 날(픽업/직접배송) 또는 배송완료로 표시된 날(택배발송) 기준으로 산정

3. 반품 및 교환이 가능한 경우
- 상품에 하자가 있는 경우 (파손, 부패, 오배송 등)
- 제품이 소비자의 과실 없이 변질·손상된 경우
- 판매자의 귀책사유로 인해 제품에 하자가 발생한 경우
- 표시·광고 내용과 다르거나, 계약 내용과 다르게 이행된 경우
- 동일 상품으로의 교환 요청이 어려울 경우, 환불로 처리
- 농수산물의 경우, 당일 수령 후 2일 이내 상태 이상 발견 시 사진과 함께 영업시간 내 고객센터로 연락

4. 반품 및 교환이 불가능한 경우
- 소비자 귀책 사유로 상품이 멸실·훼손된 경우
- 소비자의 사용 또는 일부 소비로 상품의 가치가 현저히 감소한 경우
- 신선식품(농산물 등) 특성상 단순 변심, 외관 또는 맛과 같은 주관적인 요소가 반영될 수 있는 사유로 인한 반품은 불가
- 공동구매 특성상 수령 장소 및 시간에 맞춰 수령하지 않아 발생한 품질 저하 또는 유통문제

5. 환불 처리
- 환불은 카드결제 취소 또는 계좌환불 방식으로 진행됩니다.
- PG사 결제 취소 기준에 따라 영업일 기준 3~7일 이내 처리됩니다.
- 카드결제의 경우, 승인 취소는 카드사 정책에 따라 시일이 소요될 수 있습니다.
- 현금결제(무통장 입금) 환불 시, 정확한 계좌 정보를 고객이 제공해야 하며, 제공된 계좌 정보 오류로 인한 불이익은 책임지지 않습니다.

6. 고객 문의처
- 어플 내 [고객문의] 메뉴
- 각 오픈채팅방 내 CS담당자
- 카카오톡 '와치맨컴퍼니'
- 고객센터 010-6486-2591
- 운영시간: 오전 10시 ~ 오후 6시
- 문의 접수 후 영업일 기준 1~2일 내 회신 드립니다.

7. 기타
본 정책은 소비자 보호와 서비스 신뢰 유지를 위한 기준이며, 공동구매 특성상 일부 사항은 사전 고지 없이 변경될 수 있습니다. 변경 시, 어플 공지사항 및 약관 페이지를 통해 고지합니다.''',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
      ),
    );
  }

  Future<void> _proceedToCheckout() async {
    debugPrint('🛒 _proceedToCheckout 시작');
    final cartState = ref.read(cartProvider);
    final allCartItems = cartState.cartItems;

    // Separate items by delivery type
    final deliveryItems =
        allCartItems.where((item) => item.productDeliveryType == '택배').toList();
    final pickupItems =
        allCartItems.where((item) => item.productDeliveryType == '픽업').toList();

    // Get selected items for current tab only
    final selectedItems =
        _getCurrentTabSelectedItems(deliveryItems, pickupItems);
    final deliveryType = _getCurrentTabDeliveryType();
    final displayName = _getCurrentTabDisplayName();

    debugPrint('🛒 선택된 상품: ${selectedItems.length}개, 배송타입: $deliveryType');

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$displayName 상품을 선택해주세요.'),
          backgroundColor: ColorPalette.warning,
        ),
      );
      return;
    }

    // 재고 확인 수행
    debugPrint('🛒 재고 확인 시작');
    final hasInsufficientStock = await _verifyStockAndUpdateUI(selectedItems);
    
    if (hasInsufficientStock) {
      // 재고 부족한 상품이 있으면 모달 표시하고 checkout 중단
      await _showInsufficientStockModal();
      return;
    }

    debugPrint('🛒 CheckoutScreen으로 이동 시작');
    // Navigate to checkout screen with selected items and delivery type
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          items: selectedItems.cast<CartItemModel>(),
          deliveryType: deliveryType,
        ),
      ),
    ).then((result) {
      // 주문서에서 돌아온 경우 처리
      if (result == 'order_completed') {
        // 주문 완료된 경우 장바구니 새로고침
        _loadCartItems();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('주문이 완료되었습니다!'),
            backgroundColor: ColorPalette.success,
          ),
        );
      } else if (result == 'payment_cancelled') {
        // 결제 취소된 경우 알림
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제가 취소되어 장바구니로 돌아왔습니다.'),
            backgroundColor: ColorPalette.warning,
          ),
        );
      }
    });
  }

  /// 선택된 항목 삭제 확인 다이얼로그
  Future<void> _showRemoveSelectedDialog() async {
    final cartState = ref.read(cartProvider);
    final allCartItems = cartState.cartItems;

    // Separate items by delivery type
    final deliveryItems =
        allCartItems.where((item) => item.productDeliveryType == '택배').toList();
    final pickupItems =
        allCartItems.where((item) => item.productDeliveryType == '픽업').toList();

    // Get selected items for current tab only
    final selectedItems =
        _getCurrentTabSelectedItems(deliveryItems, pickupItems);
    final displayName = _getCurrentTabDisplayName();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제할 $displayName 상품을 선택해주세요.'),
          backgroundColor: ColorPalette.warning,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택 항목 삭제'),
        content: Text(
          '선택된 $displayName 상품 ${selectedItems.length}개를 장바구니에서 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: ColorPalette.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeSelectedItems();
    }
  }

  /// 선택된 항목들을 삭제 (현재 탭 기준)
  Future<void> _removeSelectedItems() async {
    try {
      // 현재 탭의 배송 타입에 해당하는 선택된 항목들만 삭제
      final cartState = ref.read(cartProvider);
      final currentDeliveryType = _getCurrentTabDeliveryType();

      // 현재 탭의 선택된 항목들만 필터링
      final selectedItems = cartState.cartItems
          .where((item) =>
              item.isSelected &&
              item.productDeliveryType == currentDeliveryType)
          .toList();

      if (selectedItems.isEmpty) {
        return;
      }

      // 선택된 항목들의 ID 리스트
      final selectedItemIds = selectedItems.map((item) => item.id).toList();

      // Provider의 removeSelectedItems 메서드 사용
      await ref.read(cartProvider.notifier).removeSelectedItems();

      if (mounted) {
        ErrorSnackBar.showSuccess(
          context,
          '선택된 ${_getCurrentTabDisplayName()} 상품 ${selectedItems.length}개가 삭제되었습니다.',
        );
      }
    } catch (e) {
      if (mounted) {
        // 🚨 글로벌 에러 핸들러 사용
        final paymentError = PaymentError(
          code: 'CART_REMOVE_SELECTED_FAILED',
          message: '선택된 상품들을 삭제하는데 실패했습니다.',
          context: {
            'operation': 'removeSelectedItems',
            'originalError': e.toString(),
          },
        );
        GlobalErrorHandler.showErrorSnackBar(
          context,
          paymentError,
          onRetry: () => _removeSelectedItems(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final allCartItems = cartState.cartItems ?? []; // null safety 추가
    final isLoading = cartState.isLoading;
    final status = cartState.status;
    final errorMessage = cartState.errorMessage;

    // Separate items by delivery type with null safety
    final deliveryItems =
        allCartItems.where((item) => item.productDeliveryType == '택배').toList();
    final pickupItems =
        allCartItems.where((item) => item.productDeliveryType == '픽업').toList();

    debugPrint('🛒 택배 아이템: ${deliveryItems.length}개');
    debugPrint('🛒 픽업 아이템: ${pickupItems.length}개');

    // Get selected items for current tab
    final currentTabSelectedItems =
        _getCurrentTabSelectedItems(deliveryItems, pickupItems);
    final currentTabDisplayName = _getCurrentTabDisplayName();

    debugPrint('🛒 현재 탭: $currentTabDisplayName');
    debugPrint('🛒 현재 탭 선택된 아이템: ${currentTabSelectedItems.length}개');

    // Calculate total price for current tab selected items with null safety
    final currentTabTotalPrice = currentTabSelectedItems.fold<double>(
      0.0,
      (prev, item) =>
          prev + ((item.productPrice ?? 0.0) * (item.quantity ?? 1)),
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
          actions: currentTabSelectedItems.isNotEmpty
              ? [
                  IconButton(
                    onPressed: isLoading ? null : _showRemoveSelectedDialog,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '선택 항목 삭제',
                  ),
                ]
              : null,
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
        body: Column(
          children: [
            // 메인 콘텐츠
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 택배 탭
                  _buildCartTabContent(
                    cartItems: deliveryItems,
                    deliveryType: '택배',
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

                        // Button row (삭제 + 주문하기)
                        Row(
                          children: [
                            // 선택 항목 삭제 버튼
                            Expanded(
                              flex: 1,
                              child: OutlinedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : _showRemoveSelectedDialog,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                label: const Text('삭제'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: Dimensions.paddingMd,
                                  ),
                                  foregroundColor: ColorPalette.error,
                                  side: const BorderSide(
                                    color: ColorPalette.error,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: Dimensions.spacingSm),

                            // 주문하기 버튼
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed:
                                    isLoading ? null : _proceedToCheckout,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: Dimensions.paddingMd,
                                  ),
                                  backgroundColor: ColorPalette.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  '$currentTabDisplayName 주문 (${currentTabSelectedItems.length}개)',
                                  style: TextStyles.buttonLarge,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildCartTabContent({
    required List<CartItemModel> cartItems,
    required String deliveryType,
    required bool isLoading,
    required CartLoadStatus status,
    required String? errorMessage,
    required CartState cartState,
  }) {
    // RefreshIndicator로 감싸서 당겨서 새로고침 기능 추가
    return RefreshIndicator(
      onRefresh: _loadCartItems,
      child: _buildCartTabContentInner(
        cartItems: cartItems,
        deliveryType: deliveryType,
        isLoading: isLoading,
        status: status,
        errorMessage: errorMessage,
        cartState: cartState,
      ),
    );
  }

  Widget _buildCartTabContentInner({
    required List<CartItemModel> cartItems,
    required String deliveryType,
    required bool isLoading,
    required CartLoadStatus status,
    required String? errorMessage,
    required CartState cartState,
  }) {
    // Calculate if all items of this delivery type are selected
    final areAllTabItemsSelected =
        cartItems.isNotEmpty && cartItems.every((item) => item.isSelected);

    return Stack(
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
                          deliveryType == '택배'
                              ? Icons.local_shipping
                              : Icons.store,
                          size: 64,
                          color: ColorPalette.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.spacingLg),
                    Text(
                      '${deliveryType == '택배' ? '택배' : '픽업'} 상품이 없습니다',
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
                          ? '${deliveryType == '택배' ? '택배' : '픽업'} 전체 해제'
                          : '${deliveryType == '택배' ? '택배' : '픽업'} 전체 선택',
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: Dimensions.spacingMd),
                child: GestureDetector(
                  onTap: _showRefundPolicyDialog,
                  child: Text(
                    '와치맨 공동구매 반품/교환/환불 정책 보기',
                    style: TextStyles.bodySmall.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? ColorPalette.textSecondaryDark
                          : ColorPalette.textSecondaryLight,
                      decoration: TextDecoration.underline,
                    ),
                  ),
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
    );
  }
}
