import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/product_provider.dart';
import '../widgets/image_slider.dart';
import '../widgets/option_accordion.dart';
import '../../../core/theme/index.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, String> _selectedOptions = {};
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
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.clearSelectedProduct();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    try {
      await Provider.of<ProductProvider>(context, listen: false)
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

  void _onOptionSelected(String optionName, String value) {
    setState(() {
      _selectedOptions[optionName] = value;
    });
  }

  void _incrementQuantity() {
    final product = Provider.of<ProductProvider>(context, listen: false).selectedProduct;
    
    if (product != null && (product.stock == null || _quantity < product.stock!)) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          final product = provider.selectedProduct;
          final status = provider.status;
          final errorMessage = provider.errorMessage;

          if (status == ProductLoadStatus.loading && product == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (status == ProductLoadStatus.error) {
            return Center(
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
            );
          }

          if (product == null) {
            return const Center(
              child: Text('상품을 찾을 수 없습니다'),
            );
          }

          // Initialize options if needed
          if (product.options != null && 
              product.options!.isNotEmpty && 
              _selectedOptions.isEmpty) {
            for (final option in product.options!) {
              final name = option['name'] as String;
              final values = option['values'] as List<dynamic>;
              if (values.isNotEmpty) {
                _selectedOptions[name] = values.first as String;
              }
            }
          }

          // Format price
          final priceFormat = NumberFormat.currency(
            locale: 'ko_KR',
            symbol: '₩',
            decimalDigits: 0,
          );

          return CustomScrollView(
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
                    // Image Slider
                    ImageSlider(
                      imageUrls: product.imageUrls,
                      aspectRatio: 1.0,
                    ),
                    
                    // Main Info Section
                    Padding(
                      padding: const EdgeInsets.all(Dimensions.padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Seller Info
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: ColorPalette.primary,
                                radius: 16,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: Dimensions.spacingSm),
                              Text(
                                product.sellerName,
                                style: TextStyles.bodyMedium,
                              ),
                              const SizedBox(width: Dimensions.spacingSm),
                              Text(
                                product.location,
                                style: TextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? ColorPalette.textSecondaryDark
                                      : ColorPalette.textSecondaryLight,
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
                          Text(
                            priceFormat.format(product.price),
                            style: TextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ColorPalette.primary,
                            ),
                          ),
                          
                          const Divider(height: Dimensions.spacingLg * 2),
                          
                          // Options
                          if (product.options != null && product.options!.isNotEmpty) ...[
                            Text(
                              '옵션 선택',
                              style: TextStyles.titleMedium,
                            ),
                            const SizedBox(height: Dimensions.spacingSm),
                            OptionAccordion(
                              options: product.options!,
                              onOptionSelected: _onOptionSelected,
                              selectedOptions: _selectedOptions,
                            ),
                            const SizedBox(height: Dimensions.spacingMd),
                          ],
                          
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
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        _quantity.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyles.titleMedium,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: _incrementQuantity,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const Divider(height: Dimensions.spacingLg * 2),
                          
                          // Product Description
                          Text(
                            '상품 설명',
                            style: TextStyles.titleMedium,
                          ),
                          const SizedBox(height: Dimensions.spacingSm),
                          MarkdownBody(
                            data: product.description,
                            styleSheet: MarkdownStyleSheet(
                              h1: TextStyles.headlineMedium,
                              h2: TextStyles.headlineSmall,
                              h3: TextStyles.titleLarge,
                              p: TextStyles.bodyMedium,
                              listBullet: TextStyles.bodyMedium,
                            ),
                          ),
                          
                          const SizedBox(height: Dimensions.spacingLg),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          final product = provider.selectedProduct;
          
          if (product == null) {
            return const SizedBox.shrink();
          }
          
          // Calculate total price
          double totalPrice = product.price * _quantity;
          
          // Check for additional price in options
          if (_selectedOptions.isNotEmpty) {
            for (final entry in _selectedOptions.entries) {
              final value = entry.value;
              if (value.contains('+')) {
                final priceStr = value.split('+')[1].trim();
                if (priceStr.contains('원')) {
                  final additionalPrice = double.tryParse(
                    priceStr.replaceAll('원', '').replaceAll(',', '').trim(),
                  );
                  if (additionalPrice != null) {
                    totalPrice += additionalPrice * _quantity;
                  }
                }
              }
            }
          }
          
          // Format price
          final priceFormat = NumberFormat.currency(
            locale: 'ko_KR',
            symbol: '₩',
            decimalDigits: 0,
          );
          
          return Container(
            padding: const EdgeInsets.all(Dimensions.padding),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '총 금액',
                      style: TextStyles.bodySmall,
                    ),
                    Text(
                      priceFormat.format(totalPrice),
                      style: TextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: Dimensions.spacingMd),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement checkout
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('결제 금액: ${priceFormat.format(totalPrice)}'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSm),
                    ),
                    child: const Text('결제하기'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 