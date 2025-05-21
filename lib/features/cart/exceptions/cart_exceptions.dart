/// 사용자가 로그인하지 않았을 때 발생하는 예외입니다.
class UserNotLoggedInException implements Exception {
  final String message;
  UserNotLoggedInException([this.message = '로그인이 필요합니다. 먼저 로그인해주세요.']);
  @override
  String toString() => message;
}

/// 사용자의 이메일이 인증되지 않았을 때 발생하는 예외입니다.
class EmailNotVerifiedException implements Exception {
  final String message;
  EmailNotVerifiedException([this.message = '이메일 인증이 필요합니다. 이메일 확인 후 다시 시도해주세요.']);
  @override
  String toString() => message;
}

/// Firestore 작업 중 오류가 발생했을 때 사용되는 일반적인 예외입니다.
class FirestoreOperationException implements Exception {
  final String message;
  final dynamic originalException; // 원본 예외를 포함할 수 있도록 합니다.

  FirestoreOperationException(this.message, [this.originalException]);

  @override
  String toString() {
    if (originalException != null) {
      return 'Firestore 작업 오류: $message (원본 오류: $originalException)';
    }
    return 'Firestore 작업 오류: $message';
  }
} 