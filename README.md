# 당근마켓 스타일 시스템

Flutter 기반 당근마켓(Danggeun Market) 스타일 시스템입니다. 애플 디자인 가이드와 토스 Product Principles를 따르면서 당근마켓 디자인을 재현했습니다.

## 구성 요소

### 테마 시스템

- **색상 팔레트**: 당근마켓의 오렌지 계열 브랜드 컬러와 다크 모드를 위한 컬러 시스템
- **타이포그래피**: 애플 디자인 가이드라인을 따르는 텍스트 스타일
- **치수 및 간격**: 일관된 간격과 크기를 위한 dimensions 시스템
- **스타일**: 버튼, 카드, 태그 등 UI 요소의 재사용 가능한 스타일
- **테마 제공자**: 라이트/다크 모드 전환 기능 구현

### 디자인 원칙

1. **일관성**: 모든 UI 요소에 일관된 스타일 적용
2. **다크 모드 지원**: 스크린샷을 기반으로 한 다크 모드 우선 디자인
3. **확장성**: 새로운 UI 요소를 쉽게 추가할 수 있는 구조
4. **접근성**: 가독성과 사용성을 고려한 디자인

## 기술 스택

- Flutter SDK
- Dart
- Provider (상태 관리)

## 시작하기

```bash
# 종속성 설치
flutter pub get

# 앱 실행
flutter run
```

## 구조

```
lib/
├── core/
│   └── theme/
│       ├── app_theme.dart       # 메인 테마 정의
│       ├── color_palette.dart   # 색상 팔레트
│       ├── dimensions.dart      # 간격 및 크기 시스템
│       ├── styles.dart          # 공통 스타일
│       ├── text_styles.dart     # 텍스트 스타일
│       ├── theme_provider.dart  # 테마 상태 관리
│       └── index.dart           # 배럴 파일
└── main.dart                    # 앱 진입점 및 스타일 샘플
```

## 스타일 가이드

### 컬러 팔레트

- **브랜드 컬러**: #FF7E36 (당근마켓 오렌지)
- **다크 모드 배경**: #121212
- **다크 모드 표면**: #1E1E1E
- **다크 모드 텍스트**: #F2F2F2 (기본), #BBBBBB (보조)

### 타이포그래피

- **본문 텍스트**: Pretendard 15pt
- **제목**: Pretendard 18pt Bold
- **헤드라인**: Pretendard 22pt Bold
- **가격 텍스트**: Pretendard 18pt Bold

### 컴포넌트 스타일

- **버튼**: 라운드 코너(16pt), 오렌지 배경(#FF7E36)
- **카드**: 라운드 코너(12pt), 그림자 없음(다크 모드)
- **태그**: 짧은 라운드 코너(8pt), 진한 회색 배경(#2C2C2C)
- **칩**: 긴 라운드 코너(24pt), 진한 회색 배경(#2A2A2A)

# 공구앱 회원가입 기능 구현

이 프로젝트는 Flutter 기반의 공동구매 앱에서 사용자 회원가입 기능을 구현한 것입니다. Firebase Authentication, Firestore를 사용하고 GPS 위치 기반 주소 조회 기능을 카카오맵 API를 통해 제공합니다.

## 주요 기능

- 이메일 인증 (Firebase Authentication)
- 전화번호 SMS 인증 (Firebase Authentication)
- GPS 기반 현재 위치 조회 및 주소 변환 (Kakao Maps API)
- 단계별 회원가입 UI (다단계 폼)
- Riverpod 2.x를 활용한 상태 관리

## 설치 방법

1. 프로젝트 클론
```bash
git clone https://github.com/your-repo/gonggoo-app.git
cd gonggoo-app
```

2. 의존성 설치
```bash
flutter pub get
```

3. 환경 설정
`.env` 파일을 프로젝트 루트 디렉토리에 생성하고 다음 내용을 추가합니다:
```
KAKAO_MAP_API_KEY=your_kakao_map_api_key
FIREBASE_WEB_API_KEY=your_firebase_web_api_key
ENV=development
```

## 필요한 패키지

아래는 회원가입 기능에 필요한 주요 패키지들입니다:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^5.5.4
  cloud_firestore: ^5.6.8
  firebase_storage: ^12.4.6
  
  # 상태 관리
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.3.3
  
  # 위치 서비스
  geolocator: ^10.1.1
  
  # 네트워크 및 데이터
  http: ^1.2.0
  equatable: ^2.0.5
  
  # 환경 설정
  flutter_dotenv: ^5.1.0
  
  # 보안 저장
  flutter_secure_storage: ^9.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.3.9
  build_runner: ^2.4.7
```

## 권한 설정

### Android

`android/app/src/main/AndroidManifest.xml` 파일에 다음 권한을 추가합니다:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 인터넷 접근 권한 -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- 위치 권한 -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <!-- 전화번호 확인 권한 -->
    <uses-permission android:name="android.permission.READ_PHONE_STATE" />
    <uses-permission android:name="android.permission.READ_PHONE_NUMBERS" />
    
    <application>
        <!-- ... 기존 코드 ... -->
    </application>
</manifest>
```

### iOS

`ios/Runner/Info.plist` 파일에 다음 권한 설명을 추가합니다:

```xml
<dict>
    <!-- ... 기존 코드 ... -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>현재 위치를 기반으로 주소를 조회하기 위해 위치 권한이 필요합니다.</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>현재 위치를 기반으로 주소를 조회하기 위해 위치 권한이 필요합니다.</string>
</dict>
```

## 카카오맵 API 설정

1. [Kakao Developers](https://developers.kakao.com) 사이트에서 앱을 등록합니다.
2. REST API 키를 발급받습니다.
3. `.env` 파일에 `KAKAO_MAP_API_KEY`로 설정합니다.

## 코드 생성

Riverpod 코드 생성을 위해 다음 명령어를 실행합니다:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 사용 방법

회원가입 화면으로 이동하는 코드:

```dart
Navigator.of(context).pushNamed(EnhancedRegisterScreen.routeName);
```

## 주요 파일 구조

- `lib/features/auth/providers/signup_provider.dart`: 회원가입 상태 관리
- `lib/features/auth/services/kakao_map_service.dart`: 카카오맵 API 연동
- `lib/features/auth/screens/enhanced_register_screen.dart`: 회원가입 UI
- `lib/features/auth/widgets/verification_code_input.dart`: SMS 인증 코드 입력 위젯
- `lib/core/config/env_config.dart`: 환경 설정 관리

## 트러블슈팅

### 위치 권한 문제
- Android 12 이상에서는 위치 권한을 명시적으로 요청해야 합니다.
- 위치 서비스가 비활성화된 경우, 사용자에게 설정 화면으로 이동하도록 안내합니다.

### Firebase 인증 문제
- 이메일 인증 링크가 스팸함에 있는지 확인하도록 안내합니다.
- SMS 인증 코드가 도착하지 않는 경우 재전송 버튼을 사용하도록 안내합니다.

### 카카오맵 API 키 관련
- API 키는 `.env` 파일이나 환경 변수를 통해 안전하게 관리합니다.
- 개발 환경에서는 "YOUR_KAKAO_MAP_API_KEY" 기본값이 사용되지만, 실제 환경에서는 반드시 올바른 키를 설정해야 합니다. 