// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$kakaoMapServiceHash() => r'95bb38a7b9c265286d5f62962db877bae0bed5ee';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef KakaoMapServiceRef = AutoDisposeProviderRef<KakaoMapService>;
String _$signUpHash() => r'024133995aace190bd0a0965fc71da87d9d7fce0';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
