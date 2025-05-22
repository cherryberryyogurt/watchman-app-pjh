import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';

// Riverpod 코드 생성을 위한 part 파일 지정
part 'auth_providers.g.dart';

/// Firebase Auth의 사용자 인증 상태 변경 스트림을 제공하는 Provider입니다.
///
/// `idTokenChanges()`를 사용하여 토큰 갱신을 포함한 인증 상태 변경을 감지합니다.
@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  return FirebaseAuth.instance.idTokenChanges();
}

/// 현재 로그인된 Firebase User 객체를 동기적으로 제공하는 Provider입니다.
///
/// `authStateChangesProvider`를 watch하여 User 객체를 반환합니다.
/// 사용자가 로그인하지 않았거나 인증 상태가 아직 로드되지 않은 경우 null을 반환할 수 있습니다.
@riverpod
User? currentUser(CurrentUserRef ref) {
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
String? currentUserUid(CurrentUserUidRef ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
}

/// 인증 상태 초기화 시의 race condition을 안전하게 처리하는 향상된 UID Provider입니다.
/// 
/// 이 Provider는 UID가 null인 경우 Firebase Auth의 여러 상태 소스를 확인하여 
/// 더 안정적으로 사용자 ID를 제공합니다.
@riverpod
Future<String?> safeCurrentUserUid(SafeCurrentUserUidRef ref) async {
  // 이미 로그인된 상태인지 우선 확인 (가장 빠른 경로)
  final syncUid = ref.watch(currentUserUidProvider);
  if (syncUid != null) {
    return syncUid;
  }
  
  // 동기적 방법으로 가져오지 못했다면, 비동기적으로 Firebase Auth 상태 시도
  final auth = FirebaseAuth.instance;
  final currentUser = auth.currentUser;
  
  if (currentUser != null && currentUser.uid.isNotEmpty) {
    return currentUser?.uid;
  }
  
  // authStateChanges()에서 첫 번째 non-null 사용자 대기 (타임아웃 설정)
  try {
    final user = await auth.authStateChanges()
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
bool isCurrentUserEmailVerified(IsCurrentUserEmailVerifiedRef ref) {
  final user = ref.watch(currentUserProvider);
  return user?.emailVerified ?? false;
} 

//// TODO: 위와 같이 location 인증 관련 점검하는 코드 필요할 것.