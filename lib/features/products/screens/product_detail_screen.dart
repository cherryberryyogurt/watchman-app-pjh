import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gonggoo_app/core/config/app_config.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_state.dart';
import '../../../core/theme/index.dart';
import '../../cart/repositories/cart_repository.dart';
import '../models/product_model.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0; // 🆕 현재 이미지 인덱스
  final PageController _pageController = PageController(); // 🆕 페이지 컨트롤러
  int _selectedOrderUnitIndex = 0; // 🆕 선택된 OrderUnit 인덱스

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductDetails();
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); // 🆕 페이지 컨트롤러 dispose
    // Clear the selected product when leaving
    ref.read(productProvider.notifier).clearSelectedProduct();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    try {
      await ref
          .read(productProvider.notifier)
          .getProductDetails(widget.productId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상품 정보를 불러오는데 실패했습니다: $e'),
            backgroundColor: ColorPalette.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final product = productState.selectedProduct;
    final isLoading = productState.isDetailLoading;
    final hasError = productState.status == ProductLoadStatus.error &&
        productState.currentAction == ProductActionType.loadDetails;
    final errorMessage = productState.errorMessage;

    if (isLoading && product == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '오류가 발생했습니다',
                style: TextStyles.titleMedium,
              ),
              const SizedBox(height: Dimensions.spacingSm),
              Text(
                errorMessage ?? '알 수 없는 오류',
                style: TextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.spacingMd),
              ElevatedButton(
                onPressed: _loadProductDetails,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (product == null) {
      return const Scaffold(
        body: Center(
          child: Text('상품을 찾을 수 없습니다'),
        ),
      );
    }

    // Format price
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    // 판매 기간 계산
    String saleDate = '판매기간 없음';
    if (product.startDate != null && product.endDate != null) {
      final startFormatted =
          DateFormat('yyyy.MM.dd').format(product.startDate!);
      final endFormatted = DateFormat('yyyy.MM.dd').format(product.endDate!);
      saleDate = '$startFormatted ~ $endFormatted';
    } else if (product.startDate != null) {
      final startFormatted =
          DateFormat('yyyy.MM.dd').format(product.startDate!);
      saleDate = '$startFormatted부터';
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: true,
                snap: true,
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🆕 Product Image Gallery
                    _buildImageGallery(product),

                    // Main Info Section
                    Padding(
                      padding: const EdgeInsets.all(Dimensions.padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location Tag
                          Row(
                            children: [
                              // const Icon(
                              //   Icons.location_on,
                              //   size: 16,
                              //   color: ColorPalette.primary,
                              // ),
                              // const SizedBox(width: Dimensions.spacingSm),
                              // Text(
                              //   product.locationTagName ?? '위치 정보 없음',
                              //   style: TextStyles.bodyMedium,
                              // ),
                              Row(
                                children: [
                                  Icon(
                                    product.deliveryType == '픽업'
                                        ? Icons.store
                                        : Icons.local_shipping,
                                    color: ColorPalette.primary,
                                  ),
                                  const SizedBox(width: Dimensions.spacingSm),
                                  Text(
                                    product.deliveryType,
                                    style: TextStyles.titleMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: Dimensions.spacingSm),

                              // 택배 발송 정보 / 픽업 날짜 정보
                              if (product.deliveryType == '택배' ||
                                  product.deliveryType == '배송')
                                Text(
                                  '발송:',
                                  style: TextStyles.titleMedium,
                                ),
                              const SizedBox(width: Dimensions.spacingSm),
                              if (product.deliveryType == '택배' ||
                                  product.deliveryType == '배송')
                                Text(
                                  product.deliveryDate ?? '날짜 없음',
                                  style: TextStyles.titleMedium,
                                ),
                              if (product.deliveryType == '픽업')
                                Text(
                                  product.pickupDate ?? '날짜 없음',
                                  style: TextStyles.titleMedium,
                                ),
                              const SizedBox(width: Dimensions.spacingSm),

                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSm,
                                  vertical: Dimensions.paddingXs,
                                ),
                                decoration: BoxDecoration(
                                  color: product.isOnSale
                                      ? ColorPalette.success
                                          .withValues(alpha: 0.2)
                                      : ColorPalette.error
                                          .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                      Dimensions.radiusSm),
                                ),
                                child: Text(
                                  product.isOnSale ? '판매중' : '판매종료',
                                  style: TextStyles.bodySmall.copyWith(
                                    color: product.isOnSale
                                        ? ColorPalette.success
                                        : ColorPalette.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: Dimensions.spacingLg * 2),

                          // Product Name
                          Text(
                            product.name,
                            style: TextStyles.headlineSmall,
                          ),
                          const SizedBox(height: Dimensions.spacingSm),

                          // 🆕 OrderUnit 선택 아코디언
                          _buildOrderUnitSelector(product),

                          const Divider(height: Dimensions.spacingLg * 2),

                          // 🆕 픽업 포인트 정보 표시
                          if (product.isPickupDelivery &&
                              product.hasPickupPoints)
                            _buildPickupPointInfo(product),

                          const SizedBox(height: Dimensions.spacingMd),

                          // Sale Period
                          Text(
                            '공동 구매 기간',
                            style: TextStyles.titleMedium,
                          ),
                          const SizedBox(height: Dimensions.spacingSm),
                          Text(
                            saleDate,
                            style: TextStyles.bodyMedium,
                          ),

                          const SizedBox(height: Dimensions.spacingMd),

                          // Stock
                          if (product.stock < AppConfig.lowStockThreshold)
                            Text(
                              '재고: ${product.stock}개',
                              style: TextStyles.bodyMedium.copyWith(
                                color: ColorPalette.primary,
                              ),
                            ),
                          const SizedBox(height: Dimensions.spacingMd),

                          // Description
                          Text(
                            '상품 상세',
                            style: TextStyles.titleLarge,
                          ),
                          const SizedBox(height: Dimensions.spacingMd),

                          // Using markdown for the description
                          MarkdownBody(
                            data: product.description,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyles.bodyMedium,
                              h1: TextStyles.titleLarge,
                              h2: TextStyles.titleMedium,
                              h3: TextStyles.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Loading indicator
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
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSm),
          height: 100,
          child: Row(
            children: [
              // Expanded(
              //   flex: 1,
              //   child: IconButton(
              //     icon: const Icon(Icons.favorite_border),
              //     onPressed: isLoading
              //         ? null
              //         : () {
              //             ScaffoldMessenger.of(context).showSnackBar(
              //               const SnackBar(
              //                 content: Text('찜 기능은 아직 준비중입니다'),
              //               ),
              //             );
              //           },
              //   ),
              // ),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.paddingSm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                    ),
                    minimumSize: const Size.fromHeight(48), // 최소 높이 명시적 설정
                  ),
                  onPressed: (isLoading || !product.isOnSale)
                      ? null
                      : () {
                          _addToCart(product, 1);
                        },
                  child: Text(
                    product.isOnSale ? '장바구니에 담기' : '판매 종료된 상품',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 이미지 갤러리 빌더 메서드
  Widget _buildImageGallery(ProductModel product) {
    final imageUrls = product.getAllImageUrls();

    if (imageUrls.isEmpty) {
      // 이미지가 없는 경우
      return AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          width: double.infinity,
          color: ColorPalette.placeholder,
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 64,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    if (imageUrls.length == 1) {
      // 단일 이미지인 경우 (기존 방식)
      return AspectRatio(
        aspectRatio: 1.0,
        child: CachedNetworkImage(
          imageUrl: imageUrls[0],
          width: double.infinity,
          fit: BoxFit.cover,
          memCacheHeight: 600,
          maxHeightDiskCache: 1200,
          placeholder: (context, url) => Container(
            width: double.infinity,
            color: ColorPalette.placeholder,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) {
            debugPrint('🖼️ 상품 상세 이미지 로드 실패: $url, 오류: $error');
            return Container(
              width: double.infinity,
              color: ColorPalette.placeholder,
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      );
    }

    // 여러 이미지인 경우 - PageView 사용
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: imageUrls[index],
                width: double.infinity,
                fit: BoxFit.cover,
                memCacheHeight: 600,
                maxHeightDiskCache: 1200,
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  color: ColorPalette.placeholder,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) {
                  debugPrint('🖼️ 상품 상세 이미지 로드 실패: $url, 오류: $error');
                  return Container(
                    width: double.infinity,
                    color: ColorPalette.placeholder,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // 이미지 인디케이터
        Container(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imageUrls.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? ColorPalette.primary
                      : ColorPalette.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🆕 픽업 포인트 정보 표시 위젯
  Widget _buildPickupPointInfo(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSm),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(Dimensions.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: ColorPalette.primary,
              ),
              const SizedBox(width: Dimensions.spacingXs),
              Text(
                '픽업 정보',
                style: TextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spacingXs),
          Text(
            '픽업 포인트 ${product.availablePickupPointIds.length}개 이용 가능',
            style: TextStyles.bodyMedium.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: Dimensions.spacingXs),
          Text(
            '주문 시 픽업 장소를 선택하실 수 있습니다.',
            style: TextStyles.bodySmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[500]
                  : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 OrderUnit 선택 아코디언 위젯
  Widget _buildOrderUnitSelector(ProductModel product) {
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '수량 선택',
              style: TextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.spacingSm),

            // OrderUnit 리스트
            Column(
              children: product.orderUnits.asMap().entries.map((entry) {
                final index = entry.key;
                final orderUnit = entry.value;
                final isSelected = _selectedOrderUnitIndex == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: Dimensions.spacingSm),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedOrderUnitIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSm),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSm),
                        border: Border.all(
                          color: isSelected
                              ? ColorPalette.primary
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected
                            ? ColorPalette.primary.withValues(alpha: 0.1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          // 선택 인디케이터
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? ColorPalette.primary
                                    : Theme.of(context).dividerColor,
                                width: 2,
                              ),
                              color: isSelected
                                  ? ColorPalette.primary
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  )
                                : null,
                          ),
                          const SizedBox(width: Dimensions.spacingSm),

                          // 수량 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  orderUnit.quantity,
                                  style: TextStyles.bodyLarge.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? ColorPalette.primary
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  priceFormat.format(orderUnit.price),
                                  style: TextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? ColorPalette.primary
                                        : ColorPalette.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(ProductModel product, int quantity) async {
    try {
      final cartRepository = ref.read(cartRepositoryProvider);

      // 🆕 선택된 OrderUnit 정보 가져오기
      final selectedOrderUnit = product.orderUnits.isNotEmpty
          ? product.orderUnits[_selectedOrderUnitIndex]
          : product.defaultOrderUnit;

      // 🆕 픽업 배송인 경우 기본 픽업 포인트 선택
      String? selectedPickupPointId;
      if (product.isPickupDelivery && product.hasPickupPoints) {
        selectedPickupPointId = product.availablePickupPointIds.first;
      }

      // 선택된 OrderUnit과 PickupPoint로 장바구니에 추가
      await cartRepository.addToCartWithOrderUnit(
        product,
        selectedOrderUnit,
        1,
        selectedPickupPointId: selectedPickupPointId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '장바구니에 추가되었습니다\n${product.name} - ${selectedOrderUnit.quantity} (+1개)',
            ),
            backgroundColor: ColorPalette.success,
            action: SnackBarAction(
              label: '장바구니 보기',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/cart');
              },
            ),
          ),
        );
      }
    } catch (e, s) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('장바구니에 추가하는데 실패했습니다: $e'),
            backgroundColor: ColorPalette.error,
          ),
        );
      }
    }
  }
}
