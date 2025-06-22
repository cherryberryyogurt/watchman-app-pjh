# Flutter Analyze 에러 해결 가이드

## 🚨 Critical Errors (즉시 해결 필요)

### 1. Import 경로 수정
```bash
# signup_provider.dart 수정
import '../utils/secure_storage.dart'; 
→ import '../../../core/utils/secure_storage.dart';

import 'auth_state.dart'; 
→ import '../states/auth_state.dart';

import '../../common/providers/repository_providers.dart'; 
→ import '../../../core/providers/repository_providers.dart';
```

### 2. 누락된 파일들 처리
```bash
# 다음 중 하나 선택:
# A) 파일 생성 
lib/features/order/providers/order_history_state.dart

# B) import 경로 수정
'../providers/order_history_state.dart' 
→ '../states/order_state.dart'
```

### 3. Undefined 메서드/클래스 해결
```dart
// KakaoMapService에 누락된 메서드 추가
class KakaoMapService {
  Future<Map<String, dynamic>> searchAddressDetails(String query) async {
    // 구현 필요
  }
}

// CartItemModel에 누락된 메서드 추가  
class CartItemModel {
  List<dynamic> getAvailablePickupInfos() {
    // 구현 필요
    return [];
  }
}
```

## ⚠️ Deprecated & Warnings

### 1. Riverpod Provider Reference 수정
```bash
# repository_providers.dart에서 모든 *Ref → Ref로 변경
find . -name "*.dart" -exec sed -i '' 's/LocationTagRepositoryRef/Ref/g' {} \;
find . -name "*.dart" -exec sed -i '' 's/AuthRepositoryRef/Ref/g' {} \;
find . -name "*.dart" -exec sed -i '' 's/ProductRepositoryRef/Ref/g' {} \;
find . -name "*.dart" -exec sed -i '' 's/FirebaseFirestoreRef/Ref/g' {} \;
find . -name "*.dart" -exec sed -i '' 's/FirebaseAuthRef/Ref/g' {} \;
```

### 2. 불필요한 Import 제거
```bash
# 각 파일에서 unused import 제거
# core/theme/app_theme.dart
- import 'package:flutter/services.dart';

# core/widgets/web_toss_payments_widget_web.dart  
- import 'dart:convert';
- import '../config/payment_config.dart';
```

## ℹ️ Code Quality 개선

### 1. print → debugPrint 변경
```bash
# 모든 print() 문을 debugPrint()로 변경
find . -name "*.dart" -exec sed -i '' 's/print(/debugPrint(/g' {} \;
```

### 2. Empty catch blocks 수정
```dart
// secure_storage.dart:315 수정
catch (fallbackError) {
  // 빈 블록
}
→
catch (fallbackError) {
  if (kDebugMode) {
    debugPrint('Fallback storage error: $fallbackError');
  }
}
```

### 3. 중괄호 추가
```dart
// if 문에 중괄호 추가
// auth_repository.dart 143, 145, 148, 151 라인
if (condition) statement;
→
if (condition) {
  statement;
}
```

## 🔧 자동화 스크립트

### 한번에 주요 이슈 해결
```bash
#!/bin/bash

# 1. Riverpod deprecated 수정
find lib -name "*.dart" -exec sed -i '' 's/\([A-Za-z]*\)Ref ref)/Ref ref)/g' {} \;

# 2. print → debugPrint 변경  
find lib -name "*.dart" -exec sed -i '' 's/print(/debugPrint(/g' {} \;

# 3. flutter_riverpod import 추가 (필요한 경우)
echo "import 'package:flutter_riverpod/flutter_riverpod.dart';" >> lib/core/providers/repository_providers.dart

# 4. 분석 재실행
flutter analyze
```

## 📊 우선순위 해결 순서

1. **Critical Errors** (에러 레벨) → 앱 빌드 불가
2. **Missing Required Arguments** → 런타임 에러 가능성
3. **Deprecated Warnings** → 향후 호환성 문제
4. **Code Style Issues** → 코드 품질 개선

## 🎯 예상 결과

현재 186개 이슈 → 예상 잔여 이슈: **약 20-30개** (주로 info 레벨)

주요 에러들이 해결되면 앱이 정상적으로 빌드되고 실행될 것입니다. 