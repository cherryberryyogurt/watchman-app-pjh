/// Order 서비스
///
/// 주문 시스템의 핵심 비즈니스 로직을 담당합니다.
/// 주문 생성, 결제 처리, 상태 관리 등을 포함합니다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../models/order_enums.dart';
import '../repositories/order_repository.dart';
import '../models/payment_info_model.dart';
import 'payments_service.dart';
import 'webhook_service.dart';
import '../../products/repositories/product_repository.dart';
import '../../../core/providers/repository_providers.dart';

/// Order 서비스 Provider
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(
    orderRepository: ref.watch(orderRepositoryProvider),
    tossPaymentsService: ref.watch(tossPaymentsServiceProvider),
    webhookService: ref.watch(webhookServiceProvider),
    productRepository: ref.watch(productRepositoryProvider),
  );
});

/// 주문 관리 서비스
class OrderService {
  final OrderRepository _orderRepository;
  final TossPaymentsService _tossPaymentsService;
  final OrderWebhookService _webhookService;
  final ProductRepository _productRepository;

  OrderService({
    required OrderRepository orderRepository,
    required TossPaymentsService tossPaymentsService,
    required OrderWebhookService webhookService,
    required ProductRepository productRepository,
  })  : _orderRepository = orderRepository,
        _tossPaymentsService = tossPaymentsService,
        _webhookService = webhookService,
        _productRepository = productRepository;

  /// 🛒 장바구니에서 주문 생성
  ///
  /// 여러 상품을 한 번에 주문하고, 재고 확인 및 차감을 수행합니다.
  Future<OrderModel> createOrderFromCart({
    required String userId,
    required List<Map<String, dynamic>> cartItems, // {productId, quantity}
    DeliveryAddress? deliveryAddress,
    String? orderNote,
  }) async {
    debugPrint('🛒 주문 생성 시작: userId=$userId, items=${cartItems.length}개');

    try {
      // 1️⃣ 입력값 검증
      debugPrint('🔍 입력값 검증 시작');
      _validateOrderRequest(
        userId: userId,
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
      );
      debugPrint('✅ 입력값 검증 완료');

      // 2️⃣ 주문 생성 (트랜잭션으로 재고 처리 포함)
      debugPrint('📦 주문 생성 및 재고 처리 시작');
      final order = await _orderRepository.createOrder(
        userId: userId,
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
        orderNote: orderNote,
      );

      debugPrint('✅ 주문 생성 완료: ${order.orderId}');
      return order;
    } catch (e, stackTrace) {
      debugPrint('❌ 주문 생성 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');

      // 웹 환경에서 타임아웃 관련 오류 특별 처리
      if (kIsWeb && e.toString().contains('TimeoutException')) {
        debugPrint('🌐 웹 환경 타임아웃 감지, 재시도 가능한 오류로 처리');
        throw OrderServiceException(
          code: 'WEB_TIMEOUT_ERROR',
          message: '웹 환경에서 네트워크 타임아웃이 발생했습니다. 잠시 후 다시 시도해주세요.',
        );
      }

      // JavaScript 타입 변환 오류 처리
      if (kIsWeb && e.toString().contains('JavaScriptObject')) {
        debugPrint('🌐 웹 환경 JavaScript 타입 오류 감지');
        throw OrderServiceException(
          code: 'WEB_JS_ERROR',
          message: '웹 환경에서 데이터 처리 중 오류가 발생했습니다. 페이지를 새로고침 후 다시 시도해주세요.',
        );
      }

      throw OrderServiceException(
        code: 'ORDER_CREATION_FAILED',
        message: '주문 생성에 실패했습니다: $e',
      );
    }
  }

  /// 💳 Toss Payments로 결제 승인
  ///
  /// 클라이언트에서 받은 결제 정보로 결제를 승인합니다.
  /// 토스페이먼츠 가이드에 따라 서버에서 실제 주문 내역을 기반으로 금액을 재계산하여 검증합니다.
  Future<PaymentInfo> confirmPayment({
    required String orderId,
    required String paymentKey,
    required int amount,
  }) async {
    try {
      // 1️⃣ 주문 존재 확인
      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        throw OrderServiceException(
          code: 'ORDER_NOT_FOUND',
          message: '주문을 찾을 수 없습니다: $orderId',
        );
      }

      // 2️⃣ 서버 측 금액 재계산 및 검증 (토스페이먼츠 가이드 준수)
      final calculatedAmount = await _calculateAndVerifyOrderAmount(order);

      // 기본 금액 검증 (기존 로직)
      if (order.totalAmount != amount) {
        throw OrderServiceException(
          code: 'AMOUNT_MISMATCH',
          message:
              '결제 금액이 일치하지 않습니다. 주문: ${order.totalAmount}원, 결제: ${amount}원',
        );
      }

      // 서버 재계산 금액 검증 (추가 보안)
      if (calculatedAmount != amount) {
        throw OrderServiceException(
          code: 'AMOUNT_VERIFICATION_FAILED',
          message:
              '서버 검증 실패: 계산된 금액(${calculatedAmount}원)과 결제 금액(${amount}원)이 일치하지 않습니다.',
        );
      }

      debugPrint('✅ 결제 금액 검증 완료: $amount원');

      // 3️⃣ Toss Payments로 결제 승인
      final paymentInfo = await _tossPaymentsService.confirmPayment(
        paymentKey: paymentKey,
        orderId: orderId,
        amount: amount,
      );

      // 4️⃣ 결제 정보 저장
      await _orderRepository.updatePaymentInfo(
        orderId: orderId,
        paymentInfo: paymentInfo,
      );

      // 5️⃣ 주문 상태 업데이트 (pending → confirmed)
      await _orderRepository.updateOrderStatus(
        orderId: orderId,
        newStatus: OrderStatus.confirmed,
      );

      debugPrint('결제 승인 완료: $orderId, PaymentKey: $paymentKey');
      return paymentInfo;
    } catch (e) {
      if (e is TossPaymentsException) {
        throw OrderServiceException(
          code: 'PAYMENT_FAILED',
          message: e.userFriendlyMessage,
        );
      }

      throw OrderServiceException(
        code: 'PAYMENT_CONFIRMATION_FAILED',
        message: '결제 승인에 실패했습니다: $e',
      );
    }
  }

  /// 🔒 서버 측 주문 금액 재계산 및 검증
  ///
  /// 토스페이먼츠 가이드에 따라 서버에서 실제 상품 정보를 기반으로 금액을 재계산합니다.
  /// - 상품 가격 변동 확인
  /// - 재고 충분 여부 확인
  /// - 상품 활성화 상태 확인
  /// - 할인/쿠폰 유효성 재검증 (향후 확장)
  Future<int> _calculateAndVerifyOrderAmount(OrderModel order) async {
    try {
      debugPrint('🔒 서버 측 주문 금액 재계산 시작: ${order.orderId}');

      int totalCalculatedAmount = 0;

      // 주문 상품 정보 조회 (서브컬렉션에서)
      final orderedProducts =
          await _orderRepository.getOrderedProducts(order.orderId);

      // 주문 상품별로 현재 상품 정보 확인 및 금액 계산
      for (final orderedProduct in orderedProducts) {
        // 현재 상품 정보 조회
        final currentProduct =
            await _productRepository.getProductById(orderedProduct.productId);

        // 상품 활성화 상태 확인
        if (!currentProduct.isSaleActive) {
          throw OrderServiceException(
            code: 'PRODUCT_NOT_AVAILABLE',
            message: '상품 "${currentProduct.name}"이 현재 판매 중단 상태입니다.',
          );
        }

        // 재고 충분 여부 확인
        if (currentProduct.stock < orderedProduct.quantity) {
          throw OrderServiceException(
            code: 'INSUFFICIENT_STOCK',
            message:
                '상품 "${currentProduct.name}"의 재고가 부족합니다. (현재 재고: ${currentProduct.stock}개, 주문 수량: ${orderedProduct.quantity}개)',
          );
        }

        // 상품 가격 변동 확인
        if (currentProduct.price.toInt() != orderedProduct.unitPrice) {
          debugPrint('⚠️ 상품 가격 변동 감지: ${currentProduct.name}');
          debugPrint('   주문 시 가격: ${orderedProduct.unitPrice}원');
          debugPrint('   현재 가격: ${currentProduct.price.toInt()}원');

          throw OrderServiceException(
            code: 'PRICE_CHANGED',
            message: '상품 "${currentProduct.name}"의 가격이 변경되었습니다. 주문을 다시 진행해주세요.',
          );
        }

        // 개별 상품 금액 계산
        final productTotal = orderedProduct.unitPrice * orderedProduct.quantity;
        totalCalculatedAmount += productTotal;

        debugPrint(
            '✅ 상품 "${currentProduct.name}": ${orderedProduct.unitPrice}원 × ${orderedProduct.quantity}개 = ${productTotal}원');
      }

      // 배송비 추가 (기존 주문의 배송비 사용)
      totalCalculatedAmount += order.totalDeliveryFee;

      // TODO: 향후 할인/쿠폰 검증 로직 추가
      // - 쿠폰 유효기간 확인
      // - 쿠폰 사용 조건 재검증
      // - 중복 사용 방지
      // if (order.discountAmount > 0) {
      //   await _validateDiscountAndCoupons(order);
      //   totalCalculatedAmount -= order.discountAmount;
      // }

      debugPrint('🔒 서버 계산 완료:');
      debugPrint(
          '   상품 금액: ${totalCalculatedAmount - order.totalDeliveryFee}원');
      debugPrint('   배송비: ${order.totalDeliveryFee}원');
      debugPrint('   총 금액: ${totalCalculatedAmount}원');
      debugPrint('   주문 저장 금액: ${order.totalAmount}원');

      return totalCalculatedAmount;
    } catch (e) {
      debugPrint('❌ 서버 측 금액 계산 실패: $e');

      if (e is OrderServiceException) {
        rethrow;
      }

      throw OrderServiceException(
        code: 'AMOUNT_CALCULATION_FAILED',
        message: '서버에서 주문 금액 계산에 실패했습니다: $e',
      );
    }
  }

  /// 📱 간편 주문 (단일 상품)
  ///
  /// 단일 상품을 바로 주문하는 편의 메서드입니다.
  Future<OrderModel> createQuickOrder({
    required String userId,
    required String productId,
    required int quantity,
    DeliveryAddress? deliveryAddress,
    String? orderNote,
  }) async {
    final cartItems = [
      {
        'productId': productId,
        'quantity': quantity,
      }
    ];

    return await createOrderFromCart(
      userId: userId,
      cartItems: cartItems,
      deliveryAddress: deliveryAddress,
      orderNote: orderNote,
    );
  }

  /// ❌ 주문 취소
  ///
  /// 주문을 취소하고 결제 취소 및 재고 복구를 수행합니다.
  Future<void> cancelOrder({
    required String orderId,
    required String cancelReason,
    bool cancelPayment = true,
  }) async {
    try {
      // 1️⃣ 주문 조회
      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        throw OrderServiceException(
          code: 'ORDER_NOT_FOUND',
          message: '주문을 찾을 수 없습니다: $orderId',
        );
      }

      // 2️⃣ 취소 가능한지 확인
      if (!order.isCancellable) {
        throw OrderServiceException(
          code: 'ORDER_NOT_CANCELLABLE',
          message: '취소할 수 없는 주문 상태입니다: ${order.status.displayName}',
        );
      }

      // 3️⃣ 결제 취소 (결제가 완료된 경우)
      if (cancelPayment &&
          order.paymentInfo?.isSuccessful == true &&
          order.paymentInfo?.paymentKey != null) {
        await _tossPaymentsService.cancelPayment(
          paymentKey: order.paymentInfo!.paymentKey!,
          cancelReason: cancelReason,
        );

        debugPrint('결제 취소 완료: ${order.paymentInfo!.paymentKey}');
      }

      // 4️⃣ 주문 취소 (재고 복구 포함)
      await _orderRepository.cancelOrder(
        orderId: orderId,
        cancelReason: cancelReason,
      );

      debugPrint('주문 취소 완료: $orderId');
    } catch (e) {
      if (e is TossPaymentsException) {
        // 결제 취소는 실패했지만 주문은 취소 처리
        debugPrint('결제 취소 실패, 주문만 취소 처리: $e');

        await _orderRepository.cancelOrder(
          orderId: orderId,
          cancelReason: '$cancelReason (결제 취소 실패: ${e.message})',
        );
      } else {
        throw OrderServiceException(
          code: 'ORDER_CANCELLATION_FAILED',
          message: '주문 취소에 실패했습니다: $e',
        );
      }
    }
  }

  /// 📦 주문 상태 업데이트
  ///
  /// 주문의 상태를 다음 단계로 진행합니다.
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? reason,
  }) async {
    try {
      await _orderRepository.updateOrderStatus(
        orderId: orderId,
        newStatus: newStatus,
        reason: reason,
      );

      debugPrint('주문 상태 업데이트: $orderId → ${newStatus.displayName}');
    } catch (e) {
      throw OrderServiceException(
        code: 'STATUS_UPDATE_FAILED',
        message: '주문 상태 업데이트에 실패했습니다: $e',
      );
    }
  }

  /// 📸 픽업 인증 처리
  ///
  /// 픽업 완료 사진을 업로드하고 인증 처리합니다.
  Future<void> verifyPickup({
    required String orderId,
    required String pickupImageUrl,
  }) async {
    try {
      // 1️⃣ 주문 조회
      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        throw OrderServiceException(
          code: 'ORDER_NOT_FOUND',
          message: '주문을 찾을 수 없습니다: $orderId',
        );
      }

      // 2️⃣ 픽업 인증 가능한지 확인
      if (!order.canVerifyPickup) {
        throw OrderServiceException(
          code: 'PICKUP_NOT_VERIFIABLE',
          message: '픽업 인증할 수 없는 주문 상태입니다: ${order.status.displayName}',
        );
      }

      // 3️⃣ 픽업 인증 업데이트
      await _orderRepository.updatePickupVerification(
        orderId: orderId,
        pickupImageUrl: pickupImageUrl,
      );

      // 4️⃣ 주문 상태 업데이트 (preparing → pickedUp)
      await _orderRepository.updateOrderStatus(
        orderId: orderId,
        newStatus: OrderStatus.pickedUp,
      );

      debugPrint('픽업 인증 완료: $orderId');
    } catch (e) {
      throw OrderServiceException(
        code: 'PICKUP_VERIFICATION_FAILED',
        message: '픽업 인증에 실패했습니다: $e',
      );
    }
  }

  /// 📋 사용자 주문 목록 조회
  ///
  /// 페이지네이션과 필터링을 지원합니다.
  Future<List<OrderModel>> getUserOrders({
    required String userId,
    int limit = 20,
    String? lastOrderId,
    OrderStatus? statusFilter,
  }) async {
    try {
      // lastOrderId로 DocumentSnapshot 조회 (페이지네이션용)
      // 실제 구현에서는 이를 개선해야 함

      return await _orderRepository.getUserOrders(
        userId: userId,
        limit: limit,
        statusFilter: statusFilter,
      );
    } catch (e) {
      throw OrderServiceException(
        code: 'ORDER_LIST_FAILED',
        message: '주문 목록 조회에 실패했습니다: $e',
      );
    }
  }

  /// 🔍 주문 상세 조회
  ///
  /// 주문 정보와 주문 상품 목록을 함께 조회합니다.
  Future<Map<String, dynamic>?> getOrderDetail(String orderId) async {
    try {
      return await _orderRepository.getOrderWithProducts(orderId);
    } catch (e) {
      throw OrderServiceException(
        code: 'ORDER_DETAIL_FAILED',
        message: '주문 상세 조회에 실패했습니다: $e',
      );
    }
  }

  /// 🎫 주문 완료 처리
  ///
  /// 모든 상품이 픽업/배송 완료되면 주문을 완료 상태로 변경합니다.
  Future<void> completeOrder(String orderId) async {
    try {
      // 1️⃣ 주문 및 상품 조회
      final orderData = await _orderRepository.getOrderWithProducts(orderId);
      if (orderData == null) {
        throw OrderServiceException(
          code: 'ORDER_NOT_FOUND',
          message: '주문을 찾을 수 없습니다: $orderId',
        );
      }

      final order = orderData['order'] as OrderModel;
      final orderedProducts =
          orderData['orderedProducts'] as List<OrderedProduct>;

      // 2️⃣ 모든 상품이 완료되었는지 확인
      final allCompleted = orderedProducts.every((product) {
        return product.deliveryType == DeliveryType.pickup
            ? product.isPickupVerified
            : product.itemStatus == OrderItemStatus.completed;
      });

      if (!allCompleted) {
        throw OrderServiceException(
          code: 'ORDER_NOT_READY_TO_COMPLETE',
          message: '아직 완료되지 않은 상품이 있습니다.',
        );
      }

      // 3️⃣ 주문 완료 처리
      await _orderRepository.updateOrderStatus(
        orderId: orderId,
        newStatus: OrderStatus.finished,
      );

      debugPrint('주문 완료 처리: $orderId');
    } catch (e) {
      throw OrderServiceException(
        code: 'ORDER_COMPLETION_FAILED',
        message: '주문 완료 처리에 실패했습니다: $e',
      );
    }
  }

  /// 📊 주문 통계 조회
  ///
  /// 사용자별 주문 통계를 반환합니다.
  Future<Map<String, dynamic>> getOrderStats(String userId) async {
    try {
      return await _orderRepository.getUserOrderStats(userId);
    } catch (e) {
      throw OrderServiceException(
        code: 'ORDER_STATS_FAILED',
        message: '주문 통계 조회에 실패했습니다: $e',
      );
    }
  }

  /// 🧪 테스트 주문 생성 (개발용)
  ///
  /// 개발/테스트 환경에서 주문 테스트를 위한 메서드입니다.
  Future<OrderModel> createTestOrder({
    required String userId,
    int totalAmount = 10000,
  }) async {
    if (!kDebugMode) {
      throw OrderServiceException(
        code: 'TEST_ORDER_NOT_ALLOWED',
        message: '테스트 주문은 개발 모드에서만 생성 가능합니다.',
      );
    }

    // 테스트용 장바구니 아이템 생성
    final testCartItems = [
      {
        'productId': 'test_product_1',
        'quantity': 1,
      }
    ];

    try {
      return await createOrderFromCart(
        userId: userId,
        cartItems: testCartItems,
        orderNote: '테스트 주문',
      );
    } catch (e) {
      // 테스트이므로 간단한 주문 객체 반환
      return OrderModel.create(
        userId: userId,
        totalProductAmount: totalAmount,
        totalDeliveryFee: 0,
        orderNote: '테스트 주문 (실패 시 생성)',
      );
    }
  }

  /// ✅ 주문 요청 검증
  void _validateOrderRequest({
    required String userId,
    required List<Map<String, dynamic>> cartItems,
    DeliveryAddress? deliveryAddress,
  }) {
    // 사용자 ID 검증
    if (userId.isEmpty) {
      throw OrderServiceException(
        code: 'INVALID_USER_ID',
        message: '사용자 ID가 유효하지 않습니다.',
      );
    }

    // 장바구니 아이템 검증
    if (cartItems.isEmpty) {
      throw OrderServiceException(
        code: 'EMPTY_CART',
        message: '주문할 상품이 없습니다.',
      );
    }

    for (final item in cartItems) {
      final productId = item['productId'] as String?;
      final quantity = item['quantity'] as int?;

      if (productId == null || productId.isEmpty) {
        throw OrderServiceException(
          code: 'INVALID_PRODUCT_ID',
          message: '상품 ID가 유효하지 않습니다.',
        );
      }

      if (quantity == null || quantity <= 0) {
        throw OrderServiceException(
          code: 'INVALID_QUANTITY',
          message: '상품 수량이 유효하지 않습니다.',
        );
      }
    }
  }
}

/// 🚨 Order 서비스 예외 클래스
///
/// Order 서비스에서 발생하는 오류를 정의합니다.
class OrderServiceException implements Exception {
  final String code;
  final String message;

  const OrderServiceException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'OrderServiceException($code): $message';

  /// 사용자 친화적인 오류 메시지 반환
  String get userFriendlyMessage {
    switch (code) {
      case 'ORDER_NOT_FOUND':
        return '주문을 찾을 수 없습니다.';
      case 'ORDER_NOT_CANCELLABLE':
        return '취소할 수 없는 주문입니다.';
      case 'AMOUNT_MISMATCH':
        return '결제 금액이 일치하지 않습니다.';
      case 'EMPTY_CART':
        return '주문할 상품을 선택해주세요.';
      case 'INVALID_QUANTITY':
        return '상품 수량을 확인해주세요.';
      case 'PICKUP_NOT_VERIFIABLE':
        return '픽업 인증이 불가능한 상태입니다.';
      case 'ORDER_NOT_READY_TO_COMPLETE':
        return '아직 완료되지 않은 상품이 있습니다.';
      case 'PAYMENT_FAILED':
        return '결제에 실패했습니다.';
      case 'WEB_TIMEOUT_ERROR':
        return '네트워크 연결이 불안정합니다. 잠시 후 다시 시도해주세요.';
      case 'WEB_JS_ERROR':
        return '페이지를 새로고침 후 다시 시도해주세요.';
      default:
        return '주문 처리 중 오류가 발생했습니다.';
    }
  }

  /// 재시도 가능한 오류인지 확인
  bool get isRetryable {
    return [
      'NETWORK_ERROR',
      'DATABASE_ERROR',
      'TEMPORARY_FAILURE',
      'WEB_TIMEOUT_ERROR',
      'WEB_JS_ERROR',
    ].contains(code);
  }

  /// 사용자 실수로 인한 오류인지 확인
  bool get isUserError {
    return [
      'EMPTY_CART',
      'INVALID_QUANTITY',
      'INVALID_PRODUCT_ID',
      'INVALID_USER_ID',
      'AMOUNT_MISMATCH',
      'ORDER_NOT_CANCELLABLE',
      'PICKUP_NOT_VERIFIABLE',
    ].contains(code);
  }
}
