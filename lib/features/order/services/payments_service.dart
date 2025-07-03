/// Toss Payments 서비스
///
/// Toss Payments API와 연동하여 결제 처리를 담당합니다.
/// 🔒 보안: 모든 시크릿 키 사용은 Firebase Cloud Functions에서만 처리
/// 클라이언트에서는 공개 API와 클라이언트 키만 사용

import 'package:gonggoo_app/core/config/payment_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_enums.dart';
import '../models/payment_info_model.dart';
import '../models/payment_error_model.dart';

import '../../../core/utils/retry_helper.dart';

/// TossPayments 서비스 Provider
final tossPaymentsServiceProvider = Provider<TossPaymentsService>((ref) {
  return TossPaymentsService();
});

/// 🔒 TossPayments 서비스 (보안 강화됨)
///
/// 시크릿 키는 Firebase Cloud Functions에서만 관리하여 클라이언트 노출 방지
/// 모든 결제 승인은 서버 사이드에서 처리
class TossPaymentsService {
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// 의존성 주입을 지원하는 생성자
  TossPaymentsService({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// 🎯 결제 승인 (Cloud Functions 통해 처리)
  ///
  /// 보안: 시크릿 키가 필요한 결제 승인 API는 서버에서만 호출
  /// 재시도: 네트워크 오류 시 자동 재시도 적용
  Future<PaymentInfo> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    final stopwatch = Stopwatch()..start();
    int attempts = 0;

    try {
      return await (() async {
        attempts++;

        final user = _auth.currentUser;
        if (user == null) {
          throw PaymentError(
            code: 'AUTHENTICATION_REQUIRED',
            message: '사용자 인증이 필요합니다.',
            context: {'operation': 'confirmPayment'},
          );
        }

        final callable = _functions.httpsCallable('confirmPayment');
        final result = await callable.call({
          'paymentKey': paymentKey,
          'orderId': orderId,
          'amount': amount,
        });

        final data = result.data;
        if (data['success'] != true) {
          final errorCode =
              data['error']?['code'] ?? 'PAYMENT_CONFIRMATION_FAILED';
          final errorMessage = data['error']?['message'] ?? '결제 승인에 실패했습니다.';

          throw PaymentError(
            code: errorCode,
            message: errorMessage,
            context: {
              'operation': 'confirmPayment',
              'paymentKey': paymentKey,
              'orderId': orderId,
              'amount': amount,
            },
          );
        }

        // 타입 안전 캐스팅을 통해 Cloud Functions 응답 처리
        // 중첩된 Map 객체들을 재귀적으로 변환
        final convertedData = _convertToSerializableMap(data);
        final paymentData = convertedData['payment'] as Map<String, dynamic>;
        debugPrint('✅ 결제 승인 성공: ${paymentData['paymentKey']}');

        // 🔍 세금 정보가 응답에 포함되어 있는지 확인
        if (paymentData.containsKey('suppliedAmount') ||
            paymentData.containsKey('vat') ||
            paymentData.containsKey('taxFreeAmount')) {
          debugPrint(
              '💸 토스페이먼츠 응답에 포함된 세금 정보: suppliedAmount=${paymentData['suppliedAmount']}, vat=${paymentData['vat']}, taxFreeAmount=${paymentData['taxFreeAmount']}');
        } else {
          debugPrint('⚠️ 토스페이먼츠 응답에 세금 정보 없음');
        }

        return PaymentInfo.fromJson(paymentData);
      }).retry(RetryConfig.payment.copyWith(
        onRetry: (attempt, error) {
          debugPrint('🔄 결제 승인 재시도 중... (시도: $attempt, 오류: $error)');

          // PaymentError인 경우 로깅
          if (error is PaymentError) {
            error.log(userId: _auth.currentUser?.uid);
          }
        },
        shouldRetry: (error) {
          // PaymentError의 경우 자동 재시도 가능 여부 확인
          if (error is PaymentError) {
            return error.isAutoRetryable;
          }

          // FirebaseFunctionsException의 경우 코드별 판단
          if (error is FirebaseFunctionsException) {
            switch (error.code) {
              case 'unavailable':
              case 'deadline-exceeded':
              case 'resource-exhausted':
                return true;
              case 'unauthenticated':
              case 'invalid-argument':
              case 'failed-precondition':
                return false;
              default:
                return true;
            }
          }

          return RetryHelper.defaultShouldRetry(error);
        },
      ));
    } on FirebaseFunctionsException catch (e) {
      final paymentError =
          _handleFirebaseFunctionsException(e, 'confirmPayment');
      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } catch (e) {
      if (e is PaymentError) {
        e.log(userId: _auth.currentUser?.uid);
        rethrow;
      }

      final paymentError = PaymentError(
        code: 'PAYMENT_CONFIRMATION_FAILED',
        message: '결제 승인에 실패했습니다: $e',
        context: {
          'operation': 'confirmPayment',
          'originalError': e.toString(),
        },
      );

      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } finally {
      stopwatch.stop();
      RetryHelper.logRetryStats(
        operation: 'confirmPayment',
        totalAttempts: attempts,
        totalDuration: stopwatch.elapsed,
        success: true,
      );
    }
  }

  /// 🔍 결제 정보 조회 (Cloud Functions 통해 처리)
  ///
  /// 보안: 시크릿 키가 필요한 API는 서버에서만 호출
  /// 재시도: 네트워크 오류 시 자동 재시도 적용
  Future<PaymentInfo> getPayment(String paymentKey) async {
    final stopwatch = Stopwatch()..start();
    int attempts = 0;

    try {
      return await (() async {
        attempts++;

        final user = _auth.currentUser;
        if (user == null) {
          throw PaymentError(
            code: 'AUTHENTICATION_REQUIRED',
            message: '사용자 인증이 필요합니다.',
            context: {'operation': 'getPayment'},
          );
        }

        final callable = _functions.httpsCallable('getPayment');
        final result = await callable.call({
          'paymentKey': paymentKey,
        });

        final data = result.data;
        if (data['success'] != true) {
          final errorCode = data['error']?['code'] ?? 'PAYMENT_QUERY_FAILED';
          final errorMessage = data['error']?['message'] ?? '결제 정보 조회에 실패했습니다.';

          throw PaymentError(
            code: errorCode,
            message: errorMessage,
            context: {
              'operation': 'getPayment',
              'paymentKey': paymentKey,
            },
          );
        }

        // 타입 안전 캐스팅을 통해 Cloud Functions 응답 처리
        // 중첩된 Map 객체들을 재귀적으로 변환
        final convertedData = _convertToSerializableMap(data);
        return PaymentInfo.fromJson(
            convertedData['payment'] as Map<String, dynamic>);
      }).retry(RetryConfig.network.copyWith(
        onRetry: (attempt, error) {
          debugPrint('🔄 결제 정보 조회 재시도 중... (시도: $attempt, 오류: $error)');

          if (error is PaymentError) {
            error.log(userId: _auth.currentUser?.uid);
          }
        },
      ));
    } on FirebaseFunctionsException catch (e) {
      final paymentError = _handleFirebaseFunctionsException(e, 'getPayment');
      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } catch (e) {
      if (e is PaymentError) {
        e.log(userId: _auth.currentUser?.uid);
        rethrow;
      }

      final paymentError = PaymentError(
        code: 'NETWORK_ERROR',
        message: '네트워크 오류가 발생했습니다: $e',
        context: {
          'operation': 'getPayment',
          'originalError': e.toString(),
        },
      );

      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } finally {
      stopwatch.stop();
      RetryHelper.logRetryStats(
        operation: 'getPayment',
        totalAttempts: attempts,
        totalDuration: stopwatch.elapsed,
        success: true,
      );
    }
  }

  /// ❌ 결제 취소 (Cloud Functions 통해 처리)
  ///
  /// 보안: 시크릿 키가 필요한 결제 취소는 서버에서만 처리
  /// 재시도: 일시적 오류 시에만 재시도 (중복 취소 방지)
  Future<Map<String, dynamic>> cancelPayment({
    required String paymentKey,
    required String cancelReason,
    int? cancelAmount,
  }) async {
    final stopwatch = Stopwatch()..start();
    int attempts = 0;

    try {
      return await (() async {
        attempts++;

        final user = _auth.currentUser;
        if (user == null) {
          throw PaymentError(
            code: 'AUTHENTICATION_REQUIRED',
            message: '사용자 인증이 필요합니다.',
            context: {'operation': 'cancelPayment'},
          );
        }

        final HttpsCallable callable =
            _functions.httpsCallable('cancelPayment');
        final HttpsCallableResult result = await callable.call({
          'paymentKey': paymentKey,
          'cancelReason': cancelReason,
          'cancelAmount': cancelAmount,
        });

        return result.data as Map<String, dynamic>;
      }).retry(RetryConfig(
        maxRetries: 1, // 결제 취소는 중복 방지를 위해 재시도 최소화
        initialDelay: Duration(seconds: 2),
        shouldRetry: (error) {
          // 결제 취소는 매우 제한적으로만 재시도
          if (error is FirebaseFunctionsException) {
            switch (error.code) {
              case 'unavailable':
              case 'deadline-exceeded':
                return true;
              default:
                return false;
            }
          }
          return false;
        },
        onRetry: (attempt, error) {
          debugPrint('🔄 결제 취소 재시도 중... (시도: $attempt, 오류: $error)');

          if (error is PaymentError) {
            error.log(userId: _auth.currentUser?.uid);
          }
        },
      ));
    } on FirebaseFunctionsException catch (e) {
      final paymentError =
          _handleFirebaseFunctionsException(e, 'cancelPayment');
      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } catch (e) {
      final paymentError = PaymentError(
        code: 'PAYMENT_CANCEL_FAILED',
        message: 'Payment cancellation failed: $e',
        context: {
          'operation': 'cancelPayment',
          'originalError': e.toString(),
        },
      );

      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } finally {
      stopwatch.stop();
      RetryHelper.logRetryStats(
        operation: 'cancelPayment',
        totalAttempts: attempts,
        totalDuration: stopwatch.elapsed,
        success: true,
      );
    }
  }

  /// 💰 결제 환불 (Cloud Functions 통해 처리)
  ///
  /// 보안: 시크릿 키가 필요한 환불 API는 서버에서만 처리
  /// 기능: 전액/부분 환불, 가상계좌 환불 지원, 멱등키를 통한 중복 환불 방지
  Future<Map<String, dynamic>> refundPayment({
    required String paymentKey,
    required String cancelReason,
    int? cancelAmount,
    Map<String, dynamic>? refundReceiveAccount,
    String? idempotencyKey,
  }) async {
    final stopwatch = Stopwatch()..start();
    int attempts = 0;

    try {
      return await (() async {
        attempts++;

        final user = _auth.currentUser;
        if (user == null) {
          throw PaymentError(
            code: 'AUTHENTICATION_REQUIRED',
            message: '사용자 인증이 필요합니다.',
            context: {'operation': 'refundPayment'},
          );
        }

        final callable = _functions.httpsCallable('refundPayment');
        final Map<String, dynamic> requestData = {
          'paymentKey': paymentKey,
          'cancelReason': cancelReason,
        };

        // 부분 환불인 경우 금액 추가
        if (cancelAmount != null) {
          requestData['cancelAmount'] = cancelAmount;
        }

        // 가상계좌 환불인 경우 계좌 정보 추가
        if (refundReceiveAccount != null) {
          requestData['refundReceiveAccount'] = refundReceiveAccount;
        }

        // 멱등키가 있는 경우 추가 (중복 환불 방지)
        if (idempotencyKey != null) {
          requestData['idempotencyKey'] = idempotencyKey;
        }

        final result = await callable.call(requestData);

        final data = result.data;
        if (data['success'] != true) {
          final errorCode = data['error']?['code'] ?? 'REFUND_FAILED';
          final errorMessage = data['error']?['message'] ?? '환불 처리에 실패했습니다.';

          throw PaymentError(
            code: errorCode,
            message: errorMessage,
            context: {
              'operation': 'refundPayment',
              'paymentKey': paymentKey,
              'cancelAmount': cancelAmount,
            },
          );
        }

        debugPrint('✅ 환불 처리 성공: ${paymentKey}');
        return data;
      }).retry(RetryConfig(
        maxRetries: 1, // 환불은 중복 방지를 위해 재시도 최소화
        initialDelay: Duration(seconds: 2),
        shouldRetry: (error) {
          // 환불은 매우 제한적으로만 재시도
          if (error is FirebaseFunctionsException) {
            switch (error.code) {
              case 'unavailable':
              case 'deadline-exceeded':
                return true;
              default:
                return false;
            }
          }
          return false;
        },
        onRetry: (attempt, error) {
          debugPrint('🔄 환불 처리 재시도 중... (시도: $attempt, 오류: $error)');

          if (error is PaymentError) {
            error.log(userId: _auth.currentUser?.uid);
          }
        },
      ));
    } on FirebaseFunctionsException catch (e) {
      final paymentError =
          _handleFirebaseFunctionsException(e, 'refundPayment');
      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } catch (e) {
      if (e is PaymentError) {
        e.log(userId: _auth.currentUser?.uid);
        rethrow;
      }

      final paymentError = PaymentError(
        code: 'REFUND_FAILED',
        message: '환불 처리에 실패했습니다: $e',
        context: {
          'operation': 'refundPayment',
          'originalError': e.toString(),
        },
      );

      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } finally {
      stopwatch.stop();
      RetryHelper.logRetryStats(
        operation: 'refundPayment',
        totalAttempts: attempts,
        totalDuration: stopwatch.elapsed,
        success: true,
      );
    }
  }

  /// 📋 환불 내역 조회 (Cloud Functions 통해 처리)
  ///
  /// 사용자의 환불 내역을 페이지네이션으로 조회합니다.
  Future<Map<String, dynamic>> getUserRefunds({
    int limit = 20,
    dynamic startAfter,
  }) async {
    final stopwatch = Stopwatch()..start();
    int attempts = 0;

    try {
      return await (() async {
        attempts++;

        final user = _auth.currentUser;
        if (user == null) {
          throw PaymentError(
            code: 'AUTHENTICATION_REQUIRED',
            message: '사용자 인증이 필요합니다.',
            context: {'operation': 'getUserRefunds'},
          );
        }

        final callable = _functions.httpsCallable('getUserRefunds');
        final requestData = {
          'limit': limit,
        };

        if (startAfter != null) {
          requestData['startAfter'] = startAfter;
        }

        final result = await callable.call(requestData);

        final data = result.data;
        if (data['success'] != true) {
          final errorCode = data['error']?['code'] ?? 'REFUND_QUERY_FAILED';
          final errorMessage = data['error']?['message'] ?? '환불 내역 조회에 실패했습니다.';

          throw PaymentError(
            code: errorCode,
            message: errorMessage,
            context: {
              'operation': 'getUserRefunds',
              'limit': limit,
            },
          );
        }

        debugPrint('✅ 환불 내역 조회 성공: ${data['refunds']?.length ?? 0}건');
        return data;
      }).retry(RetryConfig.network.copyWith(
        onRetry: (attempt, error) {
          debugPrint('🔄 환불 내역 조회 재시도 중... (시도: $attempt, 오류: $error)');

          if (error is PaymentError) {
            error.log(userId: _auth.currentUser?.uid);
          }
        },
      ));
    } on FirebaseFunctionsException catch (e) {
      final paymentError =
          _handleFirebaseFunctionsException(e, 'getUserRefunds');
      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } catch (e) {
      if (e is PaymentError) {
        e.log(userId: _auth.currentUser?.uid);
        rethrow;
      }

      final paymentError = PaymentError(
        code: 'NETWORK_ERROR',
        message: '네트워크 오류가 발생했습니다: $e',
        context: {
          'operation': 'getUserRefunds',
          'originalError': e.toString(),
        },
      );

      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } finally {
      stopwatch.stop();
      RetryHelper.logRetryStats(
        operation: 'getUserRefunds',
        totalAttempts: attempts,
        totalDuration: stopwatch.elapsed,
        success: true,
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

  /// 📊 결제 통계 조회 (Cloud Functions 통해 처리)
  ///
  /// 보안: 관리자용 API는 서버에서만 호출
  Future<Map<String, dynamic>> getPaymentStats({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw TossPaymentsException(
          code: 'AUTHENTICATION_REQUIRED',
          message: '사용자 인증이 필요합니다.',
          userFriendlyMessage: '로그인 후 다시 시도해주세요.',
        );
      }

      final callable = _functions.httpsCallable('getPaymentStats');
      final result = await callable.call({
        'startDate': from.toIso8601String().split('T')[0],
        'endDate': to.toIso8601String().split('T')[0],
      });

      final data = result.data;
      if (data['success'] != true) {
        throw TossPaymentsException(
          code: 'API_ERROR',
          message: '결제 통계 조회에 실패했습니다.',
          userFriendlyMessage: '통계 정보를 가져올 수 없습니다. 잠시 후 다시 시도해주세요.',
        );
      }

      return data['stats'] as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      throw TossPaymentsException(
        code: e.code,
        message: e.message ?? '결제 통계 조회에 실패했습니다.',
        userFriendlyMessage: '통계 정보를 가져올 수 없습니다. 잠시 후 다시 시도해주세요.',
      );
    } catch (e) {
      throw TossPaymentsException(
        code: 'NETWORK_ERROR',
        message: '네트워크 오류가 발생했습니다: $e',
        userFriendlyMessage: '네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.',
      );
    }
  }

  /// 🎫 빌링키 발급 (Cloud Functions 통해 처리)
  ///
  /// 보안: 카드 정보와 시크릿 키가 필요한 API는 서버에서만 처리
  /// 재시도: 네트워크 오류 시 자동 재시도 적용
  Future<Map<String, dynamic>> issueBillingKey({
    required String customerKey,
    required String cardNumber,
    required String cardExpirationYear,
    required String cardExpirationMonth,
    required String cardPassword,
    required String customerBirth,
    String? customerName,
  }) async {
    final stopwatch = Stopwatch()..start();
    int attempts = 0;

    try {
      return await (() async {
        attempts++;

        final user = _auth.currentUser;
        if (user == null) {
          throw PaymentError(
            code: 'AUTHENTICATION_REQUIRED',
            message: '사용자 인증이 필요합니다.',
            context: {'operation': 'issueBillingKey'},
          );
        }

        final callable = _functions.httpsCallable('issueBillingKey');
        final result = await callable.call({
          'customerKey': customerKey,
          'cardNumber': cardNumber,
          'cardExpirationYear': cardExpirationYear,
          'cardExpirationMonth': cardExpirationMonth,
          'cardPassword': cardPassword,
          'customerBirth': customerBirth,
          'customerName': customerName,
        });

        final data = result.data;
        if (data['success'] != true) {
          final errorCode =
              data['error']?['code'] ?? 'BILLING_KEY_ISSUE_FAILED';
          final errorMessage = data['error']?['message'] ?? '빌링키 발급에 실패했습니다.';

          throw PaymentError(
            code: errorCode,
            message: errorMessage,
            context: {
              'operation': 'issueBillingKey',
              'customerKey': customerKey,
            },
          );
        }

        return data['billingKey'] as Map<String, dynamic>;
      }).retry(RetryConfig.payment.copyWith(
        onRetry: (attempt, error) {
          debugPrint('🔄 빌링키 발급 재시도 중... (시도: $attempt, 오류: $error)');

          if (error is PaymentError) {
            error.log(userId: _auth.currentUser?.uid);
          }
        },
      ));
    } on FirebaseFunctionsException catch (e) {
      final paymentError =
          _handleFirebaseFunctionsException(e, 'issueBillingKey');
      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } catch (e) {
      final paymentError = PaymentError(
        code: 'NETWORK_ERROR',
        message: '네트워크 오류가 발생했습니다: $e',
        context: {
          'operation': 'issueBillingKey',
          'originalError': e.toString(),
        },
      );

      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } finally {
      stopwatch.stop();
      RetryHelper.logRetryStats(
        operation: 'issueBillingKey',
        totalAttempts: attempts,
        totalDuration: stopwatch.elapsed,
        success: true,
      );
    }
  }

  /// 🔄 빌링키로 결제 (Cloud Functions 통해 처리)
  ///
  /// 보안: 빌링키와 시크릿 키가 필요한 API는 서버에서만 처리
  Future<PaymentInfo> chargeWithBillingKey({
    required String billingKey,
    required String customerKey,
    required int amount,
    required String orderId,
    required String orderName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw TossPaymentsException(
          code: 'AUTHENTICATION_REQUIRED',
          message: '사용자 인증이 필요합니다.',
          userFriendlyMessage: '로그인 후 다시 시도해주세요.',
        );
      }

      final callable = _functions.httpsCallable('chargeWithBillingKey');
      final result = await callable.call({
        'billingKey': billingKey,
        'customerKey': customerKey,
        'amount': amount,
        'orderId': orderId,
        'orderName': orderName,
      });

      final data = result.data;
      if (data['success'] != true) {
        throw TossPaymentsException(
          code: data['error']['code'] ?? 'UNKNOWN_ERROR',
          message: data['error']['message'] ?? '빌링 결제에 실패했습니다.',
          userFriendlyMessage: '자동결제 처리에 실패했습니다. 등록된 카드를 확인해주세요.',
        );
      }

      return PaymentInfo.fromJson(data['payment']);
    } on FirebaseFunctionsException catch (e) {
      throw TossPaymentsException(
        code: e.code,
        message: e.message ?? '빌링 결제에 실패했습니다.',
        userFriendlyMessage: '자동결제 처리에 실패했습니다. 등록된 카드를 확인해주세요.',
      );
    } catch (e) {
      if (e is TossPaymentsException) rethrow;
      throw TossPaymentsException(
        code: 'NETWORK_ERROR',
        message: '네트워크 오류가 발생했습니다: $e',
        userFriendlyMessage: '네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.',
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
      throw TossPaymentsException(
        code: 'INVALID_ENVIRONMENT',
        message: '테스트 결제는 개발 모드에서만 사용 가능합니다.',
        userFriendlyMessage: '테스트 결제는 개발 환경에서만 사용할 수 있습니다.',
      );
    }

    // 테스트용 결제 정보 생성
    return PaymentInfo(
      paymentKey:
          '${PaymentConfig.paymentInfo['paymentKeyPrefix']}${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      status: PaymentStatus.done,
      totalAmount: amount,
      balanceAmount: amount,
      suppliedAmount: (amount * 0.91).round(), // VAT 9% 제외
      vat: (amount * 0.09).round(),
      taxFreeAmount: 0,
      orderName: orderName,
      mId: PaymentConfig.paymentInfo['mId'],
      version: PaymentConfig.paymentInfo['version'],
      method: PaymentMethod.card,
      requestedAt: DateTime.now().subtract(Duration(minutes: 1)),
      approvedAt: DateTime.now(),
      country: PaymentConfig.paymentInfo['country'],
      receiptUrl: PaymentConfig.paymentInfo['receiptUrl'],
    );
  }

  /// 📱 결제 위젯 초기화 데이터 생성
  ///
  /// 클라이언트 키만 사용하여 안전한 결제 위젯 초기화
  /// 웹에서는 독립 결제 페이지 URL 반환
  Map<String, dynamic> getPaymentWidgetConfig({
    required String orderId,
    required int amount,
    required String orderName,
    String? customerEmail,
    String? customerName,
    int? suppliedAmount,
    int? vat,
    int? taxFreeAmount,
  }) {
    final clientKey = PaymentConfig.tossClientKey;

    final config = {
      'clientKey': clientKey,
      'orderId': orderId,
      'amount': amount,
      'orderName': orderName,
      'customerEmail': customerEmail,
      'customerName': customerName,
      'successUrl': PaymentConfig.successUrl,
      'failUrl': PaymentConfig.failUrl,
      'flowMode': PaymentConfig.paymentWidgetConfig['flowMode'],
      'easyPay': PaymentConfig.paymentWidgetConfig['easyPay'],
    };

    // 웹 환경에서는 독립 결제 페이지 URL 생성
    if (kIsWeb) {
      // dart:html은 kIsWeb에서만 import 가능 (최상단 import X)
      String origin = '';
      try {
        // ignore: avoid_web_libraries_in_flutter
        // ignore: undefined_prefixed_name
        origin = (Uri.base.origin);
      } catch (_) {
        origin = '';
      }
      final params = <String, String>{
        'clientKey': config['clientKey'] as String,
        'orderId': config['orderId'] as String,
        'amount': config['amount'].toString(),
        'orderName': config['orderName'] as String,
        'successUrl': origin + (config['successUrl'] as String),
        'failUrl': origin + (config['failUrl'] as String),
      };

      if (customerEmail != null) params['customerEmail'] = customerEmail;
      if (customerName != null) params['customerName'] = customerName;

      // 🆕 세금 정보 추가
      if (suppliedAmount != null)
        params['suppliedAmount'] = suppliedAmount.toString();
      if (vat != null) params['vat'] = vat.toString();
      if (taxFreeAmount != null)
        params['taxFreeAmount'] = taxFreeAmount.toString();

      final queryString = params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // 독립 결제 페이지 URL
      final paymentPageUrl = '/payment.html?$queryString';

      return {
        ...config,
        'paymentUrl': paymentPageUrl,
        'isWeb': true,
      };
    }

    // 모바일 환경에서는 기존 위젯 설정 반환
    return {
      ...config,
      'isWeb': false,
    };
  }

  /// 웹훅 서명 검증
  Future<bool> verifyWebhookSignature({
    required String payload,
    required String signature,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('verifyPaymentWebhook');
      final result = await callable.call({
        'payload': payload,
        'signature': signature,
      });

      return result.data['isValid'] == true;
    } catch (e) {
      debugPrint('웹훅 서명 검증 실패: $e');
      return false;
    }
  }

  /// 🔧 Cloud Functions 응답을 안전하게 타입 변환
  ///
  /// _Map<Object?, Object?>를 Map<String, dynamic>으로 재귀적으로 변환합니다.
  /// TossPayments API 응답의 중첩된 객체들을 안전하게 처리합니다.
  dynamic _convertToSerializableMap(dynamic data) {
    if (data is Map) {
      // Map을 Map<String, dynamic>으로 변환
      final Map<String, dynamic> result = {};
      data.forEach((key, value) {
        result[key.toString()] = _convertToSerializableMap(value);
      });
      return result;
    } else if (data is List) {
      // List 내부의 각 요소도 재귀적으로 변환
      return data.map((item) => _convertToSerializableMap(item)).toList();
    } else {
      // 기본 타입은 그대로 반환
      return data;
    }
  }

  /// Firebase Functions 예외를 PaymentError로 변환
  PaymentError _handleFirebaseFunctionsException(
    FirebaseFunctionsException e,
    String operation,
  ) {
    String code;
    String message;

    switch (e.code) {
      case 'unauthenticated':
        code = 'AUTHENTICATION_REQUIRED';
        message = '사용자 인증이 필요합니다.';
        break;
      case 'invalid-argument':
        code = 'INVALID_PARAMETER';
        message = '잘못된 결제 정보입니다.';
        break;
      case 'failed-precondition':
        code = 'PAYMENT_API_ERROR';
        message = e.message ?? '결제 처리 중 문제가 발생했습니다.';
        break;
      case 'unavailable':
        code = 'SERVICE_UNAVAILABLE';
        message = '서비스가 일시적으로 중단되었습니다.';
        break;
      case 'deadline-exceeded':
        code = 'TIMEOUT';
        message = '요청 시간이 초과되었습니다.';
        break;
      case 'resource-exhausted':
        code = 'SERVER_OVERLOAD';
        message = '서버가 과부하 상태입니다.';
        break;
      default:
        code = 'UNKNOWN_ERROR';
        message = e.message ?? '알 수 없는 오류가 발생했습니다.';
        break;
    }

    return PaymentError(
      code: code,
      message: message,
      details: e.details?.toString(),
      context: {
        'operation': operation,
        'firebaseCode': e.code,
        'firebaseMessage': e.message,
      },
    );
  }

  /// 💡 환불 가능 여부 확인
  ///
  /// 결제수단별 환불 기한과 현재 상태를 확인하여 환불 가능 여부를 판단합니다.
  Future<bool> canRefund(PaymentInfo paymentInfo) async {
    try {
      // 이미 취소된 결제는 환불 불가
      if (paymentInfo.status == PaymentStatus.canceled ||
          paymentInfo.status == PaymentStatus.partialCanceled) {
        return false;
      }

      // 승인된 결제만 환불 가능
      if (paymentInfo.status != PaymentStatus.done) {
        return false;
      }

      final now = DateTime.now();
      final approvedAt = paymentInfo.approvedAt;

      if (approvedAt == null) {
        return false;
      }

      final daysSincePayment = now.difference(approvedAt).inDays;

      // 결제수단별 환불 기한 확인
      switch (paymentInfo.method) {
        case PaymentMethod.card:
          // 카드: 일반적으로 1년 이내 (365일)
          return daysSincePayment <= PaymentConfig.refundPeriods['CARD']!;

        case PaymentMethod.transfer:
          // 계좌이체: 180일 이내
          return daysSincePayment <= PaymentConfig.refundPeriods['TRANSFER']!;

        case PaymentMethod.virtualAccount:
          // 가상계좌: 365일 이내
          return daysSincePayment <=
              PaymentConfig.refundPeriods['VIRTUAL_ACCOUNT']!;

        case PaymentMethod.mobilePhone:
          // 휴대폰: 당월에만 취소 가능
          final paymentMonth = DateTime(approvedAt.year, approvedAt.month);
          final currentMonth = DateTime(now.year, now.month);
          return paymentMonth.isAtSameMomentAs(currentMonth);

        case PaymentMethod.giftCertificate:
          // 상품권: 1년 이내
          return daysSincePayment <=
              PaymentConfig.refundPeriods['GIFT_CERTIFICATE']!;

        default:
          // 기타 결제수단: 기본 180일
          return daysSincePayment <= PaymentConfig.refundPeriods['ETC']!;
      }
    } catch (e) {
      debugPrint('환불 가능 여부 확인 실패: $e');
      return false;
    }
  }

  /// 💡 환불 불가 사유 반환
  ///
  /// 환불이 불가능한 경우 그 이유를 사용자 친화적인 메시지로 반환합니다.
  Future<String?> getRefundDenialReason(PaymentInfo paymentInfo) async {
    try {
      // 이미 취소된 결제
      if (paymentInfo.status == PaymentStatus.canceled) {
        return '이미 전액 환불된 결제입니다.';
      }

      if (paymentInfo.status == PaymentStatus.partialCanceled) {
        return '이미 부분 환불된 결제입니다.';
      }

      // 승인되지 않은 결제
      if (paymentInfo.status != PaymentStatus.done) {
        return '승인되지 않은 결제는 환불할 수 없습니다.';
      }

      final now = DateTime.now();
      final approvedAt = paymentInfo.approvedAt;

      if (approvedAt == null) {
        return '결제 승인 정보를 찾을 수 없습니다.';
      }

      final daysSincePayment = now.difference(approvedAt).inDays;

      // 결제수단별 환불 기한 확인
      switch (paymentInfo.method) {
        case PaymentMethod.card:
          if (daysSincePayment > PaymentConfig.refundPeriods['CARD']!) {
            return '카드 결제는 결제일로부터 1년 이내에만 환불 가능합니다.';
          }
          break;

        case PaymentMethod.transfer:
          if (daysSincePayment > PaymentConfig.refundPeriods['TRANSFER']!) {
            return '계좌이체는 결제일로부터 180일 이내에만 환불 가능합니다.';
          }
          break;

        case PaymentMethod.virtualAccount:
          if (daysSincePayment >
              PaymentConfig.refundPeriods['VIRTUAL_ACCOUNT']!) {
            return '가상계좌 결제는 결제일로부터 365일 이내에만 환불 가능합니다.';
          }
          break;

        case PaymentMethod.mobilePhone:
          final paymentMonth = DateTime(approvedAt.year, approvedAt.month);
          final currentMonth = DateTime(now.year, now.month);
          if (!paymentMonth.isAtSameMomentAs(currentMonth)) {
            return '휴대폰 결제는 결제한 당월에만 환불 가능합니다.';
          }
          break;

        case PaymentMethod.giftCertificate:
          if (daysSincePayment >
              PaymentConfig.refundPeriods['GIFT_CERTIFICATE']!) {
            return '상품권 결제는 결제일로부터 1년 이내에만 환불 가능합니다.';
          }
          break;

        default:
          if (daysSincePayment > PaymentConfig.refundPeriods['ETC']!) {
            return '결제일로부터 180일 이내에만 환불 가능합니다.';
          }
          break;
      }

      return null; // 환불 가능
    } catch (e) {
      debugPrint('환불 불가 사유 확인 실패: $e');
      return '환불 가능 여부를 확인할 수 없습니다.';
    }
  }

  /// 🗑️ 결제 실패 시 대기 중인 주문 삭제 (Cloud Functions 통해 처리)
  ///
  /// 보안: 서버에서 주문 삭제 및 재고 복구를 처리하여 클라이언트 조작 방지
  /// 재시도: 네트워크 오류 시 자동 재시도 적용
  Future<Map<String, dynamic>> deletePendingOrderOnPaymentFailure({
    required String orderId,
    String? reason,
  }) async {
    final stopwatch = Stopwatch()..start();
    int attempts = 0;

    try {
      return await (() async {
        attempts++;

        final user = _auth.currentUser;
        if (user == null) {
          throw PaymentError(
            code: 'AUTHENTICATION_REQUIRED',
            message: '사용자 인증이 필요합니다.',
            context: {'operation': 'deletePendingOrder'},
          );
        }

        final callable =
            _functions.httpsCallable('deletePendingOrderOnPaymentFailure');
        final result = await callable.call({
          'orderId': orderId,
          'reason': reason ?? '결제 실패',
        });

        final data = result.data;
        if (data['success'] != true) {
          final errorMessage = data['message'] ?? '주문 삭제에 실패했습니다.';

          throw PaymentError(
            code: 'ORDER_DELETION_FAILED',
            message: errorMessage,
            context: {
              'operation': 'deletePendingOrder',
              'orderId': orderId,
              'reason': reason,
            },
          );
        }

        debugPrint('✅ 결제 실패 주문 삭제 성공: $orderId');
        debugPrint('📈 재고 복구 완료: ${data['deletedProductCount']}개 상품');

        return Map<String, dynamic>.from(data);
      }).retry(RetryConfig.payment.copyWith(
        onRetry: (attempt, error) {
          debugPrint('🔄 주문 삭제 재시도 중... (시도: $attempt, 오류: $error)');

          // PaymentError인 경우 로깅
          if (error is PaymentError) {
            error.log(userId: _auth.currentUser?.uid);
          }
        },
        shouldRetry: (error) {
          // PaymentError의 경우 자동 재시도 가능 여부 확인
          if (error is PaymentError) {
            return error.isAutoRetryable;
          }

          // FirebaseFunctionsException의 경우 코드별 판단
          if (error is FirebaseFunctionsException) {
            switch (error.code) {
              case 'unavailable':
              case 'deadline-exceeded':
              case 'resource-exhausted':
                return true;
              case 'unauthenticated':
              case 'invalid-argument':
              case 'permission-denied':
                return false;
              default:
                return true;
            }
          }

          return RetryHelper.defaultShouldRetry(error);
        },
      ));
    } on FirebaseFunctionsException catch (e) {
      final paymentError =
          _handleFirebaseFunctionsException(e, 'deletePendingOrder');
      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } catch (e) {
      if (e is PaymentError) {
        e.log(userId: _auth.currentUser?.uid);
        rethrow;
      }

      final paymentError = PaymentError(
        code: 'ORDER_DELETION_FAILED',
        message: '주문 삭제에 실패했습니다: $e',
        context: {
          'operation': 'deletePendingOrder',
          'originalError': e.toString(),
        },
      );

      paymentError.log(userId: _auth.currentUser?.uid);
      throw paymentError;
    } finally {
      stopwatch.stop();
      RetryHelper.logRetryStats(
        operation: 'deletePendingOrder',
        totalAttempts: attempts,
        totalDuration: stopwatch.elapsed,
        success: true,
      );
    }
  }
}

/// 🚨 Toss Payments 예외 클래스
///
/// Toss Payments API에서 발생하는 오류를 처리합니다.
class TossPaymentsException implements Exception {
  final String code;
  final String message;
  final String userFriendlyMessage;

  const TossPaymentsException({
    required this.code,
    required this.message,
    required this.userFriendlyMessage,
  });

  @override
  String toString() => 'TossPaymentsException($code): $message';

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
