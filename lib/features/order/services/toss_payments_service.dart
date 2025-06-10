/// Toss Payments 서비스
///
/// Toss Payments API와 연동하여 결제 처리를 담당합니다.
/// Flutter SDK v1을 기반으로 구현됩니다.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../models/order_enums.dart';

/// Toss Payments 서비스 Provider
final tossPaymentsServiceProvider = Provider<TossPaymentsService>((ref) {
  return TossPaymentsService();
});

/// Toss Payments API 연동 서비스
class TossPaymentsService {
  // 🔑 API 설정
  static const String _baseUrl = 'https://api.tosspayments.com/v1';
  static const String _clientKey =
      'test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq'; // 테스트 키
  static const String _secretKey =
      'test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R'; // 테스트 키

  // 운영환경에서는 환경변수나 Firebase Remote Config 사용
  // static const String _clientKey = String.fromEnvironment('TOSS_CLIENT_KEY');
  // static const String _secretKey = String.fromEnvironment('TOSS_SECRET_KEY');

  /// 💳 결제 승인 요청
  ///
  /// 클라이언트에서 받은 paymentKey, orderId, amount로 결제를 승인합니다.
  Future<PaymentInfo> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/payments/confirm');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_secretKey:'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'paymentKey': paymentKey,
          'orderId': orderId,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentInfo.fromTossResponse(data);
      } else {
        final error = jsonDecode(response.body);
        throw TossPaymentsException(
          code: error['code'] ?? 'UNKNOWN_ERROR',
          message: error['message'] ?? '결제 승인에 실패했습니다.',
        );
      }
    } catch (e) {
      if (e is TossPaymentsException) rethrow;
      throw TossPaymentsException(
        code: 'NETWORK_ERROR',
        message: '네트워크 오류가 발생했습니다: $e',
      );
    }
  }

  /// 🔍 결제 정보 조회
  ///
  /// paymentKey로 결제 정보를 조회합니다.
  Future<PaymentInfo> getPayment(String paymentKey) async {
    try {
      final url = Uri.parse('$_baseUrl/payments/$paymentKey');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_secretKey:'))}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentInfo.fromTossResponse(data);
      } else {
        final error = jsonDecode(response.body);
        throw TossPaymentsException(
          code: error['code'] ?? 'UNKNOWN_ERROR',
          message: error['message'] ?? '결제 정보 조회에 실패했습니다.',
        );
      }
    } catch (e) {
      if (e is TossPaymentsException) rethrow;
      throw TossPaymentsException(
        code: 'NETWORK_ERROR',
        message: '네트워크 오류가 발생했습니다: $e',
      );
    }
  }

  /// ❌ 결제 취소
  ///
  /// 결제를 전액 또는 부분 취소합니다.
  Future<PaymentInfo> cancelPayment({
    required String paymentKey,
    required String cancelReason,
    int? cancelAmount, // null이면 전액 취소
    int? refundReceiveAccount, // 환불 계좌 (가상계좌 결제 시)
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/payments/$paymentKey/cancel');

      final requestBody = <String, dynamic>{
        'cancelReason': cancelReason,
      };

      if (cancelAmount != null) {
        requestBody['cancelAmount'] = cancelAmount;
      }

      if (refundReceiveAccount != null) {
        requestBody['refundReceiveAccount'] = refundReceiveAccount;
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_secretKey:'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentInfo.fromTossResponse(data);
      } else {
        final error = jsonDecode(response.body);
        throw TossPaymentsException(
          code: error['code'] ?? 'UNKNOWN_ERROR',
          message: error['message'] ?? '결제 취소에 실패했습니다.',
        );
      }
    } catch (e) {
      if (e is TossPaymentsException) rethrow;
      throw TossPaymentsException(
        code: 'NETWORK_ERROR',
        message: '네트워크 오류가 발생했습니다: $e',
      );
    }
  }

  /// 🔄 결제 키로 주문 ID 조회
  ///
  /// paymentKey로 orderId를 찾습니다.
  Future<String?> getOrderIdByPaymentKey(String paymentKey) async {
    try {
      final paymentInfo = await getPayment(paymentKey);
      return paymentInfo.orderId;
    } catch (e) {
      debugPrint('결제 키로 주문 ID 조회 실패: $e');
      return null;
    }
  }

  /// 📊 결제 통계 조회 (관리자용)
  ///
  /// 특정 기간의 결제 통계를 조회합니다.
  Future<Map<String, dynamic>> getPaymentStats({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/payments').replace(queryParameters: {
        'startDate': from.toIso8601String().split('T')[0],
        'endDate': to.toIso8601String().split('T')[0],
        'limit': '100',
      });

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_secretKey:'))}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // 간단한 통계 계산
        final payments = data['payments'] as List<dynamic>;
        int totalCount = payments.length;
        int successCount = 0;
        int totalAmount = 0;

        for (final payment in payments) {
          final status = payment['status'] as String;
          if (status == 'DONE') {
            successCount++;
            totalAmount += payment['totalAmount'] as int;
          }
        }

        return {
          'totalCount': totalCount,
          'successCount': successCount,
          'failCount': totalCount - successCount,
          'totalAmount': totalAmount,
          'averageAmount': successCount > 0 ? totalAmount / successCount : 0,
        };
      } else {
        throw TossPaymentsException(
          code: 'API_ERROR',
          message: '결제 통계 조회에 실패했습니다.',
        );
      }
    } catch (e) {
      throw TossPaymentsException(
        code: 'NETWORK_ERROR',
        message: '네트워크 오류가 발생했습니다: $e',
      );
    }
  }

  /// 🎫 빌링키 발급 (정기결제용)
  ///
  /// 카드 정보로 빌링키를 발급받습니다.
  Future<Map<String, dynamic>> issueBillingKey({
    required String customerKey,
    required String cardNumber,
    required String cardExpirationYear,
    required String cardExpirationMonth,
    required String cardPassword,
    required String customerBirthday,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/billing/authorizations/card');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_secretKey:'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customerKey': customerKey,
          'cardNumber': cardNumber,
          'cardExpirationYear': cardExpirationYear,
          'cardExpirationMonth': cardExpirationMonth,
          'cardPassword': cardPassword,
          'customerBirthday': customerBirthday,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw TossPaymentsException(
          code: error['code'] ?? 'UNKNOWN_ERROR',
          message: error['message'] ?? '빌링키 발급에 실패했습니다.',
        );
      }
    } catch (e) {
      if (e is TossPaymentsException) rethrow;
      throw TossPaymentsException(
        code: 'NETWORK_ERROR',
        message: '네트워크 오류가 발생했습니다: $e',
      );
    }
  }

  /// 🔄 빌링키로 결제 (정기결제)
  ///
  /// 발급받은 빌링키로 결제를 진행합니다.
  Future<PaymentInfo> chargeWithBillingKey({
    required String billingKey,
    required String customerKey,
    required int amount,
    required String orderId,
    required String orderName,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/billing/$billingKey');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_secretKey:'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customerKey': customerKey,
          'amount': amount,
          'orderId': orderId,
          'orderName': orderName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentInfo.fromTossResponse(data);
      } else {
        final error = jsonDecode(response.body);
        throw TossPaymentsException(
          code: error['code'] ?? 'UNKNOWN_ERROR',
          message: error['message'] ?? '빌링 결제에 실패했습니다.',
        );
      }
    } catch (e) {
      if (e is TossPaymentsException) rethrow;
      throw TossPaymentsException(
        code: 'NETWORK_ERROR',
        message: '네트워크 오류가 발생했습니다: $e',
      );
    }
  }

  /// 🧪 테스트 결제 생성 (개발용)
  ///
  /// 개발/테스트 환경에서 결제 테스트를 위한 메서드입니다.
  Future<PaymentInfo> createTestPayment({
    required String orderId,
    required int amount,
    required String orderName,
  }) async {
    if (!kDebugMode) {
      throw Exception('테스트 결제는 개발 모드에서만 사용 가능합니다.');
    }

    // 테스트용 결제 정보 생성
    return PaymentInfo(
      paymentKey: 'test_payment_${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      status: PaymentStatus.done,
      totalAmount: amount,
      balanceAmount: amount,
      suppliedAmount: (amount * 0.91).round(), // VAT 9% 제외
      vat: (amount * 0.09).round(),
      taxFreeAmount: 0,
      orderName: orderName,
      mId: 'test_mid',
      version: '2022-11-16',
      method: PaymentMethod.card,
      requestedAt: DateTime.now().subtract(Duration(minutes: 1)),
      approvedAt: DateTime.now(),
      country: 'KR',
      receiptUrl: 'https://receipt.toss.im/test',
    );
  }

  /// 🔗 결제 위젯 URL 생성
  ///
  /// 클라이언트에서 결제 위젯을 띄우기 위한 URL을 생성합니다.
  String generatePaymentWidgetUrl({
    required String orderId,
    required int amount,
    required String orderName,
    required String successUrl,
    required String failUrl,
  }) {
    final params = {
      'clientKey': _clientKey,
      'orderId': orderId,
      'amount': amount.toString(),
      'orderName': orderName,
      'successUrl': successUrl,
      'failUrl': failUrl,
    };

    final queryString = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://js.tosspayments.com/v1/payment?$queryString';
  }

  /// 🛡️ 웹훅 서명 검증
  ///
  /// Toss Payments에서 오는 웹훅의 진위를 확인합니다.
  bool verifyWebhookSignature({
    required String payload,
    required String signature,
  }) {
    // 실제 구현에서는 HMAC-SHA256으로 서명 검증
    // 여기서는 간단한 구현만 제공
    try {
      // TODO: 실제 서명 검증 로직 구현
      // final computedSignature = computeHmacSha256(_secretKey, payload);
      // return computedSignature == signature;

      return signature.isNotEmpty; // 임시 구현
    } catch (e) {
      debugPrint('웹훅 서명 검증 실패: $e');
      return false;
    }
  }
}

/// 🚨 Toss Payments 예외 클래스
///
/// Toss Payments API에서 발생하는 오류를 처리합니다.
class TossPaymentsException implements Exception {
  final String code;
  final String message;

  const TossPaymentsException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'TossPaymentsException($code): $message';

  /// 사용자 친화적인 오류 메시지 반환
  String get userFriendlyMessage {
    switch (code) {
      case 'INVALID_REQUEST':
        return '잘못된 요청입니다. 다시 시도해주세요.';
      case 'NOT_FOUND':
        return '결제 정보를 찾을 수 없습니다.';
      case 'ALREADY_PROCESSED':
        return '이미 처리된 결제입니다.';
      case 'PAYMENT_NOT_FOUND':
        return '결제 정보를 찾을 수 없습니다.';
      case 'EXCEED_MAX_DAILY_PAYMENT_COUNT':
        return '일일 최대 결제 횟수를 초과했습니다.';
      case 'REJECT_CARD_COMPANY':
        return '카드사에서 거절한 결제입니다.';
      case 'INVALID_CARD_EXPIRATION':
        return '카드 유효기간이 잘못되었습니다.';
      case 'INVALID_STOPPED_CARD':
        return '정지된 카드입니다.';
      case 'EXCEED_MAX_ONE_DAY_WITHDRAW_AMOUNT':
        return '일일 출금 한도를 초과했습니다.';
      case 'EXCEED_MAX_ONE_TIME_WITHDRAW_AMOUNT':
        return '회당 출금 한도를 초과했습니다.';
      case 'INVALID_ACCOUNT_INFO':
        return '계좌 정보가 잘못되었습니다.';
      case 'NETWORK_ERROR':
        return '네트워크 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '결제 처리 중 오류가 발생했습니다. 고객센터에 문의해주세요.';
    }
  }

  /// 재시도 가능한 오류인지 확인
  bool get isRetryable {
    return [
      'NETWORK_ERROR',
      'TEMPORARY_FAILURE',
      'TIMEOUT',
    ].contains(code);
  }

  /// 사용자 실수로 인한 오류인지 확인
  bool get isUserError {
    return [
      'INVALID_CARD_EXPIRATION',
      'INVALID_STOPPED_CARD',
      'EXCEED_MAX_DAILY_PAYMENT_COUNT',
      'EXCEED_MAX_ONE_DAY_WITHDRAW_AMOUNT',
      'EXCEED_MAX_ONE_TIME_WITHDRAW_AMOUNT',
      'INVALID_ACCOUNT_INFO',
    ].contains(code);
  }
}
