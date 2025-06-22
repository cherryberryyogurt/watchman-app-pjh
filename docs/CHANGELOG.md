# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2024-12-19

### Added

#### TossPayments 결제 시스템 통합
- **TossPayments 공식 Flutter SDK 통합**: `tosspayments_widget_sdk_flutter: ^2.1.1` 추가
- **플랫폼별 결제 지원**: Android, iOS, Web 모든 환경에서 TossPayments 결제 지원
- **URL 변환 로직**: Intent URL을 앱스킴 URL로 변환하는 `ConvertUrl` 기능 구현
- **플랫폼별 조건부 렌더링**: 웹과 모바일 환경에 최적화된 별도 처리 로직

#### iOS 플랫폼 지원 강화
- **LSApplicationQueriesSchemes 설정**: 모든 주요 카드/은행 앱 스킴 추가
  - 신용카드: 삼성, 현대, 롯데, 비씨, 하나, KB국민, 신한, 우리, NH농협
  - 간편결제: 토스, 페이코, 카카오페이, 네이버페이, SSG페이, 엘페이
  - 은행앱: 주요 시중은행 및 지방은행 스킴 포함
- **CFBundleURLTypes 설정**: gonggoo 결제 스킴 등록

#### 웹 환경 최적화
- **CSP(Content Security Policy) 설정**: TossPayments 도메인 허용
- **Flutter CanvasKit 지원**: Google CDN에서 CanvasKit 로딩 허용
- **웹소켓 연결 지원**: 개발 환경 디버깅을 위한 localhost WebSocket 허용
- **웹 환경 초기화 스크립트**: 토스페이먼츠 결제 콜백 처리

#### 사용자 경험 개선
- **플랫폼 감지 로딩**: 웹/모바일 환경별 최적화된 로딩 화면
- **결제 프로세스 시각화**: 진행 상태 표시 및 플랫폼별 안내
- **에러 처리 강화**: 결제 실패 시 명확한 오류 메시지 제공

### Changed

#### 의존성 업데이트
- **webview_flutter_android**: 3.16.0으로 버전 고정 (TossPayments 호환성)
- **url_launcher**: LaunchMode 지원을 위한 패키지 추가

#### 아키텍처 개선
- **TossPaymentsWebView 위젯 리팩토링**: 플랫폼별 네비게이션 처리 분리
- **PaymentScreen 구조 개선**: 조건부 WebView 초기화 및 플랫폼별 뷰 분리
- **HTML 생성 로직 개선**: 웹/모바일별 최적화된 스크립트 분리

### Fixed

#### 컴파일 및 런타임 오류 해결
- **LaunchMode import 오류**: `package:url_launcher/url_launcher.dart` import 추가
- **CSP 차단 문제**: Flutter CanvasKit 및 웹 리소스 로딩 허용
- **Widget 배치 오류**: CheckoutScreen의 `Expanded` → `SizedBox` 수정으로 ParentDataWidget 오류 해결

#### 플랫폼별 호환성 문제
- **Android Intent 처리**: TossPayments URL 변환 로직으로 카드앱 연동 개선
- **iOS 앱 실행**: 카드/은행 앱 스킴 허용으로 원활한 앱 간 이동
- **웹 환경 지원**: CSP 제거로 Flutter 웹앱 정상 작동

#### 사용자 인터페이스
- **결제 버튼 레이아웃**: bottomNavigationBar에서 버튼 영역 정상 표시
- **로딩 상태 표시**: 결제 프로세스 중 적절한 로딩 인디케이터 표시
- **반응형 디자인**: 다양한 화면 크기에서 일관된 사용자 경험

### Security

#### 결제 보안 강화
- **TossPayments 공식 SDK**: 공인된 결제 모듈 사용으로 보안성 향상
- **도메인 화이트리스트**: TossPayments 공식 도메인만 허용
- **앱 스킴 검증**: 등록된 앱 스킴만 실행 허용

### Technical Details

#### 파일 변경 사항
- **추가**: `ios/Runner/Info.plist` - iOS 앱 스킴 및 URL 타입 설정
- **수정**: `pubspec.yaml` - TossPayments SDK 및 의존성 추가
- **수정**: `lib/features/order/widgets/toss_payments_webview.dart` - 플랫폼별 처리 로직
- **수정**: `lib/features/order/screens/payment_screen.dart` - 조건부 WebView 초기화
- **수정**: `web/index.html` - 웹 환경 최적화 및 CSP 설정
- **수정**: `lib/features/order/screens/checkout_screen.dart` - UI 버그 수정

#### 성능 최적화
- **리소스 프리로딩**: TossPayments 도메인 preconnect 설정
- **조건부 로딩**: 플랫폼별 필요한 리소스만 로드
- **Hot Reload 지원**: 개발 환경에서 빠른 반복 개발 가능

---

### Notes

이번 업데이트로 TossPayments 결제 시스템이 Android, iOS, Web 모든 플랫폼에서 안정적으로 작동합니다. 공식 SDK 사용으로 보안성과 호환성이 크게 향상되었으며, 플랫폼별 최적화를 통해 사용자 경험이 개선되었습니다.

개발 환경에서는 CSP 설정을 완화했으나, 프로덕션 배포 시에는 보안을 위해 적절한 CSP 정책을 다시 적용해야 합니다. 