// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authRepositoryHash() => r'19a3485653561ac2f781b997131430c5659286d1';

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
String _$authStateChangesHash() => r'6cf7ee7bfdf61878e33cbc56574c0c31f15accbf';

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
String _$currentUserHash() => r'd2ff896dd1f3282351a8a2e96c77f500f36095d1';

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
String _$currentUserUidHash() => r'eee94144f75ccb79dc4386b8f714e4267108498c';

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
    r'0ae58071cdb66c3e0cd9d9aaa42e4187025a026b';

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
    r'7ce5908a61d1cce7646bf092b20bea7fe3eba38e';

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
String _$safeIsCurrentUserEmailVerifiedHash() =>
    r'e80d20d0ff3cef40cd4670a279168c2e251e1033';

/// 이메일 인증 상태를 안전하게 확인하는 향상된 Provider입니다.
///
/// 이 Provider는 Firebase Auth의 캐시된 상태가 최신이 아닐 수 있는 문제를 해결하기 위해
/// 서버에서 최신 상태를 reload하여 확인합니다.
///
/// Copied from [safeIsCurrentUserEmailVerified].
@ProviderFor(safeIsCurrentUserEmailVerified)
final safeIsCurrentUserEmailVerifiedProvider =
    AutoDisposeFutureProvider<bool>.internal(
  safeIsCurrentUserEmailVerified,
  name: r'safeIsCurrentUserEmailVerifiedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$safeIsCurrentUserEmailVerifiedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SafeIsCurrentUserEmailVerifiedRef = AutoDisposeFutureProviderRef<bool>;
String _$isCurrentUserLocationVerifiedHash() =>
    r'8ed5794eb039857a0c497ae07d8554a2665fb399';

/// See also [isCurrentUserLocationVerified].
@ProviderFor(isCurrentUserLocationVerified)
final isCurrentUserLocationVerifiedProvider =
    AutoDisposeFutureProvider<bool>.internal(
  isCurrentUserLocationVerified,
  name: r'isCurrentUserLocationVerifiedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isCurrentUserLocationVerifiedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsCurrentUserLocationVerifiedRef = AutoDisposeFutureProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
