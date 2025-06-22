# 공구앱 (Gonggoo App)

> **Flutter 기반 공동구매 마켓플레이스 애플리케이션**

공구(공동구매) 상품을 쉽게 찾고, 주문하고, 결제할 수 있는 모바일 애플리케이션입니다. 위치 기반 서비스를 통해 사용자 근처의 공구 상품을 찾을 수 있으며, 배송 또는 픽업을 선택할 수 있습니다.

## 📱 주요 기능

### 🔐 사용자 인증 시스템
- **전화번호 인증**: Firebase Auth 기반 SMS 인증
- **프로필 관리**: 사용자 정보 수정 및 관리
- **위치 정보**: 사용자 주변 공구 상품 조회를 위한 위치 설정
- **보안 저장소**: Flutter Secure Storage를 활용한 안전한 토큰 관리

### 🛍️ 상품 관리
- **상품 목록**: 위치 기반 공구 상품 검색 및 필터링
- **상품 상세**: 이미지 슬라이더, 상품 정보, 옵션 선택
- **카테고리별 분류**: 효율적인 상품 탐색
- **실시간 업데이트**: Firestore 실시간 동기화

### 🛒 장바구니 시스템
- **배송/픽업 구분**: 탭 인터페이스로 배송 타입별 관리
- **수량 조절**: 실시간 수량 변경 및 가격 계산
- **선택적 주문**: 개별 상품 선택을 통한 부분 주문
- **상태 관리**: Riverpod을 활용한 효율적인 상태 관리

### 💳 주문 및 결제 시스템
- **3단계 결제 프로세스**:
  1. **결제 정보 확인**: 주문 내역, 배송지, 금액 확인
  2. **결제 수단 선택**: 카드 결제, 계좌이체 지원
  3. **결제 진행**: Toss Payments 웹뷰 연동

- **배송 정보 관리**: 
  - 카카오 주소 API 연동을 통한 주소 검증
  - 상세 주소 입력 및 배송 메모 기능

- **픽업 시스템**: 
  - 픽업 장소 정보 제공 (영업시간, 연락처, 특별 안내사항)
  - 위치 기반 픽업 포인트 관리

- **주문 완료**: 
  - 애니메이션이 포함된 성공 화면
  - 상세한 주문 정보 표시
  - 다음 단계 안내 (배송 추적, 픽업 안내)

### 📍 위치 기반 서비스
- **위치 태그**: LocationTag 시스템을 통한 지역별 상품 관리
- **픽업 정보**: 각 위치별 픽업 포인트 상세 정보
- **거리 계산**: 사용자 위치 기반 상품 정렬

## 🏗️ 기술 스택

### **Frontend**
- **Flutter** 3.0+ - 크로스 플랫폼 모바일 개발
- **Dart** 3.0+ - 프로그래밍 언어

### **상태 관리**
- **Riverpod** 2.4.9 - 반응형 상태 관리
- **Riverpod Generator** - 코드 생성을 통한 Provider 자동화

### **Backend & Database**
- **Firebase**
  - **Firestore** - NoSQL 데이터베이스
  - **Authentication** - 사용자 인증
  - **Storage** - 파일 저장소
  - **App Check** - 앱 보안

### **결제 시스템**
- **Toss Payments** - 결제 서비스 연동
- **WebView Flutter** - 웹뷰 기반 결제 UI

### **외부 API**
- **Kakao Map API** - 주소 검색 및 검증
- **Geocoding/Geolocator** - 위치 서비스

### **UI/UX**
- **Google Fonts** - Pretendard 폰트
- **Cached Network Image** - 이미지 캐싱
- **Shimmer** - 로딩 스켈레톤
- **Flutter SpinKit** - 로딩 애니메이션

## 🏛️ 프로젝트 구조

```
lib/
├── core/                    # 핵심 공통 기능
│   ├── config/             # 앱 설정 및 환경 변수
│   ├── constants/          # 상수 정의
│   ├── network/            # 네트워크 관련 유틸리티
│   ├── theme/              # 디자인 시스템 (색상, 텍스트, 테마)
│   └── utils/              # 공통 유틸리티 함수
├── features/               # 기능별 모듈
│   ├── auth/              # 사용자 인증
│   │   ├── exceptions/    # 인증 관련 예외
│   │   ├── models/        # 사용자 데이터 모델
│   │   ├── providers/     # 상태 관리 Provider
│   │   ├── repositories/  # 데이터 레이어
│   │   ├── screens/       # UI 화면
│   │   ├── services/      # 비즈니스 로직
│   │   ├── utils/         # 인증 유틸리티
│   │   └── widgets/       # 재사용 가능한 위젯
│   ├── cart/              # 장바구니
│   ├── home/              # 홈 화면
│   ├── location/          # 위치 서비스
│   ├── order/             # 주문 및 결제
│   ├── products/          # 상품 관리
│   └── common/            # 공통 Provider
├── constants/             # 전역 상수
└── main.dart             # 앱 진입점
```

## 🔧 설정 및 실행

### **사전 요구사항**
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code
- Firebase 프로젝트 설정

### **1. 프로젝트 클론**
```bash
git clone <repository-url>
cd gonggoo-app-pjh
```

### **2. 의존성 설치**
```bash
flutter pub get
```

### **3. Firebase 설정**
```bash
# Firebase CLI 설치 (필요한 경우)
npm install -g firebase-tools

# Firebase 프로젝트와 연결
firebase login
flutterfire configure
```

### **4. 환경 변수 설정**
`.env` 파일을 생성하고 다음 정보를 입력하세요:
```env
# Kakao API
KAKAO_REST_API_KEY=your_kakao_rest_api_key

# Toss Payments (시크릿 키는 server에서만 관리)
TOSS_CLIENT_KEY=your_toss_payments_client_key
```

### **5. 앱 실행**
```bash
flutter run
```

## 📊 데이터 모델

### **주요 엔티티**

#### **User (사용자)**
```dart
class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String? email;
  final UserLocation? userLocation;
  final DateTime createdAt;
}
```

#### **Product (상품)**
```dart
class ProductModel {
  final String productId;
  final String name;
  final int price;
  final String description;
  final List<String> imageUrls;
  final String locationTagId;
  final ProductStatus status;
  final DateTime startDate;
  final DateTime endDate;
}
```

#### **Order (주문)**
```dart
class OrderModel {
  final String orderId;
  final String userId;
  final List<OrderedProduct> orderedProducts;
  final OrderStatus status;
  final DeliveryAddress? deliveryAddress;
  final PaymentInfo? paymentInfo;
  final DateTime createdAt;
}
```

#### **Cart (장바구니)**
```dart
class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double productPrice;
  final String productDeliveryType;
  final bool isSelected;
}
```

## 🎨 디자인 시스템

### **컬러 팔레트**
- **Primary**: #007AFF (iOS Blue)
- **Secondary**: #34C759 (Green)
- **Error**: #FF3B30 (Red)
- **Warning**: #FF9500 (Orange)
- **Success**: #30D158 (Green)

### **타이포그래피**
- **Font Family**: Pretendard
- **Text Styles**: Display, Headline, Title, Body, Label 스타일 제공
- **반응형 크기**: 다양한 화면 크기 지원

### **컴포넌트**
- **AuthButton**: 인증 관련 버튼
- **ProductCard**: 상품 카드
- **OrderSummaryCard**: 주문 요약 카드
- **TossPaymentsWebView**: 결제 웹뷰

## 🔐 보안

### **데이터 보안**
- **Firebase Security Rules**: Firestore 데이터 접근 제어
- **App Check**: 앱 무결성 검증
- **Secure Storage**: 민감한 데이터 암호화 저장

### **결제 보안**
- **Toss Payments**: PCI DSS 준수 결제 서비스
- **테스트 환경**: 개발용 테스트 키 사용
- **HTTPS**: 모든 API 통신 암호화

## 📱 지원 플랫폼

- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 11.0+
- **Web**: Chrome, Safari, Firefox (부분 지원)

## 🧪 테스트

### **단위 테스트**
```bash
flutter test
```

### **통합 테스트**
```bash
flutter test integration_test/
```

### **테스트 커버리지**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📚 주요 패키지

### **상태 관리**
- `riverpod: ^2.4.9` - 상태 관리
- `flutter_riverpod: ^2.4.9` - Flutter용 Riverpod

### **UI/UX**
- `google_fonts: ^6.2.1` - 폰트
- `cached_network_image: ^3.4.1` - 이미지 캐싱
- `shimmer: ^3.0.0` - 로딩 효과
- `flutter_spinkit: ^5.2.0` - 로딩 애니메이션

### **네트워킹**
- `dio: ^5.3.4` - HTTP 클라이언트
- `connectivity_plus: ^6.1.4` - 네트워크 상태 확인

### **저장소**
- `flutter_secure_storage: ^9.0.0` - 보안 저장소
- `shared_preferences: ^2.2.2` - 환경설정 저장

### **위치 서비스**
- `geolocator: ^14.0.0` - GPS 위치
- `geocoding: ^2.1.1` - 주소 변환

### **결제**
- `webview_flutter: ^4.4.2` - 웹뷰 (Toss Payments)

## 🚀 개발 진행 상황

### ✅ **완료된 기능**

#### **Phase 1: 기본 인프라 구축**
- [x] 프로젝트 초기 설정 및 Firebase 연동
- [x] 디자인 시스템 구축 (색상, 타이포그래피, 테마)
- [x] 사용자 인증 시스템 (전화번호 인증)
- [x] 기본 네비게이션 및 라우팅

#### **Phase 2: 핵심 기능 구현**
- [x] 상품 관리 시스템 (목록, 상세, 검색)
- [x] 장바구니 기능 (추가, 수정, 삭제, 배송/픽업 구분)
- [x] 위치 기반 서비스 (LocationTag, PickupInfo)
- [x] 사용자 프로필 관리

#### **Phase 3: 주문 및 결제 시스템**
- [x] 주문서 작성 (CheckoutScreen)
  - [x] 배송지 정보 입력 및 카카오 주소 API 연동
  - [x] 픽업 정보 표시 및 안내
  - [x] 주문 메모 기능
- [x] 결제 시스템 (PaymentScreen)
  - [x] 3단계 결제 프로세스
  - [x] Toss Payments 웹뷰 연동
  - [x] 카드 결제 및 계좌이체 지원
- [x] 주문 완료 (OrderSuccessScreen)
  - [x] 성공 애니메이션 및 상세 정보 표시
  - [x] 다음 단계 안내
  - [x] 홈/주문내역 이동 옵션

### 🚧 **진행 중/예정 기능**

#### **Phase 4: 사용자 경험 개선**
- [ ] 주문 내역 화면 구현
- [ ] 주문 상태 추적 시스템
- [ ] 푸시 알림 연동
- [ ] 오프라인 지원

#### **Phase 5: 고급 기능**
- [ ] 리뷰 및 평점 시스템
- [ ] 위시리스트 기능
- [ ] 쿠폰 및 할인 시스템
- [ ] 관리자 대시보드

### 🎯 **성능 최적화**
- [x] 이미지 캐싱 및 압축
- [x] 상태 관리 최적화 (Riverpod)
- [x] 데이터베이스 쿼리 최적화
- [ ] 앱 번들 크기 최적화
- [ ] 로딩 성능 개선

## 🤝 기여 가이드

### **개발 환경 설정**
1. 프로젝트 포크 및 클론
2. 브랜치 생성 (`git checkout -b feature/기능명`)
3. 커밋 (`git commit -m 'feat: 새로운 기능 추가'`)
4. 푸시 (`git push origin feature/기능명`)
5. Pull Request 생성

### **코딩 컨벤션**
- **Dart**: [Effective Dart](https://dart.dev/guides/language/effective-dart) 준수
- **Flutter**: [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo) 준수
- **Commit**: [Conventional Commits](https://www.conventionalcommits.org/) 형식 사용

### **코드 품질**
```bash
# 린트 검사
flutter analyze

# 포맷팅
dart format .

# 테스트 실행
flutter test
```

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 📞 연락처

프로젝트에 대한 질문이나 제안사항이 있으시면 언제든지 연락해주세요.

---

**Made with ❤️ using Flutter** 