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
import '../models/payment_error_model.dart';
import 'payments_service.dart';
import 'webhook_service.dart';
import '../../products/repositories/product_repository.dart';
import '../../auth/repositories/user_repository.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/tax_calculator.dart';

/// Order 서비스 Provider
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(
    ref: ref,
    orderRepository: ref.watch(orderRepositoryProvider),
    tossPaymentsService: ref.watch(tossPaymentsServiceProvider),
    webhookService: ref.watch(webhookServiceProvider),
    productRepository: ref.watch(productRepositoryProvider),
    userRepository: ref.watch(userRepositoryProvider),
  );
});

/// 주문 관리 서비스
class OrderService {
  final Ref _ref;
  final OrderRepository _orderRepository;
  final TossPaymentsService _tossPaymentsService;
  final OrderWebhookService _webhookService;
  final ProductRepository _productRepository;
  final UserRepository _userRepository;

  OrderService({
    required Ref ref,
    required OrderRepository orderRepository,
    required TossPaymentsService tossPaymentsService,
    required OrderWebhookService webhookService,
    required ProductRepository productRepository,
    required UserRepository userRepository,
  })  : _ref = ref,
        _orderRepository = orderRepository,
        _tossPaymentsService = tossPaymentsService,
        _webhookService = webhookService,
        _productRepository = productRepository,
        _userRepository = userRepository;

  /// 🛒 장바구니에서 주문 생성
  ///
  /// 여러 상품을 한 번에 주문하고, 재고 확인 및 차감을 수행합니다.
  Future<OrderModel> createOrderFromCart({
    required String userId,
    required List<Map<String, dynamic>> cartItems, // {productId, quantity}
    required String deliveryType, // 사용자가 선택한 배송 유형
    DeliveryAddress? deliveryAddress,
    String? orderNote,
    Map<String, dynamic>? selectedPickupPointInfo,
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

      // 2️⃣ 사용자 정보 조회 (locationTag 포함)
      debugPrint('👤 사용자 정보 조회 시작');
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        throw OrderServiceException(
          code: 'USER_NOT_FOUND',
          message: '사용자 정보를 찾을 수 없습니다.',
        );
      }
      debugPrint(
          '✅ 사용자 정보 조회 완료: ${user.name} (${user.locationTagName ?? "위치 미설정"})');

      // 3️⃣ 주문 생성 (트랜잭션으로 재고 처리 포함)
      debugPrint('📦 주문 생성 및 재고 처리 시작');
      final order = await _orderRepository.createOrder(
        userId: userId,
        userName: user.name,
        userContact: user.phoneNumber,
        locationTagId: user.locationTagId,
        locationTagName: user.locationTagName,
        cartItems: cartItems,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress,
        orderNote: orderNote,
        selectedPickupPointInfo: selectedPickupPointInfo,
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

      // 5️⃣ 주문 상태 업데이트는 Firebase Functions에서 처리됨
      // 클라이언트에서 중복 업데이트 제거

      debugPrint('✅ 결제 승인 완료: $orderId, PaymentKey: $paymentKey');
      debugPrint('🛒 장바구니 삭제 및 주문 상태 업데이트는 Firebase Functions에서 처리됩니다.');

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
        if (currentProduct.stock < orderedProduct.orderedUnit['quantity']) {
          throw OrderServiceException(
            code: 'INSUFFICIENT_STOCK',
            message:
                '상품 "${currentProduct.name}"의 재고가 부족합니다. (현재 재고: ${currentProduct.stock}개, 주문 수량: ${orderedProduct.orderedUnit['quantity']}개)',
          );
        }

        // 상품 가격 변동 확인
        if (currentProduct.price.toInt() !=
            orderedProduct.orderedUnit['price']) {
          debugPrint('⚠️ 상품 가격 변동 감지: ${currentProduct.name}');
          debugPrint('   주문 시 가격: ${orderedProduct.orderedUnit['price']}원');
          debugPrint('   현재 가격: ${currentProduct.price.toInt()}원');

          throw OrderServiceException(
            code: 'PRICE_CHANGED',
            message: '상품 "${currentProduct.name}"의 가격이 변경되었습니다. 주문을 다시 진행해주세요.',
          );
        }

        // 개별 상품 금액 계산
        int productTotal =
            (orderedProduct.orderedUnit['price'] as num).toInt() *
                (orderedProduct.orderedUnit['quantity'] as num).toInt();
        totalCalculatedAmount += productTotal;

        debugPrint(
            '✅ 상품 "${currentProduct.name}": ${orderedProduct.orderedUnit['price']}원 × ${orderedProduct.orderedUnit['quantity']}개 = $productTotal원');
      }

      // 배송비 추가 (기존 주문의 배송비 사용)
      totalCalculatedAmount += order.totalDeliveryFee;

      debugPrint('🔒 서버 계산 완료:');
      debugPrint(
          '   상품 금액: ${totalCalculatedAmount - order.totalDeliveryFee}원');
      debugPrint('   배송비: ${order.totalDeliveryFee}원');
      debugPrint('   총 금액: $totalCalculatedAmount원');
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
    required String deliveryType, // 사용자가 선택한 배송 유형
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
      deliveryType: deliveryType,
      deliveryAddress: deliveryAddress,
      orderNote: orderNote,
    );
  }

  /// ❌ 주문 취소 (Firebase Function 통합)
  ///
  /// Firebase Function을 통해 주문을 취소합니다.
  /// 결제 취소, 재고 복구, 주문 상태 업데이트가 서버에서 트랜잭션으로 처리됩니다.
  Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
    required String cancelReason,
    int? cancelAmount, // 부분 취소 지원
  }) async {
    try {
      debugPrint('🔄 주문 취소 시작: $orderId');

      // 1️⃣ 주문 조회 및 기본 검증 (클라이언트에서 빠른 검증)
      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        throw OrderServiceException(
          code: 'ORDER_NOT_FOUND',
          message: '주문을 찾을 수 없습니다: $orderId',
        );
      }

      // 2️⃣ 기본 취소 가능 여부 확인 (상세 검증은 서버에서)
      if (!order.isCancellable) {
        throw OrderServiceException(
          code: 'ORDER_NOT_CANCELLABLE',
          message: '취소할 수 없는 주문 상태입니다: ${order.status.displayName}',
        );
      }

      // 3️⃣ Firebase Function을 통한 통합 취소 처리
      final result = await _orderRepository.cancelOrder(
        orderId: orderId,
        cancelReason: cancelReason,
        paymentKey: order.paymentInfo?.paymentKey,
        cancelAmount: cancelAmount,
      );

      debugPrint('✅ 주문 취소 완료: $orderId');
      debugPrint('📋 결과: ${result['success']}');

      return result;
    } catch (e) {
      debugPrint('❌ 주문 취소 실패: $e');

      if (e is OrderServiceException) {
        rethrow;
      }

      throw OrderServiceException(
        code: 'ORDER_CANCELLATION_FAILED',
        message: '주문 취소에 실패했습니다: $e',
      );
    }
  }

  /// 💰 결제 환불 요청
  ///
  /// 주문에 대한 전액 또는 부분 환불을 처리합니다.
  /// 가상계좌 결제인 경우 환불 계좌 정보가 필요합니다.
  ///
  /// ⚠️ 주의: 실제 주문 상태 업데이트는 Firebase Functions에서 처리됩니다.
  /// 클라이언트에서는 환불 요청만 하고, 상태 변경은 서버에서 처리합니다.
  Future<Map<String, dynamic>> requestRefund({
    required String orderId,
    required String cancelReason,
    int? cancelAmount, // null이면 전액 환불
    Map<String, dynamic>? refundReceiveAccount, // 가상계좌 환불 시 필수
  }) async {
    try {
      debugPrint(
          '💰 환불 요청 시작: orderId=$orderId, amount=${cancelAmount ?? "전액"}');

      // 1️⃣ 주문 조회 및 기본 검증
      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        throw OrderServiceException(
          code: 'ORDER_NOT_FOUND',
          message: '주문을 찾을 수 없습니다: $orderId',
        );
      }

      // 2️⃣ 환불 가능 여부 확인
      final canRefund = await canRequestRefund(order);
      if (!canRefund) {
        final denialReason = await getRefundDenialReason(order);
        throw OrderServiceException(
          code: 'REFUND_NOT_ALLOWED',
          message: denialReason ?? '환불할 수 없는 주문입니다.',
        );
      }

      // 3️⃣ 결제 정보 확인
      final paymentInfo = order.paymentInfo;
      if (paymentInfo?.paymentKey == null) {
        throw OrderServiceException(
          code: 'PAYMENT_INFO_NOT_FOUND',
          message: '결제 정보를 찾을 수 없습니다.',
        );
      }

      // 4️⃣ 부분 환불 금액 검증
      if (cancelAmount != null) {
        if (cancelAmount <= 0) {
          throw OrderServiceException(
            code: 'INVALID_AMOUNT',
            message: '환불 금액은 0보다 커야 합니다.',
          );
        }

        if (cancelAmount > (paymentInfo!.balanceAmount ?? order.totalAmount)) {
          throw OrderServiceException(
            code: 'AMOUNT_EXCEEDS_BALANCE',
            message:
                '환불 가능한 금액을 초과했습니다. (최대: ${paymentInfo.balanceAmount ?? order.totalAmount}원)',
          );
        }
      }

      // 5️⃣ 가상계좌 환불 시 계좌 정보 확인
      if (paymentInfo!.method == PaymentMethod.virtualAccount &&
          refundReceiveAccount == null) {
        throw OrderServiceException(
          code: 'REFUND_ACCOUNT_REQUIRED',
          message: '가상계좌 결제 환불 시 환불받을 계좌 정보가 필요합니다.',
        );
      }

      // 6️⃣ 멱등키 생성 (중복 환불 방지)
      final idempotencyKey =
          '${orderId}_${DateTime.now().millisecondsSinceEpoch}';

      // 🆕 7️⃣ 환불 세금 계산 (정확한 VAT 처리)
      final refundTaxBreakdown = TaxCalculator.calculateRefundTax(
        totalRefundAmount: cancelAmount ?? order.totalAmount,
        originalTotalAmount: order.totalAmount,
        originalSuppliedAmount: order.suppliedAmount,
        originalVat: order.vat,
        originalTaxFreeAmount: order.taxFreeAmount,
        refundedItems: null, // 주문 레벨 환불이므로 null
      );

      debugPrint('💸 환불 세금 계산 완료: $refundTaxBreakdown');

      debugPrint('💰 토스페이먼츠 환불 API 호출 시작');
      debugPrint('   - paymentKey: ${paymentInfo.paymentKey}');
      debugPrint('   - cancelAmount: ${cancelAmount ?? "전액"}');
      debugPrint('   - idempotencyKey: $idempotencyKey');
      debugPrint(
          '   - taxBreakdown: ${refundTaxBreakdown.toTossPaymentsCancelMap()}');

      // 8️⃣ 토스페이먼츠 환불 API 호출 (Firebase Functions 통해) - 세금 정보 포함
      final refundResult = await _tossPaymentsService.refundPayment(
        paymentKey: paymentInfo.paymentKey!,
        cancelReason: cancelReason,
        cancelAmount: cancelAmount,
        refundReceiveAccount: refundReceiveAccount,
        idempotencyKey: idempotencyKey,
        taxBreakdown:
            refundTaxBreakdown.toTossPaymentsCancelMap(), // 🆕 세금 정보 추가
      );

      // 9️⃣ 클라이언트 측에서는 상태 업데이트하지 않음
      // ⚠️ 주문 상태 업데이트는 Firebase Functions에서 처리됨
      // 클라이언트에서 중복 업데이트 방지를 위해 로컬 상태 변경 제거

      debugPrint(
          '✅ 환불 처리 완료: orderId=$orderId, amount=${cancelAmount ?? "전액"}');
      debugPrint('📋 주문 상태 업데이트는 Firebase Functions에서 처리됩니다.');

      // 환불 결과에 추가 정보 포함
      final enhancedResult = Map<String, dynamic>.from(refundResult);
      enhancedResult['orderId'] = orderId;
      enhancedResult['isFullRefund'] =
          cancelAmount == null || cancelAmount == order.totalAmount;
      enhancedResult['clientProcessedAt'] = DateTime.now().toIso8601String();

      return enhancedResult;
    } catch (e) {
      debugPrint('❌ 환불 처리 실패: $e');

      if (e is OrderServiceException) {
        rethrow;
      }

      if (e is PaymentError) {
        throw OrderServiceException(
          code: 'REFUND_FAILED',
          message: e.message,
        );
      }

      throw OrderServiceException(
        code: 'REFUND_REQUEST_FAILED',
        message: '환불 요청에 실패했습니다: $e',
      );
    }
  }

  /// 📋 사용자 환불 내역 조회
  ///
  /// 사용자의 모든 환불 내역을 페이지네이션으로 조회합니다.
  Future<Map<String, dynamic>> getUserRefunds({
    int limit = 20,
    dynamic startAfter,
  }) async {
    try {
      return await _tossPaymentsService.getUserRefunds(
        limit: limit,
        startAfter: startAfter,
      );
    } catch (e) {
      if (e is PaymentError) {
        throw OrderServiceException(
          code: 'REFUND_LIST_FAILED',
          message: e.message,
        );
      }

      throw OrderServiceException(
        code: 'REFUND_LIST_FAILED',
        message: '환불 내역 조회에 실패했습니다: $e',
      );
    }
  }

  /// 🔍 환불 가능 여부 확인
  ///
  /// 주문 상태와 결제 정보를 종합하여 환불 가능 여부를 판단합니다.
  Future<bool> canRequestRefund(OrderModel order) async {
    try {
      // 1️⃣ 주문 상태 확인
      if (order.status == OrderStatus.cancelled) {
        return false; // 이미 취소된 주문
      }

      // 2️⃣ 결제 정보 확인
      final paymentInfo = order.paymentInfo;
      if (paymentInfo == null || !paymentInfo.isSuccessful) {
        return false; // 결제되지 않은 주문
      }

      // 3️⃣ 환불 가능한 잔액 확인
      if ((paymentInfo.balanceAmount ?? 0) <= 0) {
        return false; // 이미 전액 환불된 주문
      }

      // 4️⃣ 토스페이먼츠 환불 정책 확인
      return await _tossPaymentsService.canRefund(paymentInfo);
    } catch (e) {
      debugPrint('환불 가능 여부 확인 실패: $e');
      return false;
    }
  }

  /// 💡 환불 불가 사유 반환
  ///
  /// 환불이 불가능한 경우 그 이유를 사용자 친화적인 메시지로 반환합니다.
  Future<String?> getRefundDenialReason(OrderModel order) async {
    try {
      // 1️⃣ 주문 상태 확인
      if (order.status == OrderStatus.cancelled) {
        return '이미 취소된 주문입니다.';
      }

      // 2️⃣ 결제 정보 확인
      final paymentInfo = order.paymentInfo;
      if (paymentInfo == null || !paymentInfo.isSuccessful) {
        return '결제되지 않은 주문은 환불할 수 없습니다.';
      }

      // 3️⃣ 환불 가능한 잔액 확인
      if ((paymentInfo.balanceAmount ?? 0) <= 0) {
        return '이미 전액 환불된 주문입니다.';
      }

      // 4️⃣ 토스페이먼츠 환불 정책 확인
      return await _tossPaymentsService.getRefundDenialReason(paymentInfo);
    } catch (e) {
      debugPrint('환불 불가 사유 확인 실패: $e');
      return '환불 가능 여부를 확인할 수 없습니다.';
    }
  }

  /// 📊 주문별 환불 내역 조회
  ///
  /// 특정 주문의 환불 내역을 조회합니다.
  Future<List<Map<String, dynamic>>> getOrderRefundHistory(
      String orderId) async {
    try {
      debugPrint('환불 내역 조회: orderId=$orderId');
      return await _orderRepository.getRefundHistory(orderId);
    } catch (e) {
      throw OrderServiceException(
        code: 'REFUND_HISTORY_FAILED',
        message: '환불 내역 조회에 실패했습니다: $e',
      );
    }
  }

  /// 💳 환불 가능 금액 계산
  ///
  /// 주문의 현재 환불 가능한 금액을 반환합니다.
  Future<int> getRefundableAmount(String orderId) async {
    try {
      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        throw OrderServiceException(
          code: 'ORDER_NOT_FOUND',
          message: '주문을 찾을 수 없습니다: $orderId',
        );
      }

      final paymentInfo = order.paymentInfo;
      if (paymentInfo == null || !paymentInfo.isSuccessful) {
        return 0;
      }

      return paymentInfo.balanceAmount ?? 0;
    } catch (e) {
      if (e is OrderServiceException) {
        rethrow;
      }

      throw OrderServiceException(
        code: 'REFUNDABLE_AMOUNT_FAILED',
        message: '환불 가능 금액 조회에 실패했습니다: $e',
      );
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

      final result = await _orderRepository.getUserOrders(
        userId: userId,
        limit: limit,
        statusFilter: statusFilter,
      );

      // OrderQueryResult에서 orders만 추출하여 반환
      return result.orders;
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

  // /// 🧪 테스트 주문 생성 (개발용)
  // ///
  // /// 개발/테스트 환경에서 주문 테스트를 위한 메서드입니다.
  // Future<OrderModel> createTestOrder({
  //   required String userId,
  //   int totalAmount = 10000,
  // }) async {
  //   if (!kDebugMode) {
  //     throw OrderServiceException(
  //       code: 'TEST_ORDER_NOT_ALLOWED',
  //       message: '테스트 주문은 개발 모드에서만 생성 가능합니다.',
  //     );
  //   }

  //   // 테스트용 장바구니 아이템 생성
  //   final testCartItems = [
  //     {
  //       'productId': 'test_product_1',
  //       'quantity': 1,
  //     }
  //   ];

  //   try {
  //     return await createOrderFromCart(
  //       userId: userId,
  //       cartItems: testCartItems,
  //       deliveryType: '배송', // 테스트용 기본값
  //       orderNote: '테스트 주문',
  //     );
  //   } catch (e) {
  //     // 테스트이므로 간단한 주문 객체 반환
  //     return OrderModel.create(
  //       userId: userId,
  //       userName: 'Test User',
  //       totalProductAmount: totalAmount,
  //       totalDeliveryFee: 0,
  //       orderNote: '테스트 주문 (실패 시 생성)',
  //     );
  //   }
  // }

  /// 🛒 장바구니에서 주문된 상품들 삭제 (현재 Firebase Functions에서 처리)
  ///
  /// ⚠️ 이 메서드는 더 이상 사용되지 않습니다.
  /// 장바구니 삭제는 Firebase Functions의 confirmPayment에서 처리됩니다.
  /// 웹과 모바일 환경 모두에서 일관된 처리를 위해 서버측에서 처리하도록 변경되었습니다.
  ///
  /// @deprecated Firebase Functions에서 처리됨
  @Deprecated('Firebase Functions에서 처리됨')
  Future<void> _removeOrderedItemsFromCart(String orderId) async {
    debugPrint(
        '⚠️ 이 메서드는 더 이상 사용되지 않습니다. Firebase Functions에서 장바구니 삭제를 처리합니다.');
    // 실제 로직은 Firebase Functions의 removeOrderedItemsFromCart에서 처리됨
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

  /// 🗑️ 결제 실패 시 대기 중인 주문 삭제 (Firebase Functions 통해 처리)
  ///
  /// 결제가 실패했을 때 pending 상태의 주문을 삭제하고 재고를 복구합니다.
  /// 보안과 안정성을 위해 서버사이드(Firebase Functions)에서 처리됩니다.
  Future<void> deletePendingOrderOnPaymentFailure(String orderId,
      {String? reason}) async {
    try {
      debugPrint('🗑️ 결제 실패로 인한 주문 삭제 요청: $orderId');

      // Firebase Functions를 통해 서버사이드에서 안전하게 처리
      final result =
          await _tossPaymentsService.deletePendingOrderOnPaymentFailure(
        orderId: orderId,
        reason: reason ?? '결제 실패',
      );

      if (result['success'] == true) {
        debugPrint('✅ 결제 실패로 인한 주문 삭제 완료: $orderId');
        debugPrint('📈 재고 복구된 상품 수: ${result['deletedProductCount']}개');
      } else {
        final errorMessage = result['message'] ?? '알 수 없는 오류가 발생했습니다.';
        throw OrderServiceException(
          code: 'ORDER_DELETION_FAILED',
          message: errorMessage,
        );
      }
    } catch (e) {
      debugPrint('❌ 결제 실패 주문 삭제 실패: $orderId, 오류: $e');

      if (e is OrderServiceException) {
        rethrow;
      }

      if (e is PaymentError) {
        throw OrderServiceException(
          code: e.code,
          message: e.message,
        );
      }

      throw OrderServiceException(
        code: 'ORDER_DELETION_FAILED',
        message: '주문 삭제에 실패했습니다: $e',
      );
    }
  }

  /// 🧪 결제 실패 주문 삭제 테스트 (개발용)
  ///
  /// 개발/테스트 환경에서 결제 실패 시 주문 삭제 기능을 테스트합니다.
  Future<Map<String, dynamic>> testPendingOrderDeletion({
    required String orderId,
  }) async {
    if (!kDebugMode) {
      throw OrderServiceException(
        code: 'TEST_NOT_ALLOWED',
        message: '테스트 기능은 개발 모드에서만 사용 가능합니다.',
      );
    }

    try {
      debugPrint('🧪 결제 실패 주문 삭제 테스트 시작: $orderId');

      // 1️⃣ 삭제 전 주문 상태 확인
      final orderBefore = await _orderRepository.getOrderById(orderId);
      if (orderBefore == null) {
        return {
          'success': false,
          'message': '테스트할 주문을 찾을 수 없습니다.',
          'orderId': orderId,
        };
      }

      final orderStatusBefore = orderBefore.status;
      final orderedProductsBefore =
          await _orderRepository.getOrderedProducts(orderId);

      debugPrint(
          '🧪 삭제 전 상태: ${orderStatusBefore.displayName}, 상품 수: ${orderedProductsBefore.length}개');

      // 2️⃣ 주문 삭제 실행
      await deletePendingOrderOnPaymentFailure(orderId);

      // 3️⃣ 삭제 후 확인
      final orderAfter = await _orderRepository.getOrderById(orderId);
      final orderedProductsAfter =
          await _orderRepository.getOrderedProducts(orderId);

      final testResult = {
        'success': true,
        'orderId': orderId,
        'beforeDeletion': {
          'status': orderStatusBefore.value,
          'productCount': orderedProductsBefore.length,
        },
        'afterDeletion': {
          'orderExists': orderAfter != null,
          'productCount': orderedProductsAfter.length,
        },
        'message':
            orderAfter == null ? '✅ 주문이 성공적으로 삭제되었습니다.' : '⚠️ 주문이 아직 존재합니다.',
      };

      debugPrint('🧪 테스트 결과: $testResult');
      return testResult;
    } catch (e) {
      debugPrint('🧪 테스트 실패: $e');
      return {
        'success': false,
        'orderId': orderId,
        'error': e.toString(),
        'message': '테스트 중 오류가 발생했습니다.',
      };
    }
  }

  /// 🔄 환불 요청 상태 변경
  ///
  /// 주문 상태를 'refundRequested'로 변경합니다.
  /// 배송 완료(delivered) 또는 픽업 완료(pickedUp) 상태에서만 가능합니다.
  Future<void> requestRefundStatus({
    required String orderId,
    String? reason,
  }) async {
    try {
      debugPrint('🔄 환불 요청 상태 변경 시작: $orderId');

      // 1️⃣ 주문 조회 및 상태 확인
      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        throw OrderServiceException(
          code: 'ORDER_NOT_FOUND',
          message: '주문을 찾을 수 없습니다: $orderId',
        );
      }

      // 2️⃣ 환불 요청 가능한 상태인지 확인
      if (!_canRequestRefundStatus(order.status)) {
        throw OrderServiceException(
          code: 'REFUND_REQUEST_NOT_ALLOWED',
          message:
              '환불 요청은 배송 완료 또는 픽업 완료 후에만 가능합니다. 현재 상태: ${order.status.displayName}',
        );
      }

      // 3️⃣ 주문 상태 업데이트
      await _orderRepository.updateOrderStatus(
        orderId: orderId,
        newStatus: OrderStatus.refundRequested,
        reason: reason ?? '고객 환불 요청',
      );

      debugPrint('✅ 환불 요청 상태 변경 완료: $orderId');
    } catch (e) {
      debugPrint('❌ 환불 요청 상태 변경 실패: $orderId, 오류: $e');

      if (e is OrderServiceException) {
        rethrow;
      }

      throw OrderServiceException(
        code: 'REFUND_STATUS_UPDATE_FAILED',
        message: '환불 요청 처리에 실패했습니다: $e',
      );
    }
  }

  /// 📋 환불 요청 가능한 상태인지 확인
  bool _canRequestRefundStatus(OrderStatus status) {
    return [
      OrderStatus.delivered,
      OrderStatus.pickedUp,
    ].contains(status);
  }

  /// 🗑️ 주문 삭제 및 재고 복구 (pending 상태만)
  ///
  /// pending 상태의 주문을 삭제하고 재고를 복구합니다.
  /// OrderedProduct의 orderedUnit 정보를 사용하여 재고를 복구합니다.
  Future<void> deleteOrderAndRestoreStock({
    required String orderId,
  }) async {
    try {
      debugPrint('🗑️ 주문 삭제 및 재고 복구 시작: $orderId');

      // 1️⃣ 주문 조회 및 검증
      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        throw OrderServiceException(
          code: 'ORDER_NOT_FOUND',
          message: '주문을 찾을 수 없습니다: $orderId',
        );
      }

      // 2️⃣ pending 상태 확인
      if (order.status != OrderStatus.pending) {
        throw OrderServiceException(
          code: 'ORDER_NOT_DELETABLE',
          message: '삭제할 수 없는 주문 상태입니다: ${order.status.displayName}',
        );
      }

      // 3️⃣ 결제 완료 여부 확인
      if (order.isPaymentCompleted) {
        throw OrderServiceException(
          code: 'ORDER_ALREADY_PAID',
          message: '결제가 완료된 주문은 삭제할 수 없습니다.',
        );
      }

      // 4️⃣ 주문 상품 조회
      final orderedProducts =
          await _orderRepository.getOrderedProducts(orderId);
      debugPrint('📦 주문 상품 ${orderedProducts.length}개 확인');

      // 5️⃣ 재고 복구를 위한 정보 수집
      final stockUpdates = <Map<String, dynamic>>[];
      for (final orderedProduct in orderedProducts) {
        final orderedUnit = orderedProduct.orderedUnit;
        final unit = orderedUnit['unit'] as String;
        final quantity = orderedUnit['quantity'] as int;

        stockUpdates.add({
          'productId': orderedProduct.productId,
          'unit': unit,
          'quantity': quantity,
        });

        debugPrint(
            '📦 재고 복구 예정: ${orderedProduct.productName} - $unit: $quantity개');
      }

      // 6️⃣ 트랜잭션으로 재고 복구 및 주문 삭제
      await _productRepository.restoreStockAndDeleteOrder(
        orderId: orderId,
        stockUpdates: stockUpdates,
      );

      debugPrint('✅ 주문 삭제 및 재고 복구 완료: $orderId');
    } catch (e) {
      debugPrint('❌ 주문 삭제 실패: $e');

      if (e is OrderServiceException) {
        rethrow;
      }

      throw OrderServiceException(
        code: 'ORDER_DELETION_FAILED',
        message: '주문 삭제에 실패했습니다: $e',
      );
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
      case 'ORDER_NOT_DELETABLE':
        return '삭제할 수 없는 주문 상태입니다.';
      case 'ORDER_ALREADY_PAID':
        return '이미 결제가 완료된 주문입니다.';
      case 'ORDER_DELETION_FAILED':
        return '주문 삭제 중 오류가 발생했습니다.';
      case 'REFUND_REQUEST_NOT_ALLOWED':
        return '환불 요청은 상품을 받아보신 후 가능합니다.';
      case 'REFUND_STATUS_UPDATE_FAILED':
        return '환불 요청 처리에 실패했습니다.';
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
