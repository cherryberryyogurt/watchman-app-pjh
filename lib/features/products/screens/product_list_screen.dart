import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_list_item.dart';
import 'product_detail_screen.dart';
import '../../../core/theme/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductListScreen extends StatefulWidget {
  static const String routeName = '/products';

  const ProductListScreen({Key? key}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    try {
      await context.read<ProductProvider>().loadProducts();
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
      await context.read<ProductProvider>().addDummyProducts();
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
      {'name': '전체', 'coordinates': null},
      {'name': '강남구', 'coordinates': const GeoPoint(37.4988, 127.0281)},
      {'name': '서초구', 'coordinates': const GeoPoint(37.4923, 127.0292)},
      {'name': '송파구', 'coordinates': const GeoPoint(37.5145, 127.1057)},
      {'name': '영등포구', 'coordinates': const GeoPoint(37.5257, 126.8957)},
      {'name': '강서구', 'coordinates': const GeoPoint(37.5509, 126.8495)},
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
                  final provider = context.read<ProductProvider>();
                  provider.setLocation(
                    location['name'] as String,
                    location['coordinates'] as GeoPoint?,
                  );

                  if (location['coordinates'] != null) {
                    provider.loadProductsByLocation(
                      location['coordinates'] as GeoPoint,
                      10, // 10km radius
                    );
                  } else {
                    provider.loadProducts();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _showLocationSelector,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  return Text(provider.currentLocation);
                },
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addDummyProducts,
            tooltip: '더미 상품 추가',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: Consumer<ProductProvider>(
          builder: (context, provider, child) {
            final status = provider.status;
            final products = provider.products;
            final errorMessage = provider.errorMessage;

            if (status == ProductLoadStatus.loading && products.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (status == ProductLoadStatus.error && products.isEmpty) {
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
                      onPressed: _loadProducts,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_basket,
                      size: 64,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: Dimensions.spacingMd),
                    Text(
                      '상품이 없습니다',
                      style: TextStyles.titleMedium,
                    ),
                    const SizedBox(height: Dimensions.spacingSm),
                    Text(
                      '상단의 + 버튼을 눌러 더미 상품을 추가해보세요',
                      style: TextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: Dimensions.spacingLg),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductListItem(
                  product: product,
                  onTap: () => _navigateToProductDetail(product.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 