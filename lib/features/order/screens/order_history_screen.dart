import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/index.dart';
import '../providers/order_history_state.dart';
import '../models/order_model.dart';
import '../widgets/order_history_item.dart';

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
      body: _buildOrderList(orderHistoryState),
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
      return _buildEmptyState();
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
            child: OrderHistoryItem(
              order: order,
              onTap: () => _navigateToOrderDetail(order),
            ),
          );
        },
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
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
              Icons.shopping_cart,
              size: 64,
              color: ColorPalette.primary,
            ),
          ),
          const SizedBox(height: Dimensions.spacingXl),
          Text(
            '주문 내역이 없습니다',
            style: TextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.spacingSm),
          Text(
            '첫 주문을 해보세요!',
            style: TextStyles.bodyLarge.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? ColorPalette.textSecondaryDark
                  : ColorPalette.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.spacingXl),
          IntrinsicWidth(
            child: ElevatedButton(
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
          ),
        ],
      ),
    );
  }
}
