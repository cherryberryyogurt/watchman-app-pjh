당신은 Flutter + Riverpod 앱에서 Firebase Authentication을 사용하는 앱의 개발을 도와주는 Firebase 전문가입니다.

다음 요구사항을 바탕으로 Firebase 인증 상태를 반영한 장바구니(Cart) 기능을 설계하고, 예외 상황에도 안전하게 동작할 수 있는 구조를 제안해주세요.

---

### [요구사항]

1. `FirebaseAuth.instance.idTokenChanges()` 스트림을 통해 로그인 상태를 앱 전역에서 관리하고 싶습니다.
2. 이 스트림은 Riverpod의 `StreamProvider<User?>`로 래핑하여 앱 전체에서 사용자 상태를 공유합니다.
3. `CartRepository`에서는 로그인된 사용자의 UID를 활용해 Firestore의 사용자 장바구니 정보를 읽거나 쓰게 됩니다.
4. `CartRepository`는 인증 상태 관리자로부터 UID를 전달받되, 사용자가 로그인하지 않았거나 인증 상태가 불확실한 경우에는 예외 처리를 하고 싶습니다.

---

### [반영하고 싶은 보완 사항]

- 앱 시작 시점 또는 로그인 직후 사용자 정보가 아직 null일 수 있는 상태를 안정적으로 처리하고 싶습니다.
- 이메일 인증이 완료되지 않은 사용자가 장바구니를 사용할 수 없도록 제한하고 싶습니다.
- CartRepository는 인증 상태를 직접 참조하지 않고 Provider로 주입받아 테스트 가능한 구조를 유지하고 싶습니다.

---

### [원하는 결과물]

1. 인증 상태를 관리하는 Riverpod Provider 설계
2. 사용자 UID만을 안전하게 추출해주는 Provider 설계
3. CartRepository에서 UID를 안전하게 가져와서 Firestore 작업을 수행하는 구조
4. 로그인되지 않았거나 이메일 인증이 완료되지 않았을 때의 적절한 예외 처리 방식
5. 테스트를 고려한 구조적 설계 또는 DI 방식 제안
6. FirebaseAuth 상태가 null → user로 전이되는 초기 구간에서 생길 수 있는 race condition 대응 설계

코드는 최신 Riverpod 스타일(Riverpod 2 기준)로 작성해주세요.