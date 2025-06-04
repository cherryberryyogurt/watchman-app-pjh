import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_state.dart';
import '../widgets/product_list_item.dart';
import 'product_detail_screen.dart';
import '../../../core/theme/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  static const String routeName = '/products';

  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    try {
      // 현재 사용자 위치 + 선택된 카테고리로 로드
      await ref.read(productProvider.notifier).loadProducts();
    } catch (e) {
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

  void _addDummyProducts() async {
    try {
      await ref.read(productProvider.notifier).addDummyProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('더미 상품이 추가되었습니다.'),
            backgroundColor: ColorPalette.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('더미 상품 추가 중 오류가 발생했습니다: $e'),
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

  void _showLocationSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusMd),
        ),
      ),
      builder: (context) => _buildLocationSelector(),
    );
  }

  Widget _buildLocationSelector() {
    final locations = [
      {'name': '전체', 'coordinates': null, 'locationTag': '전체'},
      {
        'name': '강남구',
        'coordinates': const GeoPoint(37.4988, 127.0281),
        'locationTag': '강남동'
      },
      {
        'name': '서초구',
        'coordinates': const GeoPoint(37.4923, 127.0292),
        'locationTag': '서초동'
      },
      {
        'name': '송파구',
        'coordinates': const GeoPoint(37.5145, 127.1057),
        'locationTag': '송파동'
      },
      {
        'name': '영등포구',
        'coordinates': const GeoPoint(37.5257, 126.8957),
        'locationTag': '영등포동'
      },
      {
        'name': '강서구',
        'coordinates': const GeoPoint(37.5509, 126.8495),
        'locationTag': '강서동'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(Dimensions.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '지역 선택',
            style: TextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.spacingMd),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: locations.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final location = locations[index];
              return ListTile(
                title: Text(location['name'] as String),
                onTap: () {
                  final notifier = ref.read(productProvider.notifier);
                  final currentState = ref.read(productProvider);

                  notifier.setLocation(
                    location['name'] as String,
                    location['coordinates'] as GeoPoint?,
                  );

                  if (location['locationTag'] != '전체') {
                    // 선택된 카테고리를 유지하면서 지역별 상품 로드
                    notifier.loadProductsByLocationTagAndCategory(
                      location['locationTag'] as String,
                      currentState.currentCategory,
                    );
                  } else {
                    notifier.loadAllProducts();
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
          const SizedBox(height: Dimensions.spacingMd),
        ],
      ),
    );
  }

  // 카테고리 필터 버튼 위젯
  Widget _buildCategoryFilters() {
    final categories = [
      {'name': '전체', 'value': '전체'},
      {'name': '농산물', 'value': '농산물'},
      {'name': '축산물', 'value': '축산물'},
      {'name': '수산물', 'value': '수산물'},
      {'name': '기타', 'value': '기타'},
    ];

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
                ref.watch(productProvider).currentCategory == category['value'];

            return _buildCategoryChip(
              label: category['name']!,
              isSelected: isSelected,
              onTap: () => _onCategorySelected(category['value']!),
            );
          },
        ),
      ),
    );
  }

  // 토스/당근마켓 스타일 카테고리 칩
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
                    color: ColorPalette.primary.withOpacity(0.2),
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
                color: ColorPalette.primary.withOpacity(0.1),
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
                '현재 선택하신 지역에 $categoryName이 없습니다.\n다른 카테고리를 선택하거나 새로운 상품을 추가해보세요.',
                style: TextStyles.bodyLarge.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? ColorPalette.textSecondaryDark
                      : ColorPalette.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Dimensions.spacingLg),

            // 액션 버튼
            ElevatedButton.icon(
              onPressed: _addDummyProducts,
              icon: const Icon(Icons.add),
              label: const Text('더미 상품 추가하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingLg,
                  vertical: Dimensions.padding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.spacingMd),

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
    final productState = ref.watch(productProvider);
    final isLoading = productState.status == ProductLoadStatus.loading;
    final isDummyLoading = productState.isDummyAddLoading;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _showLocationSelector,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(productState.currentLocation),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: isDummyLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add),
            onPressed: isDummyLoading ? null : _addDummyProducts,
            tooltip: '더미 상품 추가',
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

                  if (isLoading && products.isEmpty) {
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
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductListItem(
                            product: product,
                            onTap: () => _navigateToProductDetail(product.id),
                          );
                        },
                      ),
                      if (isLoading)
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
