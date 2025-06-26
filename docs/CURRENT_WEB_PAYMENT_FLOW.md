# 현재 웹 결제 흐름 문서

## 작업 시작일: 2024년 12월 현재

### 1. 현재 구조

#### 웹 결제 관련 파일들:
- `lib/core/widgets/web_toss_payments_widget_web.dart` (431줄) - 웹 전용 토스페이먼츠 위젯
- `lib/core/widgets/web_toss_payments_widget_stub.dart` (69줄) - 모바일용 스텁
- `lib/features/order/screens/payment_screen.dart` - 조건부 import로 웹/모바일 분기
- `lib/features/order/widgets/toss_payments_webview.dart` - WebView 기반 결제 (웹 스크립트 포함)

### 2. 현재 웹 결제 흐름

1. **결제 요청 시작**
   - `PaymentScreen`에서 `kIsWeb` 조건으로 웹/모바일 분기
   - 웹: `WebTossPaymentsWidget` 사용
   - 모바일: `TossPaymentsWebView` 사용

2. **웹 결제 프로세스**
   - `WebTossPaymentsWidget`이 DOM을 직접 조작
   - `dart:html`과 `package:web/web.dart` 사용
   - JavaScript interop으로 토스페이먼츠 SDK v2 호출
   - HtmlElementView로 결제 UI 렌더링

3. **결제 결과 처리**
   - JavaScript postMessage로 Flutter와 통신
   - 성공/실패 결과를 콜백으로 전달

### 3. 문제점

1. **복잡성**
   - Flutter 웹에서 DOM 직접 조작의 복잡성
   - JavaScript interop 코드 유지보수 어려움

2. **안정성**
   - Flutter 웹 버전 업데이트 시 호환성 문제 가능성
   - 브라우저별 동작 차이 처리 복잡

3. **디버깅**
   - Flutter 웹과 JavaScript 간 디버깅 어려움
   - 에러 추적 복잡

### 4. 개선 방향

독립적인 HTML 결제 페이지로 분리하여:
- 결제 로직을 순수 HTML/JavaScript로 구현
- Flutter는 단순히 결제 페이지로 리다이렉트
- 결제 결과를 URL 파라미터나 postMessage로 수신

### 5. 예상 효과

- 코드 복잡도 감소
- 유지보수성 향상
- 브라우저 호환성 개선
- 디버깅 용이성 증가 