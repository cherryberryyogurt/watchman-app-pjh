import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/cart_item_model.dart';
import '../repositories/cart_repository.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_storage_service.dart';
import '../../../core/services/retry_service.dart';
import '../../../core/providers/firebase_providers.dart';
import 'package:flutter/foundation.dart';

// part 'cart_state.g.dart'; // TODO: Generate with build_runner

enum CartLoadStatus {
  initial,
  loading,
  loaded,
  error,
}

enum CartActionType {
  none,
  loadCart,
  addToCart,
  updateQuantity,
  removeItem,
  clearCart,
  toggleSelect,
  selectAll,
  unselectAll,
}

enum CartFilterType {
  all,
  pickup,
  delivery,
}

class CartState {
  final CartLoadStatus status;
  final List<CartItemModel> cartItems;
  final String? errorMessage;
  final bool isLoading;
  final CartActionType currentAction;
  final CartFilterType filterType;

  const CartState({
    this.status = CartLoadStatus.initial,
    this.cartItems = const [],
    this.errorMessage,
    this.isLoading = false,
    this.currentAction = CartActionType.none,
    this.filterType = CartFilterType.all,
  });

  CartState copyWith({
    CartLoadStatus? status,
    List<CartItemModel>? cartItems,
    String? errorMessage,
    bool? isLoading,
    CartActionType? currentAction,
    CartFilterType? filterType,
  }) {
    return CartState(
      status: status ?? this.status,
      cartItems: cartItems ?? this.cartItems,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      currentAction: currentAction ?? this.currentAction,
      filterType: filterType ?? this.filterType,
    );
  }

  // Filtered cart items based on delivery type
  List<CartItemModel> get filteredCartItems {
    if (filterType == CartFilterType.all) {
      return cartItems;
    } else if (filterType == CartFilterType.pickup) {
      return cartItems
          .where((item) => item.productDeliveryType == '픽업')
          .toList();
    } else {
      return cartItems
          .where((item) => item.productDeliveryType == '배송')
          .toList();
    }
  }

  // Selected cart items
  List<CartItemModel> get selectedItems {
    return filteredCartItems.where((item) => item.isSelected).toList();
  }

  // Total price of selected items
  double get totalSelectedPrice {
    return selectedItems.fold(0, (prev, item) => prev + item.priceSum);
  }

  // Check if all filtered items are selected
  bool get areAllItemsSelected {
    return filteredCartItems.isNotEmpty &&
        filteredCartItems.every((item) => item.isSelected);
  }

  // Check if mixed delivery types are selected
  bool get hasMixedDeliveryTypesSelected {
    final selectedTypes =
        selectedItems.map((item) => item.productDeliveryType).toSet();

    return selectedTypes.length > 1;
  }
}

// TODO: Riverpod 생성 코드는 build_runner로 생성 필요
// CartRepository provider는 cart_repository.dart에서 정의됨

// CartNotifier class - 임시로 StateNotifier로 구현
class CartNotifier extends StateNotifier<CartState> {
  late final CartRepository _cartRepository;
  final Ref _ref;

  CartNotifier(this._ref) : super(const CartState()) {
    // TODO: 생성 파일이 없으므로 임시로 직접 생성
    _cartRepository = CartRepository(
      firestore: _ref.watch(firestoreProvider),
      auth: _ref.watch(firebaseAuthProvider),
      ref: _ref,
    );
  }

  // Load cart items
  Future<void> loadCartItems() async {
    try {
      debugPrint('🛒 CartNotifier: loadCartItems() 시작');

      state = state.copyWith(
        status: CartLoadStatus.loading,
        isLoading: true,
        errorMessage: null,
        currentAction: CartActionType.loadCart,
      );

      debugPrint('🛒 CartNotifier: 상태를 loading으로 변경');

      // 네트워크 연결 확인
      final isConnected = await ConnectivityService.isConnected;
      debugPrint('🛒 CartNotifier: 네트워크 연결 상태: $isConnected');

      List<CartItemModel> cartItems;

      if (isConnected) {
        try {
          cartItems = await _cartRepository.getCartItems();
          debugPrint('🛒 CartNotifier: 온라인에서 ${cartItems.length}개 아이템 로드 성공');

          // 오프라인 저장소에 백업
          await OfflineStorageService.saveCartData(cartItems);
        } catch (e) {
          debugPrint('🛒 CartNotifier: 온라인 로드 실패, 오프라인 데이터 사용: $e');
          // Check if it's the specific authentication error
          if (e is Exception && e.toString().contains('사용자가 로그인되어 있지 않습니다')) {
            cartItems = await _cartRepository.getCartItems(); // Second attempt
            await OfflineStorageService.saveCartData(cartItems);
          } else {
            // 오프라인 데이터 사용
            cartItems = await OfflineStorageService.loadCartData();
          }
        }
      } else {
        // 오프라인 상태에서 저장된 데이터 사용
        cartItems = await OfflineStorageService.loadCartData();
      }

      debugPrint('🛒 CartNotifier: 최종 로드된 아이템 수: ${cartItems.length}');
      for (int i = 0; i < cartItems.length && i < 3; i++) {
        debugPrint(
            '🛒 아이템 $i: ${cartItems[i].productName} (수량: ${cartItems[i].quantity})');
      }


      state = state.copyWith(
        status: CartLoadStatus.loaded,
        cartItems: cartItems,
        isLoading: false,
        currentAction: CartActionType.none,
        errorMessage: null,
      );
      
      debugPrint('🛒 CartNotifier: 상태를 loaded로 변경, UI 업데이트 완료');
    } catch (e) {
      debugPrint('🛒 CartNotifier: 장바구니 로드 최종 실패: $e');
      
      state = state.copyWith(
        status: CartLoadStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
        currentAction: CartActionType.none,
      );
    }
  }

  // Add item to cart
  Future<void> addToCart(
      String productId,
      String productName,
      double productPrice,
      String productOrderUnit,
      String? thumbnailUrl,
      String productDeliveryType,
      String? locationTagId, // 🔄 픽업 정보 개선
      String? pickupInfoId, // 🔄 픽업 정보 개선
      DateTime? productStartDate,
      DateTime? productEndDate,
      int quantity) async {
    // This method is not directly used since we add to cart from product detail
    // It's implemented for completeness
  }

  // Update item quantity
  Future<void> updateCartItemQuantity(String cartItemId, int quantity) async {
    try {
      if (quantity <= 0) {
        throw Exception('수량은 1 이상이어야 합니다.');
      }

      state = state.copyWith(
        isLoading: true,
        currentAction: CartActionType.updateQuantity,
      );

      await _cartRepository.updateCartItemQuantity(cartItemId, quantity);

      // Update the item in the state
      final updatedItems = state.cartItems.map((item) {
        if (item.id == cartItemId) {
          return item.copyWith(
            quantity: quantity,
          );
        }
        return item;
      }).toList();

      state = state.copyWith(
        cartItems: updatedItems,
        isLoading: false,
        currentAction: CartActionType.none,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
        currentAction: CartActionType.none,
      );
    }
  }

  // Remove item from cart
  Future<void> removeCartItem(String cartItemId) async {
    try {
      state = state.copyWith(
        isLoading: true,
        currentAction: CartActionType.removeItem,
      );

      await _cartRepository.removeCartItem(cartItemId);

      // Remove the item from the state
      final updatedItems =
          state.cartItems.where((item) => item.id != cartItemId).toList();

      state = state.copyWith(
        cartItems: updatedItems,
        isLoading: false,
        currentAction: CartActionType.none,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
        currentAction: CartActionType.none,
      );
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      state = state.copyWith(
        isLoading: true,
        currentAction: CartActionType.clearCart,
      );

      await _cartRepository.clearCart();

      state = state.copyWith(
        cartItems: [],
        isLoading: false,
        currentAction: CartActionType.none,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
        currentAction: CartActionType.none,
      );
    }
  }

  // Remove selected items
  Future<void> removeSelectedItems() async {
    try {
      final selectedItems =
          state.cartItems.where((item) => item.isSelected).toList();

      if (selectedItems.isEmpty) {
        return; // 선택된 항목이 없으면 아무것도 하지 않음
      }

      state = state.copyWith(
        isLoading: true,
        currentAction: CartActionType.removeItem,
      );

      final selectedItemIds = selectedItems.map((item) => item.id).toList();
      await _cartRepository.removeSelectedItems(selectedItemIds);

      // 선택된 항목들을 상태에서 제거
      final updatedItems = state.cartItems
          .where((item) => !selectedItemIds.contains(item.id))
          .toList();

      state = state.copyWith(
        cartItems: updatedItems,
        isLoading: false,
        currentAction: CartActionType.none,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
        currentAction: CartActionType.none,
      );
    }
  }

  // Remove ordered items (for post-payment cleanup)
  Future<void> removeOrderedItems(List<String> productIds) async {
    try {
      if (productIds.isEmpty) {
        debugPrint('🛒 제거할 주문 상품이 없습니다.');
        return;
      }

      state = state.copyWith(
        isLoading: true,
        currentAction: CartActionType.removeItem,
      );

      // 네트워크 연결 확인
      final isConnected = await ConnectivityService.isConnected;

      if (isConnected) {
        try {
          // 온라인: 서버에서 제거 (재시도 포함)
          await RetryService.withRetry(
            () => _cartRepository.removeOrderedItems(productIds),
            maxRetries: 3,
          );
          debugPrint('🛒 온라인: 주문한 상품들을 서버에서 제거 완료');
        } catch (e) {
          debugPrint('⚠️ 온라인 제거 실패, 오프라인 처리: $e');
        }
      }

      // 오프라인 저장소에서도 제거 (온라인 실패 시에도 실행)
      await OfflineStorageService.removeOrderedItemsFromCart(productIds);

      // 상태에서 해당 상품들 제거
      final updatedItems = state.cartItems
          .where((item) => !productIds.contains(item.productId))
          .toList();

      state = state.copyWith(
        cartItems: updatedItems,
        isLoading: false,
        currentAction: CartActionType.none,
      );

      debugPrint('🛒 주문한 상품 ${productIds.length}개를 장바구니에서 제거 완료');
    } catch (e) {
      debugPrint('❌ 주문한 상품 제거 실패: $e');
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
        currentAction: CartActionType.none,
      );
      // 오류가 발생해도 rethrow하지 않음 (결제 완료는 성공했으므로)
    }
  }

  // Toggle item selection
  void toggleItemSelection(String cartItemId) {
    final updatedItems = state.cartItems.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(isSelected: !item.isSelected);
      }
      return item;
    }).toList();

    state = state.copyWith(
      cartItems: updatedItems,
      currentAction: CartActionType.toggleSelect,
    );
  }

  // Select all items
  void selectAllItems() {
    final currentFilteredIds =
        state.filteredCartItems.map((item) => item.id).toSet();
    final updatedItems = state.cartItems.map((item) {
      if (currentFilteredIds.contains(item.id)) {
        return item.copyWith(isSelected: true);
      }
      return item;
    }).toList();

    state = state.copyWith(
      cartItems: updatedItems,
      currentAction: CartActionType.selectAll,
    );
  }

  // Unselect all items
  void unselectAllItems() {
    final currentFilteredIds =
        state.filteredCartItems.map((item) => item.id).toSet();
    final updatedItems = state.cartItems.map((item) {
      if (currentFilteredIds.contains(item.id)) {
        return item.copyWith(isSelected: false);
      }
      return item;
    }).toList();

    state = state.copyWith(
      cartItems: updatedItems,
      currentAction: CartActionType.unselectAll,
    );
  }

  // Set filter type
  void setFilterType(CartFilterType filterType) {
    state = state.copyWith(
      filterType: filterType,
    );
  }

  // Select all items by delivery type
  void selectAllItemsByDeliveryType(String deliveryType) {
    final updatedItems = state.cartItems.map((item) {
      if (item.productDeliveryType == deliveryType) {
        return item.copyWith(isSelected: true);
      }
      return item;
    }).toList();

    state = state.copyWith(
      cartItems: updatedItems,
      currentAction: CartActionType.selectAll,
    );
  }

  // Unselect all items by delivery type
  void unselectAllItemsByDeliveryType(String deliveryType) {
    final updatedItems = state.cartItems.map((item) {
      if (item.productDeliveryType == deliveryType) {
        return item.copyWith(isSelected: false);
      }
      return item;
    }).toList();

    state = state.copyWith(
      cartItems: updatedItems,
      currentAction: CartActionType.unselectAll,
    );
  }
}

// Provider for CartNotifier
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});
