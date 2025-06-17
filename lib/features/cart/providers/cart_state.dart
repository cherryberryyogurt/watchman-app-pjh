// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/cart_item_model.dart';
import '../repositories/cart_repository.dart';

part 'cart_state.g.dart';

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

// CartRepository provider
@riverpod
CartRepository cartRepository(CartRepositoryRef ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return CartRepository(firestore, ref);
}

// CartNotifier class
@riverpod
class Cart extends _$Cart {
  late final CartRepository _cartRepository;

  @override
  CartState build() {
    _cartRepository = ref.watch(cartRepositoryProvider);
    return const CartState();
  }

  // Load cart items
  Future<void> loadCartItems() async {
    try {
      state = state.copyWith(
        status: CartLoadStatus.loading,
        isLoading: true,
        errorMessage: null,
        currentAction: CartActionType.loadCart,
      );

      List<CartItemModel> cartItems;
      try {
        print("CartNotifier: Attempting to load cart items (1st attempt).");
        cartItems = await _cartRepository.getCartItems();
      } catch (e) {
        // Check if it's the specific authentication error
        if (e is Exception && e.toString().contains('사용자가 로그인되어 있지 않습니다')) {
          print(
              "CartNotifier: First attempt failed due to auth error. Waiting and retrying...");
          // Wait a bit longer for auth state to potentially resolve after the robust check in repository
          await Future.delayed(const Duration(milliseconds: 1000));
          print("CartNotifier: Retrying to load cart items (2nd attempt).");
          cartItems = await _cartRepository.getCartItems(); // Second attempt
        } else {
          rethrow; // Other error, rethrow immediately
        }
      }

      print("CartNotifier: Cart items loaded successfully.");
      state = state.copyWith(
        status: CartLoadStatus.loaded,
        cartItems: cartItems,
        isLoading: false,
        currentAction: CartActionType.none,
      );
    } catch (e) {
      print(
          "CartNotifier: Error loading cart items after retries (if any): $e");
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
