/// Order Webhook 서비스
///
/// Toss Payments에서 오는 웹훅을 처리하고 주문 상태를 업데이트합니다.
/// 로깅 및 재시도 로직을 포함합니다.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../models/order_enums.dart';
import '../repositories/order_repository.dart';
import 'toss_payments_service.dart';

/// Webhook 서비스 Provider
final webhookServiceProvider = Provider<OrderWebhookService>((ref) {
  return OrderWebhookService(
    orderRepository: ref.watch(orderRepositoryProvider),
    tossPaymentsService: ref.watch(tossPaymentsServiceProvider),
  );
});

/// Order Webhook 처리 서비스
class OrderWebhookService {
  final OrderRepository _orderRepository;
  final TossPaymentsService _tossPaymentsService;

  OrderWebhookService({
    required OrderRepository orderRepository,
    required TossPaymentsService tossPaymentsService,
  })  : _orderRepository = orderRepository,
        _tossPaymentsService = tossPaymentsService;

  /// 🎣 Toss Payments 웹훅 처리
  ///
  /// Toss Payments에서 오는 웹훅을 받아서 처리합니다.
  Future<Map<String, dynamic>> handleTossWebhook({
    required String payload,
    required String signature,
    Map<String, String>? headers,
  }) async {
    OrderWebhookLog? log;

    try {
      // 1️⃣ 웹훅 서명 검증
      if (!_tossPaymentsService.verifyWebhookSignature(
        payload: payload,
        signature: signature,
      )) {
        throw WebhookException(
          code: 'INVALID_SIGNATURE',
          message: '웹훅 서명이 유효하지 않습니다.',
        );
      }

      // 2️⃣ 페이로드 파싱
      final Map<String, dynamic> webhookData;
      try {
        webhookData = jsonDecode(payload) as Map<String, dynamic>;
      } catch (e) {
        throw WebhookException(
          code: 'INVALID_PAYLOAD',
          message: '웹훅 페이로드를 파싱할 수 없습니다: $e',
        );
      }

      // 3️⃣ 이벤트 타입 및 주문 ID 추출
      final eventType = _extractEventType(webhookData);
      final orderId = _extractOrderId(webhookData);

      if (orderId == null) {
        throw WebhookException(
          code: 'MISSING_ORDER_ID',
          message: '주문 ID를 찾을 수 없습니다.',
        );
      }

      // 4️⃣ 웹훅 로그 생성
      log = OrderWebhookLog.create(
        orderId: orderId,
        eventType: eventType,
        rawPayload: webhookData,
      );

      await _orderRepository.saveWebhookLog(log);

      // 5️⃣ 이벤트별 처리
      late String processResult;

      switch (eventType) {
        case WebhookEventType.paymentDone:
          processResult = await _handlePaymentConfirmed(webhookData, orderId);
          break;
        case WebhookEventType.paymentCanceled:
          processResult = await _handlePaymentCanceled(webhookData, orderId);
          break;
        case WebhookEventType.virtualAccountDeposit:
          processResult =
              await _handleVirtualAccountDeposit(webhookData, orderId);
          break;
        default:
          processResult = '지원하지 않는 이벤트 타입: ${eventType.value}';
          debugPrint('지원하지 않는 웹훅 이벤트: ${eventType.value}');
      }

      // 6️⃣ 로그 업데이트 (성공)
      await _orderRepository.updateWebhookLog(
        logId: log.logId,
        isProcessed: true,
        processResult: processResult,
      );

      return {
        'success': true,
        'message': processResult,
        'orderId': orderId,
        'eventType': eventType.value,
      };
    } catch (e) {
      // 7️⃣ 에러 처리 및 로그 업데이트
      final errorMessage = e.toString();
      debugPrint('웹훅 처리 실패: $errorMessage');

      if (log != null) {
        await _orderRepository.updateWebhookLog(
          logId: log.logId,
          isProcessed: false,
          errorMessage: errorMessage,
          retryCount: log.retryCount + 1,
        );
      }

      return {
        'success': false,
        'error': errorMessage,
        'retryable': e is WebhookException ? e.isRetryable : true,
      };
    }
  }

  /// 💳 결제 승인 완료 처리
  Future<String> _handlePaymentConfirmed(
    Map<String, dynamic> webhookData,
    String orderId,
  ) async {
    try {
      // 1️⃣ 주문 조회
      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        throw WebhookException(
          code: 'ORDER_NOT_FOUND',
          message: '주문을 찾을 수 없습니다: $orderId',
        );
      }

      // 2️⃣ 결제 정보 생성
      final paymentInfo = PaymentInfo.fromTossResponse(webhookData);

      // 3️⃣ 결제 정보 업데이트
      await _orderRepository.updatePaymentInfo(
        orderId: orderId,
        paymentInfo: paymentInfo,
      );

      // 4️⃣ 주문 상태 업데이트 (pending → confirmed)
      if (order.status == OrderStatus.pending) {
        await _orderRepository.updateOrderStatus(
          orderId: orderId,
          newStatus: OrderStatus.confirmed,
        );
      }

      return '결제 승인 완료 처리됨. 금액: ${paymentInfo.totalAmount}원';
    } catch (e) {
      throw WebhookException(
        code: 'PAYMENT_CONFIRMATION_FAILED',
        message: '결제 승인 처리 실패: $e',
      );
    }
  }

  /// ❌ 결제 취소 완료 처리
  Future<String> _handlePaymentCanceled(
    Map<String, dynamic> webhookData,
    String orderId,
  ) async {
    try {
      // 1️⃣ 주문 조회
      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        throw WebhookException(
          code: 'ORDER_NOT_FOUND',
          message: '주문을 찾을 수 없습니다: $orderId',
        );
      }

      // 2️⃣ 결제 정보 업데이트
      final paymentInfo = PaymentInfo.fromTossResponse(webhookData);
      await _orderRepository.updatePaymentInfo(
        orderId: orderId,
        paymentInfo: paymentInfo,
      );

      // 3️⃣ 취소 사유 추출
      final cancels = webhookData['cancels'] as List<dynamic>? ?? [];
      String cancelReason = '결제 취소';
      if (cancels.isNotEmpty) {
        final lastCancel = cancels.last as Map<String, dynamic>;
        cancelReason = lastCancel['cancelReason'] as String? ?? '결제 취소';
      }

      // 4️⃣ 주문 취소 처리 (재고 복구 포함)
      await _orderRepository.cancelOrder(
        orderId: orderId,
        cancelReason: cancelReason,
      );

      return '결제 취소 완료 처리됨. 사유: $cancelReason';
    } catch (e) {
      throw WebhookException(
        code: 'PAYMENT_CANCELLATION_FAILED',
        message: '결제 취소 처리 실패: $e',
      );
    }
  }

  /// 🏦 가상계좌 입금 완료 처리
  Future<String> _handleVirtualAccountDeposit(
    Map<String, dynamic> webhookData,
    String orderId,
  ) async {
    try {
      // 가상계좌 입금은 결제 완료와 동일하게 처리
      return await _handlePaymentConfirmed(webhookData, orderId);
    } catch (e) {
      throw WebhookException(
        code: 'VIRTUAL_ACCOUNT_DEPOSIT_FAILED',
        message: '가상계좌 입금 처리 실패: $e',
      );
    }
  }

  /// 🔄 미처리 웹훅 재시도
  ///
  /// 실패한 웹훅들을 주기적으로 재시도합니다.
  Future<void> retryUnprocessedWebhooks({int maxRetries = 3}) async {
    try {
      final unprocessedLogs =
          await _orderRepository.getUnprocessedWebhookLogs();

      for (final log in unprocessedLogs) {
        // 최대 재시도 횟수 초과 시 스킵
        if (log.retryCount >= maxRetries) {
          debugPrint('웹훅 최대 재시도 초과: ${log.logId}');
          continue;
        }

        try {
          // 웹훅 재처리
          await handleTossWebhook(
            payload: jsonEncode(log.rawPayload),
            signature: 'retry', // 재시도 시에는 서명 검증 스킵
            headers: {'X-Retry': 'true'},
          );

          debugPrint('웹훅 재시도 성공: ${log.logId}');
        } catch (e) {
          debugPrint('웹훅 재시도 실패: ${log.logId}, 오류: $e');

          // 재시도 카운트 증가
          await _orderRepository.updateWebhookLog(
            logId: log.logId,
            isProcessed: false,
            errorMessage: e.toString(),
            retryCount: log.retryCount + 1,
          );
        }
      }
    } catch (e) {
      debugPrint('미처리 웹훅 재시도 중 오류: $e');
    }
  }

  /// 📊 웹훅 처리 통계 조회
  Future<Map<String, dynamic>> getWebhookStats({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      // 여기서는 간단한 구현만 제공
      // 실제로는 Firestore에서 집계 쿼리를 사용해야 함

      return {
        'totalWebhooks': 0,
        'processedWebhooks': 0,
        'failedWebhooks': 0,
        'retryCount': 0,
        'averageProcessingTime': 0.0,
      };
    } catch (e) {
      throw Exception('웹훅 통계 조회 실패: $e');
    }
  }

  /// 🔍 웹훅 데이터에서 이벤트 타입 추출
  WebhookEventType _extractEventType(Map<String, dynamic> webhookData) {
    final eventType = webhookData['eventType'] as String?;
    if (eventType != null) {
      return WebhookEventType.fromString(eventType);
    }

    // eventType이 없는 경우 다른 필드로 추정
    final status = webhookData['status'] as String?;
    if (status == 'DONE') {
      return WebhookEventType.paymentDone;
    } else if (status == 'CANCELED') {
      return WebhookEventType.paymentCanceled;
    }

    return WebhookEventType.unknown;
  }

  /// 🆔 웹훅 데이터에서 주문 ID 추출
  String? _extractOrderId(Map<String, dynamic> webhookData) {
    // 직접적인 orderId 필드
    String? orderId = webhookData['orderId'] as String?;
    if (orderId != null) return orderId;

    // 다른 경로에서 찾기
    final orderName = webhookData['orderName'] as String?;
    if (orderName != null && orderName.contains('_')) {
      // orderName에서 orderId 추출 시도
      return orderName.split('_').first;
    }

    return null;
  }

  /// 🧪 테스트 웹훅 생성 (개발용)
  Future<Map<String, dynamic>> createTestWebhook({
    required String orderId,
    required WebhookEventType eventType,
    Map<String, dynamic>? customData,
  }) async {
    if (!kDebugMode) {
      throw Exception('테스트 웹훅은 개발 모드에서만 사용 가능합니다.');
    }

    final testData = <String, dynamic>{
      'eventType': eventType.value,
      'orderId': orderId,
      'status': eventType == WebhookEventType.paymentDone ? 'DONE' : 'CANCELED',
      'totalAmount': 10000,
      'paymentKey': 'test_payment_key_${DateTime.now().millisecondsSinceEpoch}',
      'method': 'CARD',
      'requestedAt': DateTime.now().toIso8601String(),
      'approvedAt': DateTime.now().toIso8601String(),
      ...?customData,
    };

    return await handleTossWebhook(
      payload: jsonEncode(testData),
      signature: 'test_signature',
    );
  }
}

/// 🚨 웹훅 예외 클래스
///
/// 웹훅 처리 중 발생하는 오류를 정의합니다.
class WebhookException implements Exception {
  final String code;
  final String message;

  const WebhookException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'WebhookException($code): $message';

  /// 재시도 가능한 오류인지 확인
  bool get isRetryable {
    return [
      'NETWORK_ERROR',
      'DATABASE_ERROR',
      'TEMPORARY_FAILURE',
      'TIMEOUT',
    ].contains(code);
  }

  /// 심각한 오류인지 확인 (즉시 알림 필요)
  bool get isCritical {
    return [
      'ORDER_NOT_FOUND',
      'PAYMENT_CONFIRMATION_FAILED',
      'PAYMENT_CANCELLATION_FAILED',
    ].contains(code);
  }
}
