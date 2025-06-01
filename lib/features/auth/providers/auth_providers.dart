import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 추가
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/auth_repository.dart'; // 추가
import 'dart:async';

// Riverpod 코드 생성을 위한 part 파일 지정
part 'auth_providers.g.dart';

// AuthRepository Provider 추가
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

/// Firebase Auth의 사용자 인증 상태 변경 스트림을 제공하는 Provider입니다.
///
/// `idTokenChanges()`를 사용하여 토큰 갱신을 포함한 인증 상태 변경을 감지합니다.
@riverpod
Stream<User?> authStateChanges(Ref ref) {
  return FirebaseAuth.instance.idTokenChanges();
}

/// 현재 로그인된 Firebase User 객체를 동기적으로 제공하는 Provider입니다.
///
/// `authStateChangesProvider`를 watch하여 User 객체를 반환합니다.
/// 사용자가 로그인하지 않았거나 인증 상태가 아직 로드되지 않은 경우 null을 반환할 수 있습니다.
@riverpod
User? currentUser(Ref ref) {
  // authStateChangesProvider의 AsyncValue<User?> 상태를 구독합니다.
  final asyncUser = ref.watch(authStateChangesProvider);
  // 데이터가 있으면 User 객체를, 그렇지 않으면 null을 반환합니다.
  return asyncUser.valueOrNull;
}

/// 현재 로그인된 사용자의 UID를 문자열 형태로 제공하는 Provider입니다.
///
/// `currentUserProvider`를 통해 User 객체를 얻고, 해당 객체의 uid를 반환합니다.
/// 사용자가 로그인하지 않은 경우 null을 반환합니다.
@riverpod
String? currentUserUid(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
}

/// 인증 상태 초기화 시의 race condition을 안전하게 처리하는 향상된 UID Provider입니다.
///
/// 이 Provider는 UID가 null인 경우 Firebase Auth의 여러 상태 소스를 확인하여
/// 더 안정적으로 사용자 ID를 제공합니다.
@riverpod
Future<String?> safeCurrentUserUid(Ref ref) async {
  // 이미 로그인된 상태인지 우선 확인 (가장 빠른 경로)
  final syncUid = ref.watch(currentUserUidProvider);
  if (syncUid != null) {
    return syncUid;
  }

  // 동기적 방법으로 가져오지 못했다면, 비동기적으로 Firebase Auth 상태 시도
  final auth = FirebaseAuth.instance;
  final currentUser = auth.currentUser;

  if (currentUser != null && currentUser.uid.isNotEmpty) {
    return currentUser.uid;
  }

  // authStateChanges()에서 첫 번째 non-null 사용자 대기 (타임아웃 설정)
  try {
    final user = await auth
        .authStateChanges()
        .where((user) => user != null)
        .first
        .timeout(const Duration(seconds: 3))
        .then((user) => user!);
    return user.uid;
  } on TimeoutException {
    // 타임아웃 발생 시 null 반환 (로그인되지 않은 상태로 간주)
    return null;
  } catch (e) {
    // 다른 예외 발생 시 null 반환
    return null;
  }
}

/// 현재 로그인된 사용자의 이메일 인증 완료 여부를 boolean 값으로 제공하는 Provider입니다.
///
/// `currentUserProvider`를 통해 User 객체를 얻고, 해당 객체의 `emailVerified` 속성을 반환합니다.
/// 사용자가 없거나 User 객체에 `emailVerified` 속성이 없는 경우 (예: 익명 사용자) false를 반환합니다.
@riverpod
bool isCurrentUserEmailVerified(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.emailVerified ?? false;
}

/// 이메일 인증 상태를 안전하게 확인하는 향상된 Provider입니다.
///
/// 이 Provider는 Firebase Auth의 캐시된 상태가 최신이 아닐 수 있는 문제를 해결하기 위해
/// 서버에서 최신 상태를 reload하여 확인합니다.
@riverpod
Future<bool> safeIsCurrentUserEmailVerified(Ref ref) async {
  print('🔍 SafeEmailVerification: Starting email verification check...');

  // 먼저 동기적으로 확인
  final syncEmailVerified = ref.watch(isCurrentUserEmailVerifiedProvider);
  print('🔍 SafeEmailVerification: Sync email verified = $syncEmailVerified');

  if (syncEmailVerified) {
    print(
        '🔍 SafeEmailVerification: Already verified via sync, returning true');
    return true; // 이미 인증된 경우 바로 반환
  }

  // 동기적 확인에서 false가 나온 경우, Firebase Auth에서 최신 상태 확인
  final auth = FirebaseAuth.instance;
  final currentUser = auth.currentUser;

  if (currentUser == null) {
    print('🔍 SafeEmailVerification: No current user, returning false');
    return false; // 로그인되지 않은 경우
  }

  print('🔍 SafeEmailVerification: Current user exists: ${currentUser.uid}');
  print(
      '🔍 SafeEmailVerification: Initial emailVerified state: ${currentUser.emailVerified}');
  print('🔍 SafeEmailVerification: User email: ${currentUser.email}');

  try {
    // 사용자 정보를 서버에서 다시 로드하여 최신 상태 확인
    print('🔍 SafeEmailVerification: Reloading user from server...');
    await currentUser.reload();

    // reload 후 다시 currentUser를 가져와서 emailVerified 확인
    final refreshedUser = auth.currentUser;
    final isVerified = refreshedUser?.emailVerified ?? false;
    print(
        '🔍 SafeEmailVerification: After reload, emailVerified = $isVerified');

    if (!isVerified) {
      // 토큰이 만료되었을 수 있으니 토큰 갱신 시도
      try {
        print('🔍 SafeEmailVerification: Forcing token refresh...');
        await currentUser.getIdToken(true); // force refresh
        await currentUser.reload(); // 다시 reload
        final finalUser = auth.currentUser;
        final finalVerified = finalUser?.emailVerified ?? false;
        print(
            '🔍 SafeEmailVerification: After token refresh and reload, emailVerified = $finalVerified');
        return finalVerified;
      } catch (tokenError) {
        print('🔍 SafeEmailVerification: Failed to refresh token: $tokenError');
        return isVerified; // 토큰 갱신 실패 시 reload 결과 사용
      }
    }

    return isVerified;
  } catch (e) {
    // reload 실패 시 (네트워크 오류, 토큰 만료 등) 캐시된 값 사용
    print('🔍 SafeEmailVerification: Failed to reload user: $e');
    print(
        '🔍 SafeEmailVerification: Returning cached value: ${currentUser.emailVerified}');
    return currentUser.emailVerified;
  }
}

// 현재 사용자의 위치 인증 상태를 제공하는 Provider
@riverpod
Future<bool> isCurrentUserLocationVerified(Ref ref) async {
  final uid = await ref.watch(safeCurrentUserUidProvider.future);
  if (uid == null) return false;

  // Firestore에서 사용자의 위치 인증 상태 확인
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

  return userDoc.data()?['isAddressVerified'] ?? false;
}
