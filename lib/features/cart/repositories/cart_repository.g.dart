// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseFirestoreHash() => r'963402713bf9b7cc1fb259d619d9b0184d4dcec1';

/// FirebaseFirestore 인스턴스를 제공하는 Provider입니다.
/// 테스트 시 Mock 객체로 대체하기 용이하도록 별도 Provider로 분리합니다.
///
/// Copied from [firebaseFirestore].
@ProviderFor(firebaseFirestore)
final firebaseFirestoreProvider =
    AutoDisposeProvider<FirebaseFirestore>.internal(
  firebaseFirestore,
  name: r'firebaseFirestoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firebaseFirestoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseFirestoreRef = AutoDisposeProviderRef<FirebaseFirestore>;
String _$cartRepositoryHash() => r'c858cb8710af8f758faee0eaf40b13547526fa3f';

/// CartRepository 인스턴스를 제공하는 Provider입니다.
///
/// Copied from [cartRepository].
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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
