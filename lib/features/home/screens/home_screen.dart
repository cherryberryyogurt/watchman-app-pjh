import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/index.dart';
import '../../../features/auth/providers/auth_state.dart';
import '../../../features/products/screens/product_list_screen.dart';
import '../../../features/auth/models/user_model.dart';
import '../../../features/cart/screens/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

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
  const _HomeContent({Key? key}) : super(key: key);

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
                    _buildCategoryCard(context, '전자제품', Icons.smartphone, () {
                      _onNavigateToProducts(context);
                    }),
                    _buildCategoryCard(context, '의류', Icons.checkroom, () {
                      _onNavigateToProducts(context);
                    }),
                    _buildCategoryCard(context, '가구', Icons.chair, () {
                      _onNavigateToProducts(context);
                    }),
                    _buildCategoryCard(context, '스포츠', Icons.sports_soccer, () {
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
          color: isDarkMode
              ? ColorPalette.surfaceDark
              : ColorPalette.surfaceLight,
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
  const _ProfileContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return authState.when(
      data: (state) {
        final user = state.user;

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
                          user?.email ?? '',
                          style: TextStyles.bodyMedium.copyWith(
                            color: isDarkMode
                                ? ColorPalette.textSecondaryDark
                                : ColorPalette.textSecondaryLight,
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
                      '이메일',
                      user?.email ?? 'N/A',
                      isDarkMode,
                    ),
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
                      user?.address ?? '등록된 주소가 없습니다',
                      isDarkMode,
                    ),
                  ],
                ),
              ),
              
              // Profile completion reminder if needed
              if (user?.phoneNumber == null || user?.address == null) ...[
                const SizedBox(height: Dimensions.spacingLg),
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSm),
                  decoration: BoxDecoration(
                    color: ColorPalette.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSm),
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
                        '서비스의 모든 기능을 사용하기 위해서는 연락처와 주소 정보가 필요합니다.',
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