import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';
import '../models/order_enums.dart';
import '../repositories/order_repository.dart';
import '../../auth/providers/auth_state.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_storage_service.dart';
import '../../../core/services/retry_service.dart';

/// 주문 내역 로딩 상태
enum OrderHistoryStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

/// 주문 내역 상태 클래스
class OrderHistoryState {
  final OrderHistoryStatus status;
  final List<OrderModel> orders;
  final String? errorMessage;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final OrderStatus? statusFilter;

  const OrderHistoryState({
    this.status = OrderHistoryStatus.initial,
    this.orders = const [],
    this.errorMessage,
    this.hasMore = true,
    this.lastDocument,
    this.statusFilter,
  });

  OrderHistoryState copyWith({
    OrderHistoryStatus? status,
    List<OrderModel>? orders,
    String? errorMessage,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    OrderStatus? statusFilter,
  }) {
    return OrderHistoryState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  /// 로딩 중인지 확인
  bool get isLoading => status == OrderHistoryStatus.loading;

  /// 더 많은 데이터 로딩 중인지 확인
  bool get isLoadingMore => status == OrderHistoryStatus.loadingMore;

  /// 에러 상태인지 확인
  bool get hasError => status == OrderHistoryStatus.error;

  /// 데이터가 있는지 확인
  bool get hasData => orders.isNotEmpty;
}

/// 주문 내역 상태 관리 Provider
class OrderHistoryNotifier extends StateNotifier<OrderHistoryState> {
  final Ref ref;

  OrderHistoryNotifier(this.ref) : super(const OrderHistoryState());

  /// 🔄 주문 내역 새로고침
  Future<void> refreshOrders() async {
    try {
      // 상태 초기화
      state = state.copyWith(
        status: OrderHistoryStatus.loading,
        orders: [],
        errorMessage: null,
        hasMore: true,
        lastDocument: null,
      );

      await _loadOrders(isRefresh: true);
    } catch (e) {
      state = state.copyWith(
        status: OrderHistoryStatus.error,
        errorMessage: e.toString(),
      );
      debugPrint('주문 내역 새로고침 실패: $e');
    }
  }

  /// 📋 주문 내역 로드 (초기 로드 또는 페이지네이션)
  Future<void> loadOrders() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    try {
      // 첫 로드인지 더 로드인지 구분
      final isFirstLoad = state.orders.isEmpty;

      state = state.copyWith(
        status: isFirstLoad
            ? OrderHistoryStatus.loading
            : OrderHistoryStatus.loadingMore,
        errorMessage: null,
      );

      await _loadOrders();
    } catch (e) {
      state = state.copyWith(
        status: OrderHistoryStatus.error,
        errorMessage: e.toString(),
      );
      debugPrint('주문 내역 로드 실패: $e');
    }
  }

  /// 🔍 상태별 필터링
  Future<void> filterByStatus(OrderStatus? statusFilter) async {
    if (state.statusFilter == statusFilter) return;

    try {
      state = state.copyWith(
        status: OrderHistoryStatus.loading,
        orders: [],
        statusFilter: statusFilter,
        hasMore: true,
        lastDocument: null,
        errorMessage: null,
      );

      await _loadOrders(isRefresh: true);
    } catch (e) {
      state = state.copyWith(
        status: OrderHistoryStatus.error,
        errorMessage: e.toString(),
      );
      debugPrint('주문 필터링 실패: $e');
    }
  }

  /// 📊 상태별 주문 개수 가져오기
  Map<OrderStatus, int> getOrderCountsByStatus() {
    final counts = <OrderStatus, int>{};

    for (final status in OrderStatus.values) {
      counts[status] =
          state.orders.where((order) => order.status == status).length;
    }

    return counts;
  }

  /// 🔄 특정 주문 상태 업데이트 (실시간 반영)
  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final updatedOrders = state.orders.map((order) {
      if (order.orderId == orderId) {
        return order.copyWith(status: newStatus);
      }
      return order;
    }).toList();

    state = state.copyWith(orders: updatedOrders);
  }

  /// 🗑️ 특정 주문 제거 (취소된 주문 등)
  void removeOrder(String orderId) {
    final filteredOrders =
        state.orders.where((order) => order.orderId != orderId).toList();

    state = state.copyWith(orders: filteredOrders);
  }

  /// 내부 메서드: 실제 데이터 로드
  Future<void> _loadOrders({bool isRefresh = false}) async {
    debugPrint('📋 _loadOrders 시작 - isRefresh: $isRefresh');

    // 현재 로그인된 사용자 확인
    final authState = ref.read(authProvider).value;
    debugPrint('📋 authState: $authState');
    debugPrint('📋 authState?.user: ${authState?.user}');
    debugPrint('📋 authState?.user?.uid: ${authState?.user?.uid}');

    if (authState?.user == null) {
      debugPrint('📋 에러: 로그인이 필요합니다.');
      throw Exception('로그인이 필요합니다.');
    }

    final userId = authState!.user!.uid;
    debugPrint('📋 현재 사용자 ID: $userId');

    final orderRepository = ref.read(orderRepositoryProvider);
    debugPrint('📋 orderRepository: $orderRepository');

    // 네트워크 연결 확인
    final isConnected = await ConnectivityService.isConnected;
    debugPrint('📋 네트워크 연결 상태: $isConnected');

    List<OrderModel> newOrders = [];
    DocumentSnapshot? newLastDoc;

    if (isConnected) {
      try {
        debugPrint('📋 온라인 모드 - 주문 내역 서버에서 로드');

        // 페이지네이션을 위한 lastDocument 설정
        DocumentSnapshot? lastDoc = isRefresh ? null : state.lastDocument;
        debugPrint('📋 lastDoc: $lastDoc');

        // 온라인: 서버에서 데이터 로드 (재시도 포함)
        debugPrint(
            '📋 getUserOrders 호출 시작 - userId: $userId, limit: 20, statusFilter: ${state.statusFilter}');

        final result = await RetryService.withRetry(
          () => orderRepository.getUserOrders(
            userId: userId,
            limit: 20,
            lastDoc: lastDoc,
            statusFilter: state.statusFilter,
          ),
          maxRetries: 3,
        );

        // OrderQueryResult에서 orders와 lastDocument 추출
        newOrders = result.orders;
        newLastDoc = result.lastDocument;

        debugPrint('📋 getUserOrders 완료 - 조회된 주문 수: ${newOrders.length}');
        debugPrint('📋 새로운 lastDocument: ${newLastDoc?.id}');

        // 조회된 주문들의 기본 정보 출력
        for (int i = 0; i < newOrders.length; i++) {
          final order = newOrders[i];
          debugPrint(
              '📋 주문 $i: ${order.orderId} - ${order.status.displayName} - ${order.totalAmount}원');
        }

        // 첫 번째 로드이거나 새로고침인 경우 캐시에 저장
        if (isRefresh || state.orders.isEmpty) {
          await OfflineStorageService.cacheOrderHistory(newOrders);
          debugPrint('📋 주문 내역 캐시 저장 완료');
        }
      } catch (e) {
        debugPrint('⚠️ 온라인 주문 내역 로드 실패, 캐시 데이터 사용: $e');

        if (isRefresh || state.orders.isEmpty) {
          // 새로고침이거나 첫 로드인 경우 캐시된 데이터 사용
          final cachedOrders =
              await OfflineStorageService.loadCachedOrderHistory();
          debugPrint('📋 캐시에서 로드된 주문 수: ${cachedOrders.length}');
          if (cachedOrders.isNotEmpty) {
            newOrders = cachedOrders;
            // 캐시 데이터 사용 시 lastDocument는 null로 설정 (페이지네이션 불가)
            newLastDoc = null;
          } else {
            // 캐시도 비어있으면 에러 상태로 설정
            state = state.copyWith(
              status: OrderHistoryStatus.error,
              errorMessage: '주문 내역을 불러올 수 없습니다. ($e)',
            );
            return;
          }
        } else {
          // 추가 로드인 경우 빈 목록 반환하고 더 이상 로드하지 않음
          newOrders = [];
          newLastDoc = null;
          state = state.copyWith(hasMore: false);
        }
      }
    } else {
      debugPrint('📋 오프라인 모드 - 캐시된 주문 내역 로드');

      if (isRefresh || state.orders.isEmpty) {
        // 오프라인: 캐시된 데이터 로드
        newOrders = await OfflineStorageService.loadCachedOrderHistory();
        debugPrint('📋 오프라인에서 캐시 로드된 주문 수: ${newOrders.length}');
        // 오프라인에서는 페이지네이션 불가
        newLastDoc = null;
      } else {
        // 오프라인에서는 추가 로드 불가
        newOrders = [];
        newLastDoc = null;
      }
    }

    // 기존 주문 목록과 병합 (새로고침이 아닌 경우)
    final List<OrderModel> allOrders =
        isRefresh ? newOrders : [...state.orders, ...newOrders];
    debugPrint('📋 최종 주문 목록 크기: ${allOrders.length}');

    // 더 가져올 데이터가 있는지 확인
    final hasMore = isConnected && newLastDoc != null && newOrders.length >= 20;
    debugPrint('📋 hasMore: $hasMore');

    state = state.copyWith(
      status: OrderHistoryStatus.loaded,
      orders: allOrders,
      hasMore: hasMore,
      lastDocument: newLastDoc,
      errorMessage: null, // 성공 시 에러 메시지 초기화
    );

    debugPrint(
        '📋 주문 내역 로드 완료: ${allOrders.length}개 (${isConnected ? "온라인" : "오프라인"})');
    debugPrint('📋 최종 state.status: ${state.status}');
    debugPrint('📋 최종 state.orders.length: ${state.orders.length}');
    debugPrint('📋 최종 state.hasData: ${state.hasData}');
    debugPrint('📋 최종 state.lastDocument: ${state.lastDocument?.id}');
  }
}

/// 주문 내역 Provider 인스턴스
final orderHistoryProvider =
    StateNotifierProvider<OrderHistoryNotifier, OrderHistoryState>((ref) {
  return OrderHistoryNotifier(ref);
});
