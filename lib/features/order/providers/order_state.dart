import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../models/order_enums.dart';
import '../services/order_service.dart';
import '../../cart/models/cart_item_model.dart';
import '../../auth/providers/auth_state.dart';
import 'order_history_state.dart';

part 'order_state.g.dart';

/// 주문 진행 상태
enum OrderFlowStatus {
  initial,
  creatingOrder,
  orderCreated,
  processing,
  completed,
  error,
}

/// 주문 액션 타입
enum OrderActionType {
  none,
  createOrder,
  processPayment,
  cancelOrder,
  updateStatus,
}

/// 주문 상태 클래스
class OrderState {
  final OrderFlowStatus status;
  final OrderModel? currentOrder;
  final List<OrderModel> userOrders;
  final String? errorMessage;
  final bool isLoading;
  final OrderActionType currentAction;

  const OrderState({
    this.status = OrderFlowStatus.initial,
    this.currentOrder,
    this.userOrders = const [],
    this.errorMessage,
    this.isLoading = false,
    this.currentAction = OrderActionType.none,
  });

  OrderState copyWith({
    OrderFlowStatus? status,
    OrderModel? currentOrder,
    List<OrderModel>? userOrders,
    String? errorMessage,
    bool? isLoading,
    OrderActionType? currentAction,
  }) {
    return OrderState(
      status: status ?? this.status,
      currentOrder: currentOrder ?? this.currentOrder,
      userOrders: userOrders ?? this.userOrders,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      currentAction: currentAction ?? this.currentAction,
    );
  }

  /// 주문 총 금액 (배송비 포함)
  int? get totalAmount => currentOrder?.totalAmount;

  /// 결제 완료 여부
  bool get isPaymentCompleted => currentOrder?.isPaymentCompleted == true;

  /// 주문 취소 가능 여부
  bool get canCancelOrder => currentOrder?.isCancellable == true;
}

/// 주문 상태 관리 Provider
@riverpod
class Order extends _$Order {
  @override
  OrderState build() {
    return const OrderState();
  }

  /// 🛒 장바구니에서 주문 생성
  Future<void> createOrderFromCart({
    required List<CartItemModel> cartItems,
    required String deliveryType,
    DeliveryAddress? deliveryAddress,
    String? orderNote,
  }) async {
    try {
      // 로딩 시작
      state = state.copyWith(
        isLoading: true,
        currentAction: OrderActionType.createOrder,
        status: OrderFlowStatus.creatingOrder,
        errorMessage: null,
      );

      // 현재 로그인된 사용자 확인
      final authState = ref.read(authProvider).value;
      if (authState?.user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final userId = authState!.user!.uid;

      // 장바구니 아이템을 주문 형식으로 변환
      final orderItems = cartItems.map((cartItem) {
        return {
          'id': cartItem.id,
          'productId': cartItem.productId,
          'productName': cartItem.productName,
          'quantity': cartItem.quantity,
          'price': cartItem.productPrice.toInt(),
          'productOrderUnit': cartItem.productOrderUnit,
          'thumbnailUrl': cartItem.thumbnailUrl,
          'deliveryType': cartItem.productDeliveryType,
          'isTaxFree': cartItem.isTaxFree,
        };
      }).toList();

      // 주문 서비스를 통해 주문 생성
      final orderService = ref.read(orderServiceProvider);
      final order = await orderService.createOrderFromCart(
        userId: userId,
        cartItems: orderItems,
        deliveryAddress: deliveryAddress,
        orderNote: orderNote,
      );

      // 주문 생성 완료
      state = state.copyWith(
        currentOrder: order,
        status: OrderFlowStatus.orderCreated,
        isLoading: false,
        currentAction: OrderActionType.none,
      );

      debugPrint('주문 생성 완료: ${order.orderId}');
    } catch (e) {
      // 에러 처리
      state = state.copyWith(
        errorMessage: e.toString(),
        status: OrderFlowStatus.error,
        isLoading: false,
        currentAction: OrderActionType.none,
      );

      debugPrint('주문 생성 실패: $e');
      rethrow;
    }
  }

  /// 💳 결제 처리
  Future<void> processPayment({
    required String paymentKey,
    required int amount,
  }) async {
    try {
      if (state.currentOrder == null) {
        throw Exception('처리할 주문이 없습니다.');
      }

      // 로딩 시작
      state = state.copyWith(
        isLoading: true,
        currentAction: OrderActionType.processPayment,
        status: OrderFlowStatus.processing,
        errorMessage: null,
      );

      final orderService = ref.read(orderServiceProvider);

      // Toss Payments 결제 승인
      final paymentInfo = await orderService.confirmPayment(
        orderId: state.currentOrder!.orderId,
        paymentKey: paymentKey,
        amount: amount,
      );

      // 주문에 결제 정보 업데이트
      // 주문 상태는 Firebase Functions에서 업데이트되므로 클라이언트에서 설정하지 않음
      final updatedOrder = state.currentOrder!.copyWith(
        paymentInfo: paymentInfo,
      );

      // 결제 완료
      state = state.copyWith(
        currentOrder: updatedOrder,
        status: OrderFlowStatus.completed,
        isLoading: false,
        currentAction: OrderActionType.none,
      );

      debugPrint('결제 처리 완료: ${paymentInfo.paymentKey}');
      debugPrint('주문 상태는 Firebase Functions에서 confirmed로 업데이트됩니다.');

      // 🔄 결제 완료 후 주문 목록 새로고침 및 실시간 리스너 설정
      final orderHistoryNotifier = ref.read(orderHistoryProvider.notifier);

      // 실시간 리스너 설정 (Firebase Functions가 status를 업데이트할 때 감지)
      orderHistoryNotifier
          .listenToOrderStatusChanges(state.currentOrder!.orderId);

      // 주문 목록 새로고침 (Firebase Functions 처리 시간 고려)
      orderHistoryNotifier.refreshAfterPayment(
          orderId: state.currentOrder!.orderId);
    } catch (e) {
      // 에러 처리
      state = state.copyWith(
        errorMessage: e.toString(),
        status: OrderFlowStatus.error,
        isLoading: false,
        currentAction: OrderActionType.none,
      );

      debugPrint('결제 처리 실패: $e');
      rethrow;
    }
  }

  /// 📋 사용자 주문 내역 조회
  Future<void> loadUserOrders() async {
    try {
      // 현재 로그인된 사용자 확인
      final authState = ref.read(authProvider).value;
      if (authState?.user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final userId = authState!.user!.uid;
      final orderService = ref.read(orderServiceProvider);

      // 주문 내역 조회
      final orders = await orderService.getUserOrders(userId: userId);

      state = state.copyWith(userOrders: orders);

      debugPrint('주문 내역 조회 완료: ${orders.length}개');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      debugPrint('주문 내역 조회 실패: $e');
    }
  }

  /// ❌ 주문 취소
  Future<void> cancelOrder({
    required String orderId,
    required String cancelReason,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        currentAction: OrderActionType.cancelOrder,
        errorMessage: null,
      );

      final orderService = ref.read(orderServiceProvider);

      await orderService.cancelOrder(
        orderId: orderId,
        cancelReason: cancelReason,
      );

      // 현재 주문이 취소된 주문과 같다면 상태 업데이트
      if (state.currentOrder?.orderId == orderId) {
        final canceledOrder = state.currentOrder!.copyWith(
          status: OrderStatus.cancelled,
          cancelReason: cancelReason,
          canceledAt: DateTime.now(),
        );

        state = state.copyWith(
          currentOrder: canceledOrder,
          isLoading: false,
          currentAction: OrderActionType.none,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          currentAction: OrderActionType.none,
        );
      }

      debugPrint('주문 취소 완료: $orderId');
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
        currentAction: OrderActionType.none,
      );

      debugPrint('주문 취소 실패: $e');
      rethrow;
    }
  }

  /// 🔄 주문 상태 초기화
  void resetOrder() {
    state = const OrderState();
  }

  /// 📊 주문 상태 업데이트
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        currentAction: OrderActionType.updateStatus,
        errorMessage: null,
      );

      final orderService = ref.read(orderServiceProvider);

      await orderService.updateOrderStatus(
        orderId: orderId,
        newStatus: newStatus,
      );

      // 현재 주문 상태 업데이트
      if (state.currentOrder?.orderId == orderId) {
        final updatedOrder = state.currentOrder!.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );

        state = state.copyWith(
          currentOrder: updatedOrder,
          isLoading: false,
          currentAction: OrderActionType.none,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          currentAction: OrderActionType.none,
        );
      }

      debugPrint('주문 상태 업데이트 완료: $orderId -> ${newStatus.displayName}');
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
        currentAction: OrderActionType.none,
      );

      debugPrint('주문 상태 업데이트 실패: $e');
      rethrow;
    }
  }
}
