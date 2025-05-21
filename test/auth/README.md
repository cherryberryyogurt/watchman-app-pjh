# 인증 시스템 테스트

이 디렉토리에는 와치맨 앱의 인증 시스템(로그인, 회원가입, 로그아웃, 프로필 수정 등)에 대한 테스트 코드가 포함되어 있습니다.

## 테스트 종류

1. **단위 테스트** (`auth_provider_test.dart`)
   - Auth Provider의 각 메소드 기능 검증
   - 의존성 모킹을 통해 격리된 환경에서 테스트

2. **위젯 테스트** (`auth_screen_test.dart`)
   - 로그인, 회원가입 화면의 UI 및 상호작용 테스트
   - 폼 유효성 검사 기능 검증
   - Provider 오버라이드를 통한 의존성 모킹

3. **통합 테스트** (`auth_integration_test.dart`)
   - 실제 앱 환경에서의 전체 인증 흐름 테스트
   - 로그인 → 홈 화면 → 프로필 편집 → 로그아웃 등의 시나리오 테스트

## 테스트 실행 방법

### 단위 테스트 및 위젯 테스트 실행

```bash
# 모든 테스트 실행
flutter test test/auth/

# 특정 테스트 파일만 실행
flutter test test/auth/auth_provider_test.dart
flutter test test/auth/auth_screen_test.dart
```

### 통합 테스트 실행

통합 테스트는 실제 기기 또는 에뮬레이터에서 실행해야 합니다:

```bash
# 연결된 모든 기기에서 통합 테스트 실행
flutter test integration_test/auth_integration_test.dart

# 특정 기기에서만 실행
flutter test integration_test/auth_integration_test.dart -d {device_id}
```

## 테스트 데이터

단위 테스트와 위젯 테스트에서는 모킹된 데이터를 사용하므로 실제 Firebase 인증을 사용하지 않습니다.

통합 테스트에서는 실제 Firebase 인증을 사용하므로, 테스트를 실행하기 전에 다음 정보를 테스트 코드에 업데이트해야 합니다:

```dart
// auth_integration_test.dart
// 테스트용 계정 정보 업데이트
await tester.enterText(
  find.byType(TextFormField).first, 
  'your_test_email@example.com'  // 테스트 이메일로 변경
);
await tester.enterText(
  find.byType(TextFormField).at(1), 
  'your_test_password'  // 테스트 비밀번호로 변경
);
```

## 주의사항

1. 통합 테스트는 실제 Firebase 서비스를 호출하므로 테스트 환경에서만 실행해야 합니다.
2. 테스트가 끝나면 테스트에 사용된 계정의 데이터를 정리해야 합니다.
3. CI/CD 파이프라인에서 통합 테스트를 자동화할 경우, Firebase 에뮬레이터를 활용하는 것이 좋습니다. 