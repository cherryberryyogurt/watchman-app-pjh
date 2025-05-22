// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$kakaoMapServiceHash() => r'9e7b3c8d5f6d0b39a7c4e1d8b5a2f0c7e4b9d6a3';

/// See also [kakaoMapService].
@ProviderFor(kakaoMapService)
final kakaoMapServiceProvider = AutoDisposeProvider<KakaoMapService>.internal(
  kakaoMapService,
  name: r'kakaoMapServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$kakaoMapServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef KakaoMapServiceRef = AutoDisposeProviderRef<KakaoMapService>;
String _$signUpHash() => r'f0e1d2c3b4a5968778695a4b3c2d1e0f9a8b7c6d';

/// See also [SignUp].
@ProviderFor(SignUp)
final signUpProvider =
    AutoDisposeAsyncNotifierProvider<SignUp, SignUpState>.internal(
  SignUp.new,
  name: r'signUpProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$signUpHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SignUp = AutoDisposeAsyncNotifier<SignUpState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member 