import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/index.dart';
import '../providers/order_history_state.dart';
import '../models/order_model.dart';
import '../models/order_enums.dart';
import '../widgets/order_list_item.dart';
import '../widgets/order_status_filter.dart';

/// 주문 내역 화면
class OrderHistoryScreen extends ConsumerStatefulWidget {
  static const String routeName = '/order-history';

  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 화면 진입 시 주문 내역 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderHistoryProvider.notifier).loadOrders();
    });

    // 무한 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 스크롤 이벤트 처리 (무한 스크롤)
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 하단 200px 지점에서 추가 로드
      ref.read(orderHistoryProvider.notifier).loadOrders();
    }
  }

  /// 새로고침
  Future<void> _onRefresh() async {
    await ref.read(orderHistoryProvider.notifier).refreshOrders();
  }

  /// 상태 필터 변경
  void _onFilterChanged(OrderStatus? status) {
    ref.read(orderHistoryProvider.notifier).filterByStatus(status);
  }

  /// 주문 상세 화면으로 이동
  void _navigateToOrderDetail(OrderModel order) {
    Navigator.pushNamed(
      context,
      '/order-detail',
      arguments: {'orderId': order.orderId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderHistoryState = ref.watch(orderHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 내역'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Column(
        children: [
          // 상태별 필터 탭
          OrderStatusFilter(
            currentFilter: orderHistoryState.statusFilter,
            onFilterChanged: _onFilterChanged,
            orderCounts: ref
                .read(orderHistoryProvider.notifier)
                .getOrderCountsByStatus(),
          ),

          // 주문 목록
          Expanded(
            child: _buildOrderList(orderHistoryState),
          ),
        ],
      ),
    );
  }

  /// 주문 목록 위젯
  Widget _buildOrderList(OrderHistoryState state) {
    // 로딩 상태 (첫 로드)
    if (state.isLoading && !state.hasData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 에러 상태
    if (state.hasError && !state.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ColorPalette.error,
            ),
            const SizedBox(height: Dimensions.spacingMd),
            Text(
              '주문 내역을 불러올 수 없습니다',
              style: TextStyles.titleMedium,
            ),
            const SizedBox(height: Dimensions.spacingSm),
            Text(
              state.errorMessage ?? '알 수 없는 오류가 발생했습니다',
              style: TextStyles.bodyMedium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? ColorPalette.textSecondaryDark
                    : ColorPalette.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.spacingLg),
            ElevatedButton(
              onPressed: () =>
                  ref.read(orderHistoryProvider.notifier).refreshOrders(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 빈 상태
    if (!state.hasData && !state.isLoading) {
      return _buildEmptyState(state.statusFilter);
    }

    // 주문 목록 표시
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.padding),
        itemCount: state.orders.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // 로딩 인디케이터 (더 로드할 데이터가 있는 경우)
          if (index == state.orders.length) {
            return const Padding(
              padding: EdgeInsets.all(Dimensions.padding),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final order = state.orders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.spacingMd),
            child: OrderListItem(
              order: order,
              onTap: () => _navigateToOrderDetail(order),
            ),
          );
        },
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState(OrderStatus? currentFilter) {
    String title;
    String subtitle;
    IconData icon;

    switch (currentFilter) {
      case OrderStatus.pending:
        title = '결제 대기 중인 주문이 없습니다';
        subtitle = '새로운 주문을 해보세요!';
        icon = Icons.payment;
        break;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        title = '준비 중인 주문이 없습니다';
        subtitle = '현재 처리되고 있는 주문이 없습니다';
        icon = Icons.inventory;
        break;
      case OrderStatus.shipped:
      case OrderStatus.delivered:
        title = '배송 관련 주문이 없습니다';
        subtitle = '배송 중이거나 완료된 주문이 없습니다';
        icon = Icons.local_shipping;
        break;
      case OrderStatus.readyForPickup:
      case OrderStatus.pickedUp:
        title = '픽업 관련 주문이 없습니다';
        subtitle = '픽업 대기 중이거나 완료된 주문이 없습니다';
        icon = Icons.store;
        break;
      case OrderStatus.cancelled:
        title = '취소된 주문이 없습니다';
        subtitle = '취소된 주문 내역이 없습니다';
        icon = Icons.cancel;
        break;
      case OrderStatus.finished:
        title = '완료된 주문이 없습니다';
        subtitle = '완료된 주문 내역이 없습니다';
        icon = Icons.check_circle;
        break;
      default:
        title = '주문 내역이 없습니다';
        subtitle = '첫 주문을 해보세요!';
        icon = Icons.shopping_cart;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: ColorPalette.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: ColorPalette.primary,
            ),
          ),
          const SizedBox(height: Dimensions.spacingXl),
          Text(
            title,
            style: TextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.spacingSm),
          Text(
            subtitle,
            style: TextStyles.bodyLarge.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? ColorPalette.textSecondaryDark
                  : ColorPalette.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.spacingXl),
          if (currentFilter == null) // 전체 탭에서만 쇼핑 버튼 표시
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingXl,
                  vertical: Dimensions.paddingMd,
                ),
              ),
              child: const Text('쇼핑하러 가기'),
            ),
        ],
      ),
    );
  }
}
