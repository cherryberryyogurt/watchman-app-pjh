import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gonggoo_app/core/config/app_config.dart';
import 'package:gonggoo_app/features/auth/models/user_model.dart';
import '../../../core/theme/index.dart';
import '../../../core/widgets/loading_modal.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/screens/login_screen.dart';
import '../../../features/products/screens/product_list_screen.dart';

import '../../../features/cart/screens/cart_screen.dart';
import '../../order/providers/order_history_state.dart';
import '../../order/models/order_model.dart';
import '../../order/models/order_enums.dart';

import '../../order/widgets/order_history_item.dart';

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
                          _formatAddress(user),
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

  String _formatAddress(UserModel? user) {
    if (user == null || user.roadNameAddress == null) {
      return '등록된 주소가 없습니다';
    }

    String address = user.roadNameAddress!;
    if (user.detailedAddress != null && user.detailedAddress!.isNotEmpty) {
      address += '\n${user.detailedAddress}';
    }

    return address;
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
              onPressed: () async {
                Navigator.of(context).pop();

                // 로그아웃 실행
                await ref.read(authProvider.notifier).signOut();

                // 로그인 화면으로 이동 (모든 이전 화면 제거)
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    LoginScreen.routeName,
                    (route) => false,
                  );
                }
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
    debugPrint('🏠 프로필 - 주문 내역 상태: ${state.status}');
    debugPrint('🏠 프로필 - 주문 개수: ${state.orders.length}');

    // 상태별 주문 개수 디버깅
    final statusCounts = <OrderStatus, int>{};
    for (final order in state.orders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }
    debugPrint('🏠 프로필 - 상태별 주문 개수: $statusCounts');

    if (state.isLoading && !state.hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.padding),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.hasError && !state.hasData) {
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
    final recentOrders = state.orders.take(5).toList();

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
          .map((order) => OrderHistoryItem(
                order: order,
                onTap: () => _navigateToOrderDetail(order),
                isCompact: true,
              ))
          .toList(),
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
