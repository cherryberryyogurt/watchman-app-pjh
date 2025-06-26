# 과세/면세 상품 구분 결제 구현 진행 상황

## 작업 일자: 2024-12-20

## 📊 전체 진행 상황

### ✅ Phase 1: 세금 계산 로직 구현 (완료)

#### 1.1 세금 계산 유틸리티 클래스 생성
- **파일**: `lib/core/utils/tax_calculator.dart`
- **주요 기능**:
  - VAT 포함 가격에서 공급가액과 VAT 분리
  - 주문 아이템들의 세금 계산
  - TaxBreakdown, OrderTaxBreakdown 클래스 정의
  - toTossPaymentsMap() 메서드로 API 연동 준비

#### 1.2 주문 모델 확장
- **파일**: `lib/features/order/models/order_model.dart`
- **변경 사항**:
  - suppliedAmount, vat, taxFreeAmount 필드 추가
  - OrderModel.withTaxCalculation 팩토리 메서드 추가
  - 세금 계산 로직 통합

#### 1.3 CartItemModel 수정
- **파일**: `lib/features/cart/models/cart_item_model.dart`
- **변경 사항**:
  - isTaxFree 필드 추가 (면세 여부)
  - 모든 관련 메서드 업데이트 (fromJson, toJson, copyWith 등)

### ✅ Phase 2: 모바일 결제 로직 개선 (완료)

#### 2.1 TossPaymentsWebView 수정
- **파일**: `lib/features/order/widgets/toss_payments_webview.dart`
- **변경 사항**:
  - OrderTaxBreakdown? taxBreakdown 파라미터 추가
  - JavaScript 결제 요청에 세금 정보 추가 (suppliedAmount, vat, taxFreeAmount)
  - 세금 정보 로깅 추가

#### 2.2 PaymentScreen 수정
- **파일**: `lib/features/order/screens/payment_screen.dart`
- **변경 사항**:
  - tax_calculator.dart import 추가
  - OrderModel에서 세금 정보를 가져와 OrderTaxBreakdown 생성
  - TossPaymentsWebView에 taxBreakdown 전달

### ✅ Phase 3: 웹 결제 페이지 업데이트 (완료)

#### 3.1 PaymentService 수정
- **파일**: `lib/features/order/services/payments_service.dart`
- **변경 사항**:
  - getPaymentWidgetConfig 메서드에 세금 정보 파라미터 추가 (suppliedAmount, vat, taxFreeAmount)
  - 웹 환경에서 세금 정보를 URL 파라미터로 전달

#### 3.2 PaymentScreen 웹 환경 처리
- **파일**: `lib/features/order/screens/payment_screen.dart`
- **변경 사항**:
  - _redirectToIndependentPaymentPage에서 세금 정보 전달

#### 3.3 독립 결제 페이지 수정
- **파일**: `web/payment.html`
- **변경 사항**:
  - URL 파라미터로 세금 정보 수신 (suppliedAmount, vat, taxFreeAmount)
  - 토스페이먼츠 requestPayment에 세금 정보 추가
  - 세금 정보 로깅 추가

## 🔄 진행 중인 작업

없음 - Phase 1, 2, 3 모두 완료

## 📝 이슈 및 해결 내역

### 이슈 1: CartItemModel 구조 불일치
- **문제**: 원래 계획에서 CartItemModel.product.isTaxFree를 사용하려 했으나 실제로는 product 객체가 없음
- **해결**: CartItemModel에 직접 isTaxFree 필드 추가

### 이슈 2: 린터 에러
- **문제**: round() 메서드가 num 타입을 반환하는데 int로 할당하려고 함
- **해결**: .toInt() 메서드 추가하여 타입 변환

### 이슈 3: OrderTaxBreakdown import 누락
- **문제**: PaymentScreen에서 OrderTaxBreakdown 클래스를 찾을 수 없음
- **해결**: tax_calculator.dart import 추가

## 🎯 다음 단계

### Phase 3: 웹 결제 페이지 업데이트
1. web/payment.html에 세금 정보 파라미터 추가
2. JavaScript에서 세금 정보를 requestPayment에 전달

### Phase 4: 서버 사이드 검증
1. Cloud Functions에서 세금 정보 검증 로직 추가
2. 결제 승인 시 세금 정보 검증

### Phase 5: 테스트 및 검증
1. 과세/면세 상품 혼합 주문 테스트
2. 세금 계산 정확도 검증
3. 토스페이먼츠 API 응답 확인

## 💡 참고 사항

- VAT 계산 방식: VAT 포함 가격에서 공급가액과 VAT 분리 (10,000원 = 공급가액 9,091원 + VAT 909원)
- 배송비는 항상 과세 대상으로 처리
- 기존 데이터는 모두 과세로 처리 (isTaxFree = false가 기본값) 