// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authRepositoryHash() => r'e3b22fd7863ea1be0b322870da43112c60f80087';

/// See also [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = AutoDisposeProvider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = AutoDisposeProviderRef<AuthRepository>;
String _$authIntegrityServiceHash() =>
    r'7cf6244239b84b8ad4df8d06a005fe3c8316009a';

/// See also [authIntegrityService].
@ProviderFor(authIntegrityService)
final authIntegrityServiceProvider =
    AutoDisposeProvider<AuthIntegrityService>.internal(
  authIntegrityService,
  name: r'authIntegrityServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authIntegrityServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthIntegrityServiceRef = AutoDisposeProviderRef<AuthIntegrityService>;
String _$authHash() => r'79b41eb69cbd62f6cadb69b8cd3ee6eef5ada3ce';

/// See also [Auth].
@ProviderFor(Auth)
final authProvider =
    AutoDisposeStreamNotifierProvider<Auth, AuthState>.internal(
  Auth.new,
  name: r'authProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Auth = AutoDisposeStreamNotifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
