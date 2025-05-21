// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authStateChangesHash() => r'7ea3d420751477a00de8f42c20566158abb15333';

/// Firebase Auth의 사용자 인증 상태 변경 스트림을 제공하는 Provider입니다.
///
/// `idTokenChanges()`를 사용하여 토큰 갱신을 포함한 인증 상태 변경을 감지합니다.
///
/// Copied from [authStateChanges].
@ProviderFor(authStateChanges)
final authStateChangesProvider = AutoDisposeStreamProvider<User?>.internal(
  authStateChanges,
  name: r'authStateChangesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStateChangesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateChangesRef = AutoDisposeStreamProviderRef<User?>;
String _$currentUserHash() => r'82957be8b94e648f0db764c83b3e65d3b66f97e4';

/// 현재 로그인된 Firebase User 객체를 동기적으로 제공하는 Provider입니다.
///
/// `authStateChangesProvider`를 watch하여 User 객체를 반환합니다.
/// 사용자가 로그인하지 않았거나 인증 상태가 아직 로드되지 않은 경우 null을 반환할 수 있습니다.
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeProvider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeProviderRef<User?>;
String _$currentUserUidHash() => r'3aedda0109a262d806fa5382ee3bd2778c367f5b';

/// 현재 로그인된 사용자의 UID를 문자열 형태로 제공하는 Provider입니다.
///
/// `currentUserProvider`를 통해 User 객체를 얻고, 해당 객체의 uid를 반환합니다.
/// 사용자가 로그인하지 않은 경우 null을 반환합니다.
///
/// Copied from [currentUserUid].
@ProviderFor(currentUserUid)
final currentUserUidProvider = AutoDisposeProvider<String?>.internal(
  currentUserUid,
  name: r'currentUserUidProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserUidHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserUidRef = AutoDisposeProviderRef<String?>;
String _$safeCurrentUserUidHash() =>
    r'd83ea403b1d7075ffe1d0377fb5d842a03ea4c2e';

/// 인증 상태 초기화 시의 race condition을 안전하게 처리하는 향상된 UID Provider입니다.
///
/// 이 Provider는 UID가 null인 경우 Firebase Auth의 여러 상태 소스를 확인하여
/// 더 안정적으로 사용자 ID를 제공합니다.
///
/// Copied from [safeCurrentUserUid].
@ProviderFor(safeCurrentUserUid)
final safeCurrentUserUidProvider = AutoDisposeFutureProvider<String?>.internal(
  safeCurrentUserUid,
  name: r'safeCurrentUserUidProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$safeCurrentUserUidHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SafeCurrentUserUidRef = AutoDisposeFutureProviderRef<String?>;
String _$isCurrentUserEmailVerifiedHash() =>
    r'c8763fb17b3ca2c0bed5edf8fa6c479de3a70597';

/// 현재 로그인된 사용자의 이메일 인증 완료 여부를 boolean 값으로 제공하는 Provider입니다.
///
/// `currentUserProvider`를 통해 User 객체를 얻고, 해당 객체의 `emailVerified` 속성을 반환합니다.
/// 사용자가 없거나 User 객체에 `emailVerified` 속성이 없는 경우 (예: 익명 사용자) false를 반환합니다.
///
/// Copied from [isCurrentUserEmailVerified].
@ProviderFor(isCurrentUserEmailVerified)
final isCurrentUserEmailVerifiedProvider = AutoDisposeProvider<bool>.internal(
  isCurrentUserEmailVerified,
  name: r'isCurrentUserEmailVerifiedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isCurrentUserEmailVerifiedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsCurrentUserEmailVerifiedRef = AutoDisposeProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
