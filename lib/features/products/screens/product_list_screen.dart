import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/product_state.dart';
import '../widgets/product_list_item.dart';
import 'product_detail_screen.dart';
import '../../../core/theme/index.dart';
import '../../auth/providers/auth_state.dart';
import '../../../core/providers/repository_providers.dart';
import '../../location/models/location_tag_model.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  static const String routeName = '/products';

  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  bool _loginModalShown = false;

  @override
  void initState() {
    super.initState();
    // Start initial loading after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initialLoad();
      }
    });
  }

  void _initialLoad() {
    debugPrint('🏠 ProductListScreen: Checking initial auth state');
    final authState = ref.read(authProvider);
    authState.whenData((state) {
      final user = state.user;
      debugPrint(
          '🏠 ProductListScreen: Initial user = ${user?.uid}, locationStatus = ${user?.locationStatus}, locationTagName = ${user?.locationTagName}');

      if (user != null &&
          user.locationStatus == 'active' &&
          user.locationTagName != null) {
        debugPrint(
            '🏠 ProductListScreen: Loading products immediately for user with valid location');
        _loginModalShown = false; // Reset flag when user is authenticated
        _loadProducts();
      } else if (user == null) {
        debugPrint(
            '🏠 ProductListScreen: Initial user not logged in, showing login modal');
        _showLoginRequiredModal(context, ref);
      } else {
        debugPrint(
            '🏠 ProductListScreen: Initial user has invalid location status: ${user.locationStatus}');
      }
    });
  }

  Future<void> _loadProducts() async {
    debugPrint('🏠 ProductListScreen: _loadProducts called');
    try {
      // 현재 사용자 위치 + 선택된 카테고리로 로드
      await ref.read(productProvider.notifier).loadProducts();
      debugPrint('🏠 ProductListScreen: _loadProducts completed successfully');
    } catch (e) {
      debugPrint('🏠 ProductListScreen: _loadProducts failed with error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상품 로딩 중 오류가 발생했습니다: $e'),
            backgroundColor: ColorPalette.error,
          ),
        );
      }
    }
  }

  void _navigateToProductDetail(String productId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          productId: productId,
        ),
      ),
    );
  }

  Future<void> _showGroupChatModal(BuildContext context, String locationTagName, String? kakaoGroupChatURL) async {
    if (kakaoGroupChatURL == null || kakaoGroupChatURL.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$locationTagName 동네 그룹 채팅방이 아직 준비되지 않았습니다.'),
          backgroundColor: ColorPalette.error,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusLg),
          ),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들 바
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: Dimensions.spacingLg),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 아이콘
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ColorPalette.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.chat_outlined,
                size: 32,
                color: ColorPalette.primary,
              ),
            ),
            const SizedBox(height: Dimensions.spacingLg),

            // 제목
            Text(
              '그룹 채팅방 참여',
              style: TextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.spacingMd),

            // 설명
            Text(
              '$locationTagName 동네 그룹 채팅방에\n참여하시겠습니까?',
              style: TextStyles.bodyLarge.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? ColorPalette.textSecondaryDark
                    : ColorPalette.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.spacingXl),

            // 버튼들
            Row(
              children: [
                // 닫기 버튼
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.padding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusMd),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Text(
                      '닫기',
                      style: TextStyles.labelLarge.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? ColorPalette.textSecondaryDark
                            : ColorPalette.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.spacingMd),

                // 참여 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _launchGroupChatURL(kakaoGroupChatURL);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.padding,
                      ),
                      backgroundColor: ColorPalette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusMd),
                      ),
                    ),
                    child: Text(
                      '참여하기',
                      style: TextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 안전 영역 확보
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _launchGroupChatURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      
      if (kIsWeb) {
        // Web environment: Open in new window
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, webOnlyWindowName: '_blank');
        } else {
          throw Exception('Cannot launch URL');
        }
      } else {
        // Mobile environment: Open in external browser
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw Exception('Cannot launch URL');
        }
      }
    } catch (e) {
      debugPrint('Failed to launch URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('채팅방 링크를 열 수 없습니다: $e'),
            backgroundColor: ColorPalette.error,
          ),
        );
      }
    }
  }

  void _showLoginRequiredModal(BuildContext context, WidgetRef ref) {
    if (_loginModalShown) {
      return;
    }
    _loginModalShown = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusLg),
          ),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들 바
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: Dimensions.spacingLg),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 아이콘
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ColorPalette.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.location_on_outlined,
                size: 32,
                color: ColorPalette.primary,
              ),
            ),
            const SizedBox(height: Dimensions.spacingLg),

            // 제목
            Text(
              '로그인이 필요해요',
              style: TextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.spacingMd),

            // 설명
            Text(
              '내 지역의 상품을 확인하려면\n로그인이 필요합니다.',
              style: TextStyles.bodyLarge.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? ColorPalette.textSecondaryDark
                    : ColorPalette.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.spacingXl),

            // 버튼들
            Row(
              children: [
                // 취소 버튼
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.padding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusMd),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyles.labelLarge.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? ColorPalette.textSecondaryDark
                            : ColorPalette.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.spacingMd),

                // 로그인 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: 로그인 화면으로 이동
                      // Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.padding,
                      ),
                      backgroundColor: ColorPalette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusMd),
                      ),
                    ),
                    child: Text(
                      '로그인하기',
                      style: TextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 안전 영역 확보
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    ).then((_) {
      // Reset the flag when modal is dismissed
      _loginModalShown = false;
    });
  }

  // 카테고리 필터 버튼 위젯
  Widget _buildCategoryFilters() {
    // final categories = [
    //   {'name': '전체', 'value': '전체'},
    //   {'name': '농산물', 'value': '농산물'},
    //   {'name': '축산물', 'value': '축산물'},
    //   {'name': '수산물', 'value': '수산물'},
    //   {'name': '기타', 'value': '기타'},
    // ];

    const categories = ['전체', '농산물', '축산물', '수산물', '기타'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: Dimensions.spacingSm),
      child: SizedBox(
        height: 44, // 토스/당근 스타일의 적절한 높이
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.padding),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected =
                ref.watch(productProvider).currentCategory == category;

            return _buildCategoryChip(
              label: category,
              isSelected: isSelected,
              onTap: () => _onCategorySelected(category),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(
          minWidth: 56, // 최소 터치 영역 보장
          minHeight: 44,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorPalette.primary
              : Theme.of(context).brightness == Brightness.dark
                  ? ColorPalette.surfaceDark
                  : ColorPalette.surfaceLight,
          borderRadius: BorderRadius.circular(22), // 높이의 절반 (44/2)
          border: Border.all(
            color: isSelected
                ? ColorPalette.primary
                : Theme.of(context).brightness == Brightness.dark
                    ? ColorPalette.borderDark
                    : ColorPalette.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorPalette.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          // 텍스트 중앙 정렬을 위해 Center 위젯 사용
          child: Text(
            label,
            style: TextStyles.labelLarge.copyWith(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).brightness == Brightness.dark
                      ? ColorPalette.textPrimaryDark
                      : ColorPalette.textPrimaryLight,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              height: 1.0, // 라인 높이를 1.0으로 설정하여 텍스트 중앙 정렬 개선
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // 카테고리 선택 핸들러
  void _onCategorySelected(String category) {
    final notifier = ref.read(productProvider.notifier);

    notifier.setCategory(category);
    notifier.loadProductsByCategory(category);
  }

  Widget _buildEmptyProductView() {
    final currentCategory = ref.watch(productProvider).currentCategory;
    final categoryName = currentCategory == '전체'
        ? '상품'
        : currentCategory == '농산물'
            ? '농산물'
            : currentCategory == '축산물'
                ? '축산물'
                : currentCategory == '수산물'
                    ? '수산물'
                    : currentCategory == '기타'
                        ? '기타 상품'
                        : '상품';

    return Center(
      child: Container(
        padding: const EdgeInsets.all(Dimensions.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 일러스트레이션 컨테이너
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: ColorPalette.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusLg),
              ),
              child: Center(
                child: Icon(
                  Icons.shopping_basket_outlined,
                  size: 80,
                  color: ColorPalette.primary,
                ),
              ),
            ),
            const SizedBox(height: Dimensions.spacingLg),

            // 타이틀 텍스트
            Text(
              '$categoryName이 없습니다',
              style: TextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.spacingMd),

            // 설명 텍스트
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: Dimensions.paddingLg),
              child: Text(
                '현재 선택하신 지역에 $categoryName이 없습니다.\n다른 카테고리를 선택해보세요.',
                style: TextStyles.bodyLarge.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? ColorPalette.textSecondaryDark
                      : ColorPalette.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Dimensions.spacingLg),

            // 새로고침 버튼
            TextButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('새로 고침'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.padding,
                  vertical: Dimensions.paddingSm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes and automatically load products
    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      debugPrint('🏠 ProductListScreen: Auth state changed');
      next.whenData((authState) {
        final user = authState.user;
        debugPrint(
            '🏠 ProductListScreen: User = ${user?.uid}, locationStatus = ${user?.locationStatus}, locationTagName = ${user?.locationTagName}');

        if (user != null &&
            user.locationStatus == 'active' &&
            user.locationTagName != null) {
          debugPrint(
              '🏠 ProductListScreen: Loading products for user with valid location');
          _loginModalShown = false; // Reset flag when user is authenticated
          _loadProducts();
        } else if (user == null) {
          debugPrint(
              '🏠 ProductListScreen: User not logged in, showing login modal');
          // Use Future.delayed to avoid calling setState during build
          Future.delayed(Duration.zero, () {
            if (mounted) {
              _showLoginRequiredModal(context, ref);
            }
          });
        } else {
          debugPrint(
              '🏠 ProductListScreen: User has invalid location status: ${user.locationStatus}');
        }
      });
    });

    final productState = ref.watch(productProvider);
    final authState = ref.watch(authProvider);
    final user = authState.asData?.value.user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authProvider);

            return authState.when(
              data: (state) {
                if (state.user != null) {
                  // 로그인된 상태: 유저의 위치 표시
                  return Text(state.user!.locationTagName ?? '위치 미설정');
                } else {
                  // 로그인하지 않은 상태: 로그인 필요 표시
                  return GestureDetector(
                    onTap: () => _showLoginRequiredModal(context, ref),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('로그인 필요'),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.login,
                          size: 20,
                          color: ColorPalette.primary,
                        ),
                      ],
                    ),
                  );
                }
              },
              loading: () => const Text('위치 확인 중...'),
              error: (error, stack) => const Text('위치 오류'),
            );
          },
        ),
        centerTitle: true,
        actions: [
          // 그룹 채팅방 버튼
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              
              return authState.when(
                data: (state) {
                  if (state.user != null && 
                      state.user!.locationStatus == 'active' &&
                      state.user!.locationTagId != null) {
                    return IconButton(
                      onPressed: () async {
                        // Fetch LocationTag data to get kakaoGroupChatURL
                        final locationTagRepository = ref.read(locationTagRepositoryProvider);
                        final locationTag = await locationTagRepository.getLocationTagById(
                          state.user!.locationTagId!
                        );
                        
                        if (locationTag != null && mounted) {
                          await _showGroupChatModal(
                            context,
                            locationTag.name,
                            locationTag.kakaoGroupChatURL,
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      tooltip: '그룹 채팅방',
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: Column(
          children: [
            // 카테고리 필터 추가
            _buildCategoryFilters(),

            // 기존 상품 리스트
            Expanded(
              child: Builder(
                builder: (context) {
                  final status = productState.status;
                  final products = productState.products;
                  final errorMessage = productState.errorMessage;

                  if (status == ProductLoadStatus.loading && products.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (status == ProductLoadStatus.error && products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('오류가 발생했습니다', style: TextStyles.titleMedium),
                          const SizedBox(height: Dimensions.spacingSm),
                          Text(
                            errorMessage ?? '알 수 없는 오류',
                            style: TextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Dimensions.spacingMd),
                          ElevatedButton(
                            onPressed: _loadProducts,
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (products.isEmpty) {
                    return _buildEmptyProductView();
                  }

                  return Stack(
                    children: [
                      ListView.builder(
                        padding:
                            const EdgeInsets.only(bottom: Dimensions.spacingLg),
                        itemCount: products.length + 1, // +1 for company info
                        itemBuilder: (context, index) {
                          // Company info at the bottom
                          if (index == products.length) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(Dimensions.padding),
                              margin: const EdgeInsets.only(
                                top: Dimensions.spacingLg,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? ColorPalette.surfaceDark
                                    : ColorPalette.surfaceLight,
                                border: Border(
                                  top: BorderSide(
                                    color: isDarkMode
                                        ? ColorPalette.borderDark
                                        : ColorPalette.border,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '와치맨 공동구매 정보',
                                        style: TextStyles.labelLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: Dimensions.spacingSm),
                                  Text(
                                    '상호 : 와치맨컴퍼니\n'
                                    '대표자 : 박지환\n'
                                    '주소 : 경기도 광명시 새빛공원로 67, B1819\n'
                                    '사업자번호 : 378-21-02298\n'
                                    '통신판매번호 : 2024-3900309-30-2-00429\n'
                                    '고객센터 : 010-6486-2591',
                                    style: TextStyles.bodySmall.copyWith(
                                      color: isDarkMode
                                          ? ColorPalette.textSecondaryDark
                                          : ColorPalette.textSecondaryLight,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Product items
                          final product = products[index];
                          return ProductListItem(
                            product: product,
                            onTap: () => _navigateToProductDetail(product.id),
                          );
                        },
                      ),
                      if (status == ProductLoadStatus.loading)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Colors.transparent,
                            color: ColorPalette.primary,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
