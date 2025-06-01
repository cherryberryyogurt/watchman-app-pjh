// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productRepositoryHash() => r'1143e6a957468f07814b030b8e53d8ea1ddb037b';

/// See also [productRepository].
@ProviderFor(productRepository)
final productRepositoryProvider =
    AutoDisposeProvider<ProductRepository>.internal(
  productRepository,
  name: r'productRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProductRepositoryRef = AutoDisposeProviderRef<ProductRepository>;
String _$productHash() => r'c6170bbd1c6b3efd9a16e68a201f29f9863673f6';

/// See also [Product].
@ProviderFor(Product)
final productProvider =
    AutoDisposeNotifierProvider<Product, ProductState>.internal(
  Product.new,
  name: r'productProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$productHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Product = AutoDisposeNotifier<ProductState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
