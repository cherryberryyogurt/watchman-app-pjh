/// Refund Repository
///
/// 전용 'refunds' 컬렉션을 위한 포괄적인 리포지토리
/// 효율적인 쿼리와 트랜잭션을 지원합니다.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/refund_model.dart';
import '../models/refunded_item_model.dart';
import '../models/order_enums.dart';
import '../models/order_model.dart';
import '../../../core/utils/tax_calculator.dart';

/// Refund Repository Provider
final refundRepositoryProvider = Provider<RefundRepository>((ref) {
  return RefundRepository(FirebaseFirestore.instance);
});

/// 🔄 환불 리포지토리
///
/// 전용 'refunds' 컬렉션 관리를 위한 데이터베이스 작업을 담당합니다.
/// 효율적인 쿼리, 트랜잭션, 인덱싱을 지원합니다.
class RefundRepository {
  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _refundsCollection;
  late final CollectionReference<Map<String, dynamic>> _ordersCollection;

  RefundRepository(this._firestore) {
    _refundsCollection = _firestore.collection('refunds');
    _ordersCollection = _firestore.collection('orders');
  }

  // ==================== CREATE ====================

  /// 💰 새 환불 요청 생성
  ///
  /// 환불 문서를 생성하고 주문 상태를 업데이트하는 트랜잭션을 실행합니다.
  Future<RefundModel> createRefundRequest({
    required String orderId,
    required String userId,
    required String userName,
    required String userContact,
    required int refundAmount,
    required int originalOrderAmount,
    required String refundReason,
    required String locationTagId,
    required String locationTagName,
    required PaymentMethod paymentMethod,
    String? paymentKey,
    RefundType type = RefundType.full,
    List<RefundedItemModel>? refundedItems,
    String? refundBankName,
    String? refundAccountNumber,
    String? refundAccountHolder,
    String? idempotencyKey,
    Map<String, dynamic>? clientInfo,
  }) async {
    try {
      // 1️⃣ 환불 모델 생성
      final refund = RefundModel.createRequest(
        orderId: orderId,
        userId: userId,
        userName: userName,
        userContact: userContact,
        locationTagId: locationTagId,
        locationTagName: locationTagName,
        refundAmount: refundAmount,
        originalOrderAmount: originalOrderAmount,
        refundReason: refundReason,
        paymentMethod: paymentMethod,
        paymentKey: paymentKey,
        type: type,
        refundedItems: refundedItems,
        refundBankName: refundBankName,
        refundAccountNumber: refundAccountNumber,
        refundAccountHolder: refundAccountHolder,
        idempotencyKey: idempotencyKey,
        clientInfo: clientInfo,
      );

      // 2️⃣ 트랜잭션으로 환불 생성 및 주문 상태 업데이트
      await _firestore.runTransaction((transaction) async {
        // 주문 문서 조회
        final orderDoc = await transaction.get(_ordersCollection.doc(orderId));
        if (!orderDoc.exists) {
          throw Exception('주문을 찾을 수 없습니다: $orderId');
        }

        // 주문 상태 확인
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final currentOrder = OrderModel.fromMap(orderData);

        // 환불 요청 가능한 상태인지 확인
        if (!_canRequestRefund(currentOrder.status)) {
          throw Exception(
              '환불 요청이 불가능한 주문 상태입니다: ${currentOrder.status.displayName}');
        }

        // 중복 환불 요청 확인
        final existingRefunds = await getRefundsByOrderId(orderId);
        final hasActiveRefund = existingRefunds.any((r) => r.isInProgress);
        if (hasActiveRefund) {
          throw Exception('이미 진행 중인 환불 요청이 있습니다');
        }

        // 🆕 환불 세금 계산 및 저장
        final refundTaxBreakdown = TaxCalculator.calculateRefundTax(
          totalRefundAmount: refund.refundAmount,
          originalTotalAmount: currentOrder.totalAmount,
          originalSuppliedAmount: currentOrder.suppliedAmount,
          originalVat: currentOrder.vat,
          originalTaxFreeAmount: currentOrder.taxFreeAmount,
          refundedItems: refund.refundedItems,
        );

        debugPrint('💸 환불 세금 계산 완료: $refundTaxBreakdown');

        // 환불 문서에 세금 정보 추가
        final refundDataWithTax = refund.toMap();
        refundDataWithTax['taxBreakdown'] =
            refundTaxBreakdown.toTossPaymentsCancelMap();

        // 환불 문서 생성
        transaction.set(
            _refundsCollection.doc(refund.refundId), refundDataWithTax);

        // 주문 상태를 refundRequested로 업데이트
        transaction.update(_ordersCollection.doc(orderId), {
          'status': OrderStatus.refundRequested.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ 환불 요청 생성 완료: ${refund.refundId}');
      });

      return refund;
    } catch (e) {
      debugPrint('❌ 환불 요청 생성 실패: $e');
      rethrow;
    }
  }

  /// 📝 환불 요청 가능한 주문 상태인지 확인
  bool _canRequestRefund(OrderStatus status) {
    return [
      OrderStatus.delivered,
      OrderStatus.pickedUp,
    ].contains(status);
  }

  // ==================== READ ====================

  /// 🔍 환불 ID로 환불 조회
  Future<RefundModel?> getRefundById(String refundId) async {
    try {
      final doc = await _refundsCollection.doc(refundId).get();
      if (!doc.exists) return null;

      return RefundModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('❌ 환불 조회 실패: $e');
      rethrow;
    }
  }

  /// 📋 사용자의 환불 목록 조회 (페이지네이션)
  Future<List<RefundModel>> getUserRefunds({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    RefundStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      Query query = _refundsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('requestedAt', descending: true);

      // 상태 필터링
      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      // 날짜 범위 필터링
      if (fromDate != null) {
        query = query.where('requestedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
      }
      if (toDate != null) {
        query = query.where('requestedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(toDate));
      }

      // 페이지네이션
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => RefundModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 사용자 환불 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 📦 주문 ID로 환불 목록 조회
  Future<List<RefundModel>> getRefundsByOrderId(String orderId) async {
    try {
      final snapshot = await _refundsCollection
          .where('orderId', isEqualTo: orderId)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RefundModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ 주문 환불 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 📊 관리자용 환불 목록 조회 (전체)
  Future<List<RefundModel>> getAdminRefunds({
    int limit = 50,
    DocumentSnapshot? startAfter,
    RefundStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchUserId,
  }) async {
    try {
      Query query = _refundsCollection.orderBy('requestedAt', descending: true);

      // 상태 필터링
      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      // 사용자 ID 검색
      if (searchUserId != null) {
        query = query.where('userId', isEqualTo: searchUserId);
      }

      // 날짜 범위 필터링
      if (fromDate != null) {
        query = query.where('requestedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
      }
      if (toDate != null) {
        query = query.where('requestedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(toDate));
      }

      // 페이지네이션
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => RefundModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ 관리자 환불 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 📈 환불 통계 조회
  Future<Map<String, dynamic>> getRefundStats({
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      Query query = _refundsCollection;

      // 사용자 필터링
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      // 날짜 범위 필터링
      if (fromDate != null) {
        query = query.where('requestedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
      }
      if (toDate != null) {
        query = query.where('requestedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(toDate));
      }

      final snapshot = await query.get();
      final refunds = snapshot.docs
          .map((doc) => RefundModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // 통계 계산
      final totalCount = refunds.length;
      final totalAmount =
          refunds.fold<int>(0, (sum, refund) => sum + refund.refundAmount);
      final completedCount =
          refunds.where((r) => r.status == RefundStatus.completed).length;
      final completedAmount = refunds
          .where((r) => r.status == RefundStatus.completed)
          .fold<int>(0, (sum, refund) => sum + refund.refundAmount);

      // 상태별 분포
      final statusDistribution = <String, int>{};
      for (final status in RefundStatus.values) {
        statusDistribution[status.value] =
            refunds.where((r) => r.status == status).length;
      }

      return {
        'totalCount': totalCount,
        'totalAmount': totalAmount,
        'completedCount': completedCount,
        'completedAmount': completedAmount,
        'completionRate': totalCount > 0 ? completedCount / totalCount : 0.0,
        'statusDistribution': statusDistribution,
        'averageAmount': totalCount > 0 ? totalAmount / totalCount : 0,
      };
    } catch (e) {
      debugPrint('❌ 환불 통계 조회 실패: $e');
      rethrow;
    }
  }

  // ==================== UPDATE ====================

  /// 🔄 환불 상태 업데이트
  Future<void> updateRefundStatus({
    required String refundId,
    required RefundStatus newStatus,
    String? adminNotes,
    String? rejectionReason,
    String? processedByAdminId,
    String? providerRefundId,
    int? actualRefundAmount,
    Map<String, dynamic>? providerResponse,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 상태별 추가 필드 업데이트
      switch (newStatus) {
        // case RefundStatus.reviewing:
        // 검토 시작 시간 기록
        // break;

        case RefundStatus.approved:
          updateData['approvedAt'] = FieldValue.serverTimestamp();
          if (processedByAdminId != null) {
            updateData['processedByAdminId'] = processedByAdminId;
          }
          break;

        case RefundStatus.processing:
          updateData['processingStartedAt'] = FieldValue.serverTimestamp();
          if (providerRefundId != null) {
            updateData['providerRefundId'] = providerRefundId;
          }
          break;

        case RefundStatus.completed:
          updateData['completedAt'] = FieldValue.serverTimestamp();
          if (actualRefundAmount != null) {
            updateData['actualRefundAmount'] = actualRefundAmount;
          }
          if (providerResponse != null) {
            updateData['providerResponse'] = providerResponse;
          }
          break;

        case RefundStatus.rejected:
          if (rejectionReason != null) {
            updateData['rejectionReason'] = rejectionReason;
          }
          if (processedByAdminId != null) {
            updateData['processedByAdminId'] = processedByAdminId;
          }
          break;

        case RefundStatus.failed:
          if (providerResponse != null) {
            updateData['providerResponse'] = providerResponse;
          }
          break;

        default:
          break;
      }

      // 관리자 메모 추가
      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }

      await _refundsCollection.doc(refundId).update(updateData);

      debugPrint('✅ 환불 상태 업데이트 완료: $refundId → ${newStatus.displayName}');
    } catch (e) {
      debugPrint('❌ 환불 상태 업데이트 실패: $e');
      rethrow;
    }
  }

  /// 🔄 환불 재시도 카운터 증가
  Future<void> incrementRetryCount({
    required String refundId,
    String? errorMessage,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'retryCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (errorMessage != null) {
        updateData['lastErrorMessage'] = errorMessage;
      }

      await _refundsCollection.doc(refundId).update(updateData);

      debugPrint('✅ 환불 재시도 카운터 증가: $refundId');
    } catch (e) {
      debugPrint('❌ 환불 재시도 카운터 증가 실패: $e');
      rethrow;
    }
  }

  /// 🔄 환불과 주문 상태 동시 업데이트 (트랜잭션)
  Future<void> updateRefundAndOrderStatus({
    required String refundId,
    required String orderId,
    required RefundStatus refundStatus,
    required OrderStatus orderStatus,
    String? adminNotes,
    String? rejectionReason,
    String? processedByAdminId,
    int? actualRefundAmount,
    Map<String, dynamic>? providerResponse,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 환불 상태 업데이트 데이터 준비
        final refundUpdateData = <String, dynamic>{
          'status': refundStatus.value,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // 상태별 추가 필드
        if (refundStatus == RefundStatus.completed) {
          refundUpdateData['completedAt'] = FieldValue.serverTimestamp();
          if (actualRefundAmount != null) {
            refundUpdateData['actualRefundAmount'] = actualRefundAmount;
          }
          if (providerResponse != null) {
            refundUpdateData['providerResponse'] = providerResponse;
          }
        }

        if (adminNotes != null) {
          refundUpdateData['adminNotes'] = adminNotes;
        }
        if (rejectionReason != null) {
          refundUpdateData['rejectionReason'] = rejectionReason;
        }
        if (processedByAdminId != null) {
          refundUpdateData['processedByAdminId'] = processedByAdminId;
        }

        // 주문 상태 업데이트 데이터 준비
        final orderUpdateData = <String, dynamic>{
          'status': orderStatus.value,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // 트랜잭션 실행
        transaction.update(_refundsCollection.doc(refundId), refundUpdateData);
        transaction.update(_ordersCollection.doc(orderId), orderUpdateData);

        debugPrint(
            '✅ 환불 및 주문 상태 동시 업데이트: $refundId → ${refundStatus.displayName}, $orderId → ${orderStatus.displayName}');
      });
    } catch (e) {
      debugPrint('❌ 환불 및 주문 상태 동시 업데이트 실패: $e');
      rethrow;
    }
  }

  // ==================== DELETE ====================

  /// 🗑️ 환불 요청 취소 (소프트 삭제)
  Future<void> cancelRefundRequest({
    required String refundId,
    required String orderId,
    String? cancelReason,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 환불을 취소 상태로 업데이트
        transaction.update(_refundsCollection.doc(refundId), {
          'status': RefundStatus.cancelled.value,
          'rejectionReason': cancelReason ?? '사용자 요청에 의한 취소',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 주문 상태를 원래 상태로 복원 (delivered 또는 pickedUp)
        // 실제 구현에서는 주문의 이전 상태를 기록하거나 비즈니스 로직에 따라 결정
        transaction.update(_ordersCollection.doc(orderId), {
          'status': OrderStatus.delivered.value, // 또는 적절한 상태
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ 환불 요청 취소 완료: $refundId');
      });
    } catch (e) {
      debugPrint('❌ 환불 요청 취소 실패: $e');
      rethrow;
    }
  }

  // ==================== SEARCH & ANALYTICS ====================

  /// 🔍 멱등키로 환불 검색 (중복 방지)
  Future<RefundModel?> getRefundByIdempotencyKey(String idempotencyKey) async {
    try {
      final snapshot = await _refundsCollection
          .where('idempotencyKey', isEqualTo: idempotencyKey)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return RefundModel.fromMap(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('❌ 멱등키로 환불 검색 실패: $e');
      rethrow;
    }
  }

  /// 📊 일별 환불 통계
  Future<List<Map<String, dynamic>>> getDailyRefundStats({
    required DateTime fromDate,
    required DateTime toDate,
    String? userId,
  }) async {
    try {
      Query query = _refundsCollection
          .where('requestedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
          .where('requestedAt', isLessThanOrEqualTo: Timestamp.fromDate(toDate))
          .orderBy('requestedAt');

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      final refunds = snapshot.docs
          .map((doc) => RefundModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // 일별 그룹화
      final dailyStats = <String, Map<String, dynamic>>{};

      for (final refund in refunds) {
        final dateKey = refund.requestedAt.toIso8601String().split('T')[0];

        if (!dailyStats.containsKey(dateKey)) {
          dailyStats[dateKey] = {
            'date': dateKey,
            'count': 0,
            'amount': 0,
            'completed': 0,
            'completedAmount': 0,
          };
        }

        dailyStats[dateKey]!['count'] = dailyStats[dateKey]!['count'] + 1;
        dailyStats[dateKey]!['amount'] =
            dailyStats[dateKey]!['amount'] + refund.refundAmount;

        if (refund.status == RefundStatus.completed) {
          dailyStats[dateKey]!['completed'] =
              dailyStats[dateKey]!['completed'] + 1;
          dailyStats[dateKey]!['completedAmount'] =
              dailyStats[dateKey]!['completedAmount'] + refund.refundAmount;
        }
      }

      return dailyStats.values.toList()
        ..sort((a, b) => a['date'].compareTo(b['date']));
    } catch (e) {
      debugPrint('❌ 일별 환불 통계 조회 실패: $e');
      rethrow;
    }
  }

  // ==================== STREAM ====================

  /// 📡 실시간 환불 목록 스트림 (사용자용)
  Stream<List<RefundModel>> watchUserRefunds({
    required String userId,
    int limit = 20,
    RefundStatus? status,
  }) {
    try {
      Query query = _refundsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('requestedAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) =>
                RefundModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint('❌ 실시간 환불 목록 스트림 실패: $e');
      rethrow;
    }
  }

  /// 📡 특정 환불 실시간 감시
  Stream<RefundModel?> watchRefund(String refundId) {
    try {
      return _refundsCollection.doc(refundId).snapshots().map((doc) {
        if (!doc.exists) return null;
        return RefundModel.fromMap(doc.data()!);
      });
    } catch (e) {
      debugPrint('❌ 환불 실시간 감시 실패: $e');
      rethrow;
    }
  }
}
