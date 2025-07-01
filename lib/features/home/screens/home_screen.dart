import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gonggoo_app/core/config/app_config.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/index.dart';
import '../../auth/providers/auth_state.dart';
import '../../../features/products/screens/product_list_screen.dart';

import '../../../features/cart/screens/cart_screen.dart';
import '../../order/providers/order_history_state.dart';
import '../../order/models/order_model.dart';
import '../../order/models/order_enums.dart';
import '../../order/screens/refund_request_screen.dart';
import '../../order/widgets/order_status_badge.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ProductListScreen(),
    const CartScreen(),
    const _ProfileContent(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // 프로필 탭 선택 시 주문 내역 새로고침
    if (index == 2) {
      // PostFrameCallback을 사용하여 위젯이 빌드된 후 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final container = ProviderScope.containerOf(context);
          container.read(orderHistoryProvider.notifier).refreshOrders();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: ColorPalette.primary,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? ColorPalette.textSecondaryDark
            : ColorPalette.textSecondaryLight,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: '장바구니',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '내정보',
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }
}

// Original home content
class _HomeContent extends ConsumerWidget {
  const _HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return authState.when(
      data: (state) {
        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('와치맨'),
            centerTitle: true,
            elevation: 0,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message with user name
                  Text(
                    '환영합니다, ${user?.name ?? '사용자'}님!',
                    style: TextStyles.headlineMedium.copyWith(
                      color: isDarkMode
                          ? ColorPalette.textPrimaryDark
                          : ColorPalette.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingSm),
                  Text(
                    '와치맨에서 내 근처의 상품을 찾아보세요',
                    style: TextStyles.bodyLarge.copyWith(
                      color: isDarkMode
                          ? ColorPalette.textSecondaryDark
                          : ColorPalette.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingLg),

                  // Categories
                  Text(
                    '카테고리',
                    style: TextStyles.titleLarge,
                  ),
                  const SizedBox(height: Dimensions.spacingSm),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryCard(context, '전자제품', Icons.smartphone,
                            () {
                          _onNavigateToProducts(context);
                        }),
                        _buildCategoryCard(context, '의류', Icons.checkroom, () {
                          _onNavigateToProducts(context);
                        }),
                        _buildCategoryCard(context, '가구', Icons.chair, () {
                          _onNavigateToProducts(context);
                        }),
                        _buildCategoryCard(context, '스포츠', Icons.sports_soccer,
                            () {
                          _onNavigateToProducts(context);
                        }),
                        _buildCategoryCard(context, '도서', Icons.book, () {
                          _onNavigateToProducts(context);
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: Dimensions.spacingLg),

                  // Recent items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '최근 상품',
                        style: TextStyles.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          _onNavigateToProducts(context);
                        },
                        child: Text(
                          '더보기',
                          style: TextStyles.bodyMedium.copyWith(
                            color: ColorPalette.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storefront,
                            size: 48,
                            color: isDarkMode
                                ? ColorPalette.textSecondaryDark
                                : ColorPalette.textSecondaryLight,
                          ),
                          const SizedBox(height: Dimensions.spacingSm),
                          Text(
                            '상품 탭에서 상품을 둘러보세요!',
                            style: TextStyles.bodyLarge.copyWith(
                              color: isDarkMode
                                  ? ColorPalette.textSecondaryDark
                                  : ColorPalette.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: Dimensions.spacingMd),
                          ElevatedButton(
                            onPressed: () {
                              _onNavigateToProducts(context);
                            },
                            child: const Text('상품 보러가기'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('오류가 발생했습니다: $error'),
        ),
      ),
    );
  }

  void _onNavigateToProducts(BuildContext context) {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      homeScreenState._onItemTapped(0); // Navigate to products tab
    }
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: Dimensions.spacingSm),
        padding: const EdgeInsets.all(Dimensions.paddingSm),
        decoration: BoxDecoration(
          color:
              isDarkMode ? ColorPalette.surfaceDark : ColorPalette.surfaceLight,
          borderRadius: BorderRadius.circular(Dimensions.radiusSm),
          boxShadow: isDarkMode ? null : Styles.shadowXs,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: ColorPalette.primary,
              size: 32,
            ),
            const SizedBox(height: Dimensions.spacingXs),
            Text(
              title,
              style: TextStyles.bodySmall.copyWith(
                color: isDarkMode
                    ? ColorPalette.textPrimaryDark
                    : ColorPalette.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Profile content
class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return authState.when(
      data: (state) {
        final user = state.user;

        // 현재 사용자 정보 디버깅
        debugPrint('👤 현재 로그인 사용자 정보:');
        debugPrint('👤 user: $user');
        debugPrint('👤 user?.uid: ${user?.uid}');
        debugPrint('👤 user?.name: ${user?.name}');
        debugPrint('👤 user?.phoneNumber: ${user?.phoneNumber}');

        return Scaffold(
          appBar: AppBar(
            title: const Text('내 정보'),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User profile header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: ColorPalette.primary,
                        radius: 40,
                        child: Text(
                          (user?.name ?? '?').substring(0, 1),
                          style: TextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? '사용자',
                              style: TextStyles.titleLarge.copyWith(
                                color: isDarkMode
                                    ? ColorPalette.textPrimaryDark
                                    : ColorPalette.textPrimaryLight,
                              ),
                            ),
                            Text(
                              user?.phoneNumber ?? '전화번호 없음',
                              style: TextStyles.bodyMedium.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            // 사용자 ID 표시 (디버깅용)
                            Text(
                              'ID: ${user?.uid ?? 'N/A'}',
                              style: TextStyles.bodySmall.copyWith(
                                color: Colors.grey[500],
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/edit-profile');
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('수정'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorPalette.primary,
                            side: const BorderSide(color: ColorPalette.primary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingXs,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Dimensions.spacingLg),

                  // User info card
                  Container(
                    padding: const EdgeInsets.all(Dimensions.padding),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? ColorPalette.surfaceDark
                          : ColorPalette.surfaceLight,
                      borderRadius: BorderRadius.circular(Dimensions.radius),
                      boxShadow: isDarkMode ? null : Styles.shadowSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '내 정보',
                          style: TextStyles.titleLarge.copyWith(
                            color: isDarkMode
                                ? ColorPalette.textPrimaryDark
                                : ColorPalette.textPrimaryLight,
                          ),
                        ),
                        const Divider(),
                        // const SizedBox(height: Dimensions.spacingSm),
                        // _buildInfoRow(
                        //   context,
                        //   '이메일',
                        //   user?.email ?? 'N/A',
                        //   isDarkMode,
                        // ),
                        const SizedBox(height: Dimensions.spacingSm),
                        _buildInfoRow(
                          context,
                          '이름',
                          user?.name ?? 'N/A',
                          isDarkMode,
                        ),
                        const SizedBox(height: Dimensions.spacingSm),
                        _buildInfoRow(
                          context,
                          '전화번호',
                          user?.phoneNumber ?? '등록된 전화번호가 없습니다',
                          isDarkMode,
                        ),
                        const SizedBox(height: Dimensions.spacingSm),
                        _buildInfoRow(
                          context,
                          '주소',
                          user?.roadNameAddress ?? '등록된 주소가 없습니다',
                          isDarkMode,
                        ),
                        const SizedBox(height: Dimensions.spacingSm),
                        _buildInfoRow(
                          context,
                          '사용자 ID',
                          user?.uid ?? 'N/A',
                          isDarkMode,
                        ),
                      ],
                    ),
                  ),

                  // Profile completion reminder if needed
                  if (user?.roadNameAddress == null) ...[
                    const SizedBox(height: Dimensions.spacingLg),
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSm),
                      decoration: BoxDecoration(
                        color: ColorPalette.warning.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSm),
                        border: Border.all(
                          color: ColorPalette.warning.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: ColorPalette.warning,
                              ),
                              const SizedBox(width: Dimensions.spacingSm),
                              Expanded(
                                child: Text(
                                  '프로필을 완성하여 와치맨을 더 편리하게 이용해보세요!',
                                  style: TextStyles.bodyMedium.copyWith(
                                    color: isDarkMode
                                        ? ColorPalette.textPrimaryDark
                                        : ColorPalette.textPrimaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimensions.spacingSm),
                          Text(
                            '서비스의 모든 기능을 사용하기 위해서는 주소 정보가 필요합니다.',
                            style: TextStyles.bodySmall.copyWith(
                              color: isDarkMode
                                  ? ColorPalette.textSecondaryDark
                                  : ColorPalette.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: Dimensions.spacingSm),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/edit-profile');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorPalette.warning,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('프로필 완성하기'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 최근 주문 내역 섹션 추가
                  const SizedBox(height: Dimensions.spacingLg),
                  _RecentOrdersSection(isDarkMode: isDarkMode),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('오류가 발생했습니다: $error'),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    bool isDarkMode,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyles.bodyMedium.copyWith(
              color: isDarkMode
                  ? ColorPalette.textSecondaryDark
                  : ColorPalette.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: Dimensions.spacingSm),
        Expanded(
          child: Text(
            value,
            style: TextStyles.bodyMedium.copyWith(
              color: isDarkMode
                  ? ColorPalette.textPrimaryDark
                  : ColorPalette.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '로그아웃',
            style: TextStyles.titleLarge.copyWith(
              color: isDarkMode
                  ? ColorPalette.textPrimaryDark
                  : ColorPalette.textPrimaryLight,
            ),
          ),
          content: Text(
            '정말 로그아웃 하시겠습니까?',
            style: TextStyles.bodyMedium.copyWith(
              color: isDarkMode
                  ? ColorPalette.textPrimaryDark
                  : ColorPalette.textPrimaryLight,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                '취소',
                style: TextStyles.bodyMedium.copyWith(
                  color: isDarkMode
                      ? ColorPalette.textSecondaryDark
                      : ColorPalette.textSecondaryLight,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.error,
              ),
              child: const Text('로그아웃'),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).signOut();
              },
            ),
          ],
        );
      },
    );
  }
}

/// 최근 주문 내역 섹션 위젯
class _RecentOrdersSection extends ConsumerStatefulWidget {
  final bool isDarkMode;

  const _RecentOrdersSection({required this.isDarkMode});

  @override
  ConsumerState<_RecentOrdersSection> createState() =>
      _RecentOrdersSectionState();
}

class _RecentOrdersSectionState extends ConsumerState<_RecentOrdersSection> {
  static const int recentOrdersLimit = AppConfig.RECENT_ORDERS_LIMIT;

  @override
  void initState() {
    super.initState();
    // 최근 주문 내역 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🏠 ProfileContent: 주문 내역 로드 시작');
      ref.read(orderHistoryProvider.notifier).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderHistoryState = ref.watch(orderHistoryProvider);

    // 디버깅용 로그
    debugPrint('🏠 ProfileContent: 현재 상태 = ${orderHistoryState.status}');
    debugPrint('🏠 ProfileContent: 주문 개수 = ${orderHistoryState.orders.length}');
    debugPrint('🏠 ProfileContent: 에러 메시지 = ${orderHistoryState.errorMessage}');
    debugPrint('🏠 ProfileContent: hasData = ${orderHistoryState.hasData}');
    debugPrint('🏠 ProfileContent: isLoading = ${orderHistoryState.isLoading}');
    debugPrint('🏠 ProfileContent: hasError = ${orderHistoryState.hasError}');

    return Container(
      padding: const EdgeInsets.all(Dimensions.padding),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? ColorPalette.surfaceDark
            : ColorPalette.surfaceLight,
        borderRadius: BorderRadius.circular(Dimensions.radius),
        boxShadow: widget.isDarkMode ? null : Styles.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '나의 구매내역',
                style: TextStyles.titleLarge.copyWith(
                  color: widget.isDarkMode
                      ? ColorPalette.textPrimaryDark
                      : ColorPalette.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 새로고침 버튼
                  IconButton(
                    onPressed: () {
                      debugPrint('🔄 수동 주문 내역 새로고침');
                      ref.read(orderHistoryProvider.notifier).refreshOrders();
                    },
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                      color: widget.isDarkMode
                          ? ColorPalette.textSecondaryDark
                          : ColorPalette.textSecondaryLight,
                    ),
                    tooltip: '새로고침',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/order-history');
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '주문 상세보기',
                          style: TextStyles.bodyMedium.copyWith(
                            color: widget.isDarkMode
                                ? ColorPalette.textSecondaryDark
                                : ColorPalette.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: widget.isDarkMode
                              ? ColorPalette.textSecondaryDark
                              : ColorPalette.textSecondaryLight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: Dimensions.spacingSm),

          // 주문 내역 내용
          _buildOrderContent(orderHistoryState),
        ],
      ),
    );
  }

  Widget _buildOrderContent(OrderHistoryState state) {
    return Consumer(
      builder: (context, ref, child) {
        final orderHistoryState = ref.watch(orderHistoryProvider);

        debugPrint('🏠 프로필 - 주문 내역 상태: ${orderHistoryState.status}');
        debugPrint('🏠 프로필 - 주문 개수: ${orderHistoryState.orders.length}');

        // 상태별 주문 개수 디버깅
        final statusCounts = <OrderStatus, int>{};
        for (final order in orderHistoryState.orders) {
          statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
        }
        debugPrint('🏠 프로필 - 상태별 주문 개수: $statusCounts');

        if (orderHistoryState.isLoading && !orderHistoryState.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Dimensions.padding),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (orderHistoryState.hasError && !orderHistoryState.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.padding),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: ColorPalette.error,
                  ),
                  const SizedBox(height: Dimensions.spacingSm),
                  Text(
                    '주문 내역을 불러올 수 없습니다',
                    style: TextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spacingSm),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(orderHistoryProvider.notifier).refreshOrders(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }

        // 최근 주문 5개만 표시
        final recentOrders = orderHistoryState.orders.take(5).toList();

        debugPrint('🏠 프로필 - 표시할 최근 주문 개수: ${recentOrders.length}');
        for (int i = 0; i < recentOrders.length; i++) {
          final order = recentOrders[i];
          debugPrint(
              '🏠 주문 $i: ${order.orderId} - ${order.status.displayName} - ${order.totalAmount}원');
        }

        if (recentOrders.isEmpty) {
          return _buildEmptyOrderState();
        }

        return Column(
          children: recentOrders
              .map((order) => _RecentOrderItem(
                    order: order,
                    isDarkMode: widget.isDarkMode,
                    onTap: () => _navigateToOrderDetail(order),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildEmptyOrderState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spacingLg),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: widget.isDarkMode
                  ? ColorPalette.textSecondaryDark
                  : ColorPalette.textSecondaryLight,
            ),
            const SizedBox(height: Dimensions.spacingSm),
            Text(
              '아직 주문 내역이 없습니다',
              style: TextStyles.bodyMedium.copyWith(
                color: widget.isDarkMode
                    ? ColorPalette.textSecondaryDark
                    : ColorPalette.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.spacingSm),
            TextButton(
              onPressed: () {
                // 홈 탭(상품 목록)으로 이동
                final homeScreenState =
                    context.findAncestorStateOfType<_HomeScreenState>();
                if (homeScreenState != null) {
                  homeScreenState._onItemTapped(0);
                }
              },
              child: Text(
                '상품 둘러보기',
                style: TextStyles.bodySmall.copyWith(
                  color: ColorPalette.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToOrderDetail(OrderModel order) {
    Navigator.pushNamed(
      context,
      '/order-detail',
      arguments: {'orderId': order.orderId},
    );
  }
}

/// 최근 주문 아이템 위젯
class _RecentOrderItem extends StatelessWidget {
  final OrderModel order;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _RecentOrderItem({
    required this.order,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    // 주문 정보 표시 (비정규화된 데이터 사용)
    final productName = order.representativeProductName ?? '상품명 없음';
    final additionalItemsCount =
        order.totalProductCount > 1 ? order.totalProductCount - 1 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSm),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radius),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 주문 헤더 (배송 완료 상태 및 날짜)
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSm),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[800]?.withOpacity(0.3)
                  : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.radius),
                topRight: Radius.circular(Dimensions.radius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatOrderDate(order.createdAt),
                  style: TextStyles.bodySmall.copyWith(
                    color: isDarkMode
                        ? ColorPalette.textSecondaryDark
                        : ColorPalette.textSecondaryLight,
                  ),
                ),
                OrderStatusBadge(status: order.status, isCompact: true),
              ],
            ),
          ),

          // 상품 정보 섹션
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(Dimensions.radius),
              bottomRight: Radius.circular(Dimensions.radius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSm),
              child: Column(
                children: [
                  // 상품 이미지 및 정보
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상품 이미지 (플레이스홀더)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.image_outlined,
                          color: isDarkMode
                              ? ColorPalette.textSecondaryDark
                              : ColorPalette.textSecondaryLight,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: Dimensions.spacingSm),

                      // 상품 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 상품명
                            Text(
                              productName,
                              style: TextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? ColorPalette.textPrimaryDark
                                    : ColorPalette.textPrimaryLight,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            if (additionalItemsCount > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                '외 ${additionalItemsCount}개',
                                style: TextStyles.bodySmall.copyWith(
                                  color: isDarkMode
                                      ? ColorPalette.textSecondaryDark
                                      : ColorPalette.textSecondaryLight,
                                ),
                              ),
                            ],

                            const SizedBox(height: Dimensions.spacingXs),

                            // 가격 정보
                            Text(
                              priceFormat.format(order.totalAmount),
                              style: TextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? ColorPalette.textPrimaryDark
                                    : ColorPalette.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Dimensions.spacingMd),

                  // 액션 버튼들
                  Row(
                    children: [
                      // 교환, 반품 신청 버튼
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _canRequestRefund(order.status)
                              ? () {
                                  _showRefundRequestDialog(context);
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDarkMode
                                ? ColorPalette.textSecondaryDark
                                : ColorPalette.textSecondaryLight,
                            side: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey[600]!
                                  : Colors.grey[300]!,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: Dimensions.paddingXs,
                            ),
                          ),
                          child: Text(
                            '환불',
                            style: TextStyles.bodySmall,
                          ),
                        ),
                      ),

                      const SizedBox(width: Dimensions.spacingSm),

                      // 배송조회/픽업장소 확인 버튼
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _canShowSecondButton(order)
                              ? () {
                                  _onSecondButtonPressed(context, order);
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDarkMode
                                ? ColorPalette.textSecondaryDark
                                : ColorPalette.textSecondaryLight,
                            side: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey[600]!
                                  : Colors.grey[300]!,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: Dimensions.paddingXs,
                            ),
                          ),
                          child: Text(
                            _getSecondButtonText(order),
                            style: TextStyles.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 주문일자 포맷팅
  String _formatOrderDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return '${DateFormat('M/d').format(date)}(금) 도착';
    } else if (difference == 1) {
      return '${DateFormat('M/d').format(date)}(목) 도착';
    } else {
      return '${DateFormat('M/d').format(date)} 도착';
    }
  }

  /// 환불 요청 가능 여부 확인
  bool _canRequestRefund(OrderStatus status) {
    return status == OrderStatus.confirmed;
  }

  /// 배송 주문인지 픽업 주문인지 판단
  bool _isDeliveryOrder(OrderModel order) {
    return order.deliveryAddress != null;
  }

  /// 두 번째 버튼(배송조회/픽업장소 확인) 텍스트 결정
  String _getSecondButtonText(OrderModel order) {
    return _isDeliveryOrder(order) ? '배송조회' : '픽업장소 확인';
  }

  /// 두 번째 버튼 활성화 여부 확인
  bool _canShowSecondButton(OrderModel order) {
    if (_isDeliveryOrder(order)) {
      // 배송 상품: 배송 관련 상태일 때만 활성화
      return order.status == OrderStatus.shipped ||
          order.status == OrderStatus.delivered;
    } else {
      // 픽업 상품: 준비 완료 이후 상태일 때 활성화
      return order.status == OrderStatus.readyForPickup ||
          order.status == OrderStatus.pickedUp ||
          order.status == OrderStatus.finished;
    }
  }

  /// 환불 요청 다이얼로그
  void _showRefundRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('반품'),
        content: const Text('반품을 신청하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RefundRequestScreen(order: order),
                ),
              );
            },
            child: const Text('신청'),
          ),
        ],
      ),
    );
  }

  /// 두 번째 버튼 클릭 이벤트 핸들러
  void _onSecondButtonPressed(BuildContext context, OrderModel order) {
    if (_isDeliveryOrder(order)) {
      _showDeliveryTrackingDialog(context);
    } else {
      _showPickupLocationDialog(context);
    }
  }

  /// 배송 추적 다이얼로그
  void _showDeliveryTrackingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('배송조회'),
        content: const Text('배송 조회 기능을 실행합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 픽업장소 확인 다이얼로그
  void _showPickupLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('픽업장소 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '픽업 장소 정보',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text('📍 상호명: 와치맨 픽업센터'),
            const SizedBox(height: 4),
            const Text('📍 주소: 서울시 강남구 테헤란로 123'),
            const SizedBox(height: 4),
            const Text('📞 연락처: 02-1234-5678'),
            const SizedBox(height: 4),
            const Text('🕒 운영시간: 평일 09:00-18:00'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Text(
                '💡 픽업 시 주문번호와 신분증을 지참해주세요.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 지도 앱 열기 또는 전화걸기 기능 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('길찾기 기능은 준비 중입니다.')),
              );
            },
            child: const Text('길찾기'),
          ),
        ],
      ),
    );
  }
}
