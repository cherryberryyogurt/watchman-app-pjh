import 'package:flutter_riverpod/flutter_riverpod.dart'; // Notifier 사용 위해 추가
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gonggoo_app/features/cart/models/cart_item_model.dart';
import 'package:gonggoo_app/features/cart/repositories/cart_repository.dart';
import 'package:gonggoo_app/features/cart/exceptions/cart_exceptions.dart';
import 'package:gonggoo_app/features/auth/providers/auth_providers.dart'; // AuthProviders 사용

part 'cart_state_provider.g.dart';

/// 장바구니의 상태를 나타내는 클래스입니다.
/// 로딩 상태, 장바구니 아이템 목록, 오류 메시지를 포함합니다.
class CartState {
  final bool isLoading;
  final List<CartItemModel> items;
  final String? errorMessage;
  final bool isGuestCart; // 게스트 장바구니 여부 (로그인 안했을 때)

  const CartState({
    this.isLoading = false,
    this.items = const [],
    this.errorMessage,
    this.isGuestCart = true, // 기본적으로 게스트 장바구니로 시작
  });

  CartState copyWith({
    bool? isLoading,
    List<CartItemModel>? items,
    String? errorMessage,
    bool? clearError, // errorMessage를 null로 설정할지 여부
    bool? isGuestCart,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: clearError == true ? null : errorMessage ?? this.errorMessage,
      isGuestCart: isGuestCart ?? this.isGuestCart,
    );
  }
}

/// CartNotifier는 장바구니 관련 비즈니스 로직과 상태 관리를 담당합니다.
@riverpod
class CartNotifier extends _$CartNotifier {
  late CartRepository _cartRepository;

  @override
  CartState build() {
    _cartRepository = ref.watch(cartRepositoryProvider);
    
    // authStateChanges를 직접 감시하여 인증 상태 변경에 반응
    ref.watch(authStateChangesProvider).whenData((_) {
      // 인증 상태가 변경될 때마다 CartState 새로고침
      _loadCartOnAuthChange();
    });
    
    // 초기 상태. 실제 로드는 loadCartItems를 통해 명시적으로 호출하거나,
    // 인증 상태 변경을 감지하여 자동으로 로드할 수 있습니다.
    _loadInitialCart(); // 초기 로드 호출
    return const CartState(isGuestCart: true, items: []);
  }

  Future<void> _loadInitialCart() async {
    try {
      // 향상된 안전한 UID 프로바이더 사용
      final uid = await ref.read(safeCurrentUserUidProvider.future);
      if (uid != null) {
        await loadCartItems();
      } else {
        // 로그인하지 않은 경우, 상태를 게스트 장바구니로 명확히 설정
        state = const CartState(items: [], isLoading: false, isGuestCart: true);
      }
    } catch (e) {
      // 오류 발생 시 게스트 모드로 처리
      state = CartState(items: [], isLoading: false, isGuestCart: true, errorMessage: '로그인 상태 확인 중 오류가 발생했습니다.');
    }
  }
  
  // 인증 상태 변경 시 장바구니 업데이트
  Future<void> _loadCartOnAuthChange() async {
    try {
      final isEmailVerified = ref.read(isCurrentUserEmailVerifiedProvider);
      final uid = await ref.read(safeCurrentUserUidProvider.future);
      
      if (uid != null && isEmailVerified) {
        // 로그인 상태이고 이메일 인증이 완료된 경우에만 장바구니 로드
        await loadCartItems();
      } else if (uid != null && !isEmailVerified) {
        // 로그인했지만 이메일 인증이 안된 경우 - 빈 장바구니 + 인증 필요 메시지
        state = CartState(
          items: [],
          isLoading: false,
          isGuestCart: false,
          errorMessage: '이메일 인증이 필요합니다. 인증 후 장바구니를 이용해주세요.',
        );
      } else {
        // 로그인하지 않은 경우 - 게스트 장바구니
        state = const CartState(items: [], isLoading: false, isGuestCart: true);
      }
    } catch (e) {
      // 오류 발생 시 에러 메시지와 함께 빈 장바구니 표시
      state = CartState(
        items: [],
        isLoading: false,
        isGuestCart: true,
        errorMessage: '장바구니 로드 중 오류가 발생했습니다.',
      );
    }
  }

  /// 장바구니 아이템 목록을 불러옵니다.
  Future<void> loadCartItems() async {
    // 안전한 UID 확인으로 로그인 상태 체크
    final uid = await ref.read(safeCurrentUserUidProvider.future);
    final isGuest = uid == null;
    
    state = state.copyWith(isLoading: true, clearError: true, isGuestCart: isGuest);
    
    try {
      // 이메일 인증 여부 확인
      final isEmailVerified = ref.read(isCurrentUserEmailVerifiedProvider);
      
      // 로그인했지만 이메일 인증되지 않은 경우
      if (!isGuest && !isEmailVerified) {
        state = state.copyWith(
          isLoading: false, 
          items: [], 
          errorMessage: '이메일 인증이 필요합니다. 인증 후 장바구니를 이용해주세요.',
          isGuestCart: false
        );
        return;
      }
      
      final items = await _cartRepository.getCartItems();
      state = state.copyWith(isLoading: false, items: items, isGuestCart: isGuest);
    } on FirestoreOperationException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message, isGuestCart: isGuest);
    } on UserNotLoggedInException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message, isGuestCart: true);
    } on EmailNotVerifiedException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message, isGuestCart: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '알 수 없는 오류로 장바구니를 불러오지 못했습니다.', isGuestCart: isGuest);
    }
  }

  /// 장바구니에 아이템을 추가합니다.
  Future<void> addItemToCart(CartItemModel item) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _cartRepository.addItemToCart(item);
      // 성공 후 장바구니 목록을 다시 로드하여 UI를 최신 상태로 업데이트합니다.
      await loadCartItems(); 
    } on UserNotLoggedInException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      // TODO: 로그인 화면으로 안내하는 로직 또는 UI 피드백 추가
    } on EmailNotVerifiedException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      // TODO: 이메일 인증 화면으로 안내 또는 인증 메일 재발송 UI 피드백 추가
    } on FirestoreOperationException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '알 수 없는 오류로 아이템을 추가하지 못했습니다.');
    }
  }

  /// 장바구니 아이템의 수량을 업데이트합니다.
  Future<void> updateItemQuantity(String cartItemId, int newQuantity) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _cartRepository.updateCartItemQuantity(cartItemId, newQuantity);
      await loadCartItems(); // 변경 후 목록 새로고침
    } on UserNotLoggedInException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } on FirestoreOperationException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '알 수 없는 오류로 수량을 변경하지 못했습니다.');
    }
  }

  /// 장바구니에서 아이템을 삭제합니다.
  Future<void> removeItemFromCart(String cartItemId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _cartRepository.removeCartItem(cartItemId);
      await loadCartItems(); // 변경 후 목록 새로고침
    } on UserNotLoggedInException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } on FirestoreOperationException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '알 수 없는 오류로 아이템을 삭제하지 못했습니다.');
    }
  }

  /// 장바구니 전체를 비웁니다.
  Future<void> clearUserCart() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _cartRepository.clearCart();
      state = state.copyWith(isLoading: false, items: [], isGuestCart: ref.read(currentUserUidProvider) == null); // 비우고 게스트 상태 반영
    } on UserNotLoggedInException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message, items: []); // 실패해도 로컬은 비움 (선택적)
    } on FirestoreOperationException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '알 수 없는 오류로 장바구니를 비우지 못했습니다.');
    }
  }

  /// 오류 메시지를 초기화합니다.
  void clearErrorMessage() {
    state = state.copyWith(clearError: true);
  }
} 