// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cartRepositoryHash() => r'3c860e0751a74b54370e20bfbd9583f00b8a33e2';

/// See also [cartRepository].
@ProviderFor(cartRepository)
final cartRepositoryProvider = AutoDisposeProvider<CartRepository>.internal(
  cartRepository,
  name: r'cartRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cartRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartRepositoryRef = AutoDisposeProviderRef<CartRepository>;
String _$cartHash() => r'8a6c18393a841c2f76dbf0c65cca6cd89b3435d3';

/// See also [Cart].
@ProviderFor(Cart)
final cartProvider = AutoDisposeNotifierProvider<Cart, CartState>.internal(
  Cart.new,
  name: r'cartProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cartHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Cart = AutoDisposeNotifier<CartState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
