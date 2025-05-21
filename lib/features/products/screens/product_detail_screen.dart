import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/product_state.dart';
import '../../../core/theme/index.dart';
import '../../cart/repositories/cart_repository.dart';
import '../models/product_model.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductDetails();
    });
  }

  @override
  void dispose() {
    // Clear the selected product when leaving
    ref.read(productProvider.notifier).clearSelectedProduct();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    try {
      await ref.read(productProvider.notifier).getProductDetails(widget.productId);
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

  void _incrementQuantity() {
    final product = ref.read(productProvider).selectedProduct;
    
    if (product != null && _quantity < product.stock) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _addToCart(ProductModel product, int quantity) async {
    try {
      final cartRepository = ref.read(cartRepositoryProvider);
      await cartRepository.addToCart(product, quantity);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '장바구니에 추가되었습니다\n${product.name}, 수량: $quantity',
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
    } catch (e) {
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
      final startFormatted = DateFormat('yyyy.MM.dd').format(product.startDate!);
      final endFormatted = DateFormat('yyyy.MM.dd').format(product.endDate!);
      saleDate = '$startFormatted ~ $endFormatted';
    } else if (product.startDate != null) {
      final startFormatted = DateFormat('yyyy.MM.dd').format(product.startDate!);
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
                    // Product Image
                    if (product.thumbnailUrl != null)
                      Image.network(
                        product.thumbnailUrl!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 300,
                        color: ColorPalette.placeholder,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    
                    // Main Info Section
                    Padding(
                      padding: const EdgeInsets.all(Dimensions.padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location Tag
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: ColorPalette.primary,
                              ),
                              const SizedBox(width: Dimensions.spacingSm),
                              Text(
                                product.locationTag,
                                style: TextStyles.bodyMedium,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSm,
                                  vertical: Dimensions.paddingXs,
                                ),
                                decoration: BoxDecoration(
                                  color: product.isOnSale 
                                    ? ColorPalette.success.withOpacity(0.2)
                                    : ColorPalette.error.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                                ),
                                child: Text(
                                  product.isOnSale ? '판매중' : '판매종료',
                                  style: TextStyles.bodySmall.copyWith(
                                    color: product.isOnSale ? ColorPalette.success : ColorPalette.error,
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
                          
                          // Product Price
                          Row(
                            children: [
                              Text(
                                priceFormat.format(product.price),
                                style: TextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: ColorPalette.primary,
                                ),
                              ),
                              Text(
                                ' / ${product.orderUnit}',
                                style: TextStyles.bodyMedium.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? ColorPalette.textSecondaryDark
                                      : ColorPalette.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          
                          const Divider(height: Dimensions.spacingLg * 2),
                          
                          // Delivery Type & Pickup Info
                          Row(
                            children: [
                              Icon(
                                product.deliveryType == '픽업' ? Icons.store : Icons.local_shipping,
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
                          
                          if (product.deliveryType == '픽업' && product.pickupInfo != null && product.pickupInfo!.isNotEmpty)
                            Container(
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
                                  if (product.pickupInfo!.length > 0)
                                    Text(
                                      '픽업 장소: ${product.pickupInfo![0]}',
                                      style: TextStyles.bodyMedium,
                                    ),
                                  if (product.pickupInfo!.length > 1)
                                    Text(
                                      '픽업 시간: ${product.pickupInfo![1]}',
                                      style: TextStyles.bodyMedium,
                                    ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: Dimensions.spacingMd),
                          
                          // Sale Period
                          Text(
                            '판매 기간',
                            style: TextStyles.titleMedium,
                          ),
                          const SizedBox(height: Dimensions.spacingSm),
                          Text(
                            saleDate,
                            style: TextStyles.bodyMedium,
                          ),
                          
                          const SizedBox(height: Dimensions.spacingMd),
                          
                          // Quantity
                          Row(
                            children: [
                              Text(
                                '수량',
                                style: TextStyles.titleMedium,
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: _decrementQuantity,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        _quantity.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyles.bodyLarge,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: _incrementQuantity,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: Dimensions.spacingLg),
                          
                          // Stock
                          Text(
                            '재고: ${product.stock}개',
                            style: TextStyles.bodyMedium,
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
          height: 80,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: isLoading ? null : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('찜 기능은 아직 준비중입니다'),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                flex: 4,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.padding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                    ),
                  ),
                  onPressed: (isLoading || !product.isOnSale) ? null : () {
                    _addToCart(product, _quantity);
                  },
                  child: Text(product.isOnSale ? '장바구니에 담기' : '판매 종료된 상품'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 