# LocationTag 리팩토링 & 마이그레이션 가이드

## 🎯 개요

기존 Flutter Firebase 공동구매 앱의 locationTag 문자열 필드를 별도의 LocationTag 클래스로 분리하여 관리하는 시스템으로 리팩토링하는 프로젝트입니다.

## 📋 목표

### 기존 구조
```dart
class ProductModel {
  final String locationTag; // "강남동", "서초동" 등
}

class UserModel {
  final String? locationTag; // "강남동", "서초동" 등
}
```

### 새로운 구조
```dart
class ProductModel {
  final String locationTagId; // 참조 ID
  final String locationTagName; // 성능을 위한 중복
}

class UserModel {
  final String? locationTagId; // 참조 ID
  final String? locationTagName; // 성능을 위한 중복
  final String locationStatus; // "active" | "pending" | "unavailable" | "none"
  final String? pendingLocationName; // 대기 중인 지역명
}

class LocationTagModel {
  final String id;
  final String name; // "강남동"
  final List<PickupInfoModel> pickupInfos;
}
```

## 🏗️ 데이터 구조

### 1. LocationTag 컬렉션
```firestore
/locationTags/{locationTagId}
{
  id: "gangnam_dong",
  name: "강남동",
  description: "강남구 강남동 지역",
  region: {
    sido: "서울특별시",
    sigungu: "강남구", 
    dong: "강남동"
  },
  pickupInfos: [
    {
      id: "pickup_001",
      spotName: "강남역 3번 출구",
      address: "서울특별시 강남구 강남대로 396",
      pickupTimes: [Timestamp, ...],
      isActive: true
    }
  ],
  isActive: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### 2. Product 컬렉션 (수정)
```firestore
/products/{productId}
{
  // 기존 필드들 유지
  id: string,
  name: string,
  price: double,
  
  // 🔄 LocationTag 관련 (수정된 부분)
  locationTagId: string,       // 참조 ID
  locationTagName: string,     // "강남동" (성능을 위한 중복)
}
```

### 3. User 컬렉션 (수정)
```firestore
/users/{userId}
{
  // 기존 필드들 유지
  uid: string,
  name: string,
  
  // 🔄 LocationTag 관련 (수정된 부분)
  locationTagId: string,       // 참조 ID
  locationTagName: string,     // "강남동" (성능을 위한 중복)
  
  // 🆕 LocationTag 상태 관리
  locationStatus: string,      // "active" | "pending" | "unavailable" | "none"
  pendingLocationName: string, // LocationTag가 없는 지역인 경우 임시 저장
}
```

## 📦 구현된 주요 컴포넌트

### 1. 모델 클래스
- **LocationTagModel**: 지역 태그 정보
- **PickupInfoModel**: 픽업 장소/시간 정보
- **ProductModel**: 상품 정보 (LocationTag ID/Name 추가)
- **UserModel**: 사용자 정보 (LocationTag 상태 관리 추가)

### 2. Repository 클래스
- **LocationTagRepository**: LocationTag CRUD 및 지역 관리
- **ProductRepository**: 위치 기반 상품 조회 기능 확장
- **UserRepository**: 사용자 위치 관리 및 검증

### 3. 서비스 클래스
- **LocationTagMigrationService**: 기존 데이터 마이그레이션

### 4. Exception 클래스
- **LocationTag 관련**: LocationTagNotFoundException, UnsupportedLocationException 등
- **Product 관련**: ProductLocationMismatchException 등
- **User 관련**: UserLocationTagNotSetException 등

## 🚀 설치 및 설정

### 1. 코드 생성
```bash
# Riverpod Generator를 위한 빌드 실행
dart run build_runner build --delete-conflicting-outputs
```

### 2. 필요한 의존성 확인
```yaml
dependencies:
  cloud_firestore: ^4.x.x
  firebase_auth: ^4.x.x
  flutter_riverpod: ^2.x.x
  riverpod_annotation: ^2.x.x
  equatable: ^2.x.x

dev_dependencies:
  build_runner: ^2.x.x
  riverpod_generator: ^2.x.x
```

## 🔄 마이그레이션 프로세스

### 1. 마이그레이션 실행

```dart
import 'package:gonggoo_app/features/products/services/location_tag_migration_service.dart';

// Provider에서 서비스 가져오기
final migrationService = ref.read(locationTagMigrationServiceProvider);

// 전체 마이그레이션 실행
final result = await migrationService.executeFullMigration();

print('생성된 LocationTag: ${result['locationTagsCreated']}개');
print('업데이트된 Product: ${result['productsUpdated']}개');
print('업데이트된 User: ${result['usersUpdated']}개');
```

### 2. 마이그레이션 상태 확인

```dart
final status = await migrationService.checkMigrationStatus();

print('LocationTag 총 개수: ${status['locationTags']['total']}');
print('마이그레이션된 Product: ${status['products']['migrated']}');
print('마이그레이션 필요한 User: ${status['users']['needsMigration']}');
```

## 📍 지원 지역

현재 지원되는 지역은 다음과 같습니다:
- **강남동** (gangnam_dong)
- **서초동** (seocho_dong)
- **송파동** (songpa_dong)
- **영등포동** (yeongdeungpo_dong)
- **강서동** (gangseo_dong)

## 💻 사용법

### 1. LocationTag 기반 상품 조회

```dart
// LocationTag ID로 상품 조회
final products = await productRepository.getProductsByLocationTagId('gangnam_dong');

// LocationTag Name으로 상품 조회 (호환성)
final products = await productRepository.getProductsByLocationTagName('강남동');
```

### 2. 사용자 위치 설정

```dart
// 사용자 LocationTag 업데이트
await userRepository.updateUserLocationTag(uid, 'gangnam_dong', '강남동');

// 사용자 지역 접근 권한 검증
final hasAccess = await userRepository.validateUserLocationAccess(uid, 'gangnam_dong');
```

### 3. LocationTag 정보 조회

```dart
// 지원 지역 목록 조회
final supportedTags = await locationTagRepository.getSupportedLocationTags();

// 특정 LocationTag 조회
final locationTag = await locationTagRepository.getLocationTagById('gangnam_dong');

// 픽업 정보 조회
final pickupInfos = await locationTagRepository.getPickupInfosByLocationTagId('gangnam_dong');
```

## 🔍 상태 관리

### LocationStatus 값들
- **"active"**: LocationTag가 설정되고 활성 상태
- **"pending"**: 지원 지역이지만 LocationTag가 아직 생성되지 않음
- **"unavailable"**: 지원하지 않는 지역
- **"none"**: LocationTag가 설정되지 않음

### 상태 전환 흐름
```
회원가입/주소 입력
    ↓
주소 검증 (카카오맵 API + GPS)
    ↓
동 정보 추출
    ↓
지원 지역 확인
    ↓
├─ 지원 지역 + LocationTag 존재 → "active"
├─ 지원 지역 + LocationTag 없음 → "pending"
└─ 지원하지 않는 지역 → "unavailable"
```

## ⚠️ 주의사항

### 1. 데이터 일관성
- LocationTag ID와 Name은 항상 함께 업데이트해야 합니다
- Product와 User의 locationTag 필드는 마이그레이션 후에만 제거하세요

### 2. 성능 고려사항
- locationTagName은 중복 저장으로 성능을 위한 것입니다
- 자주 조회되는 경우 ID 대신 Name으로 쿼리할 수 있습니다

### 3. 마이그레이션 순서
1. LocationTag 컬렉션 생성
2. Product 컬렉션 마이그레이션
3. User 컬렉션 마이그레이션
4. 기존 locationTag 필드 제거 (충분한 검증 후)

## 🧪 테스트

### 1. 단위 테스트
```dart
// LocationTagRepository 테스트
test('should return supported location tags', () async {
  final tags = await locationTagRepository.getSupportedLocationTags();
  expect(tags.length, equals(5));
  expect(tags.first.name, equals('강남동'));
});
```

### 2. 통합 테스트
```dart
// 마이그레이션 테스트
test('should migrate existing data correctly', () async {
  final result = await migrationService.executeFullMigration();
  expect(result['errors'], isEmpty);
});
```

## 📚 API 문서

### LocationTagRepository

#### 주요 메서드
- `getSupportedLocationTags()`: 지원 지역 목록 조회
- `getLocationTagById(String id)`: ID로 LocationTag 조회
- `getLocationTagByName(String name)`: 이름으로 LocationTag 조회
- `isLocationTagAvailable(String dongName)`: 지역 가용성 확인
- `createLocationTagForRegion(String dongName)`: 신규 LocationTag 생성

### UserRepository

#### 주요 메서드
- `updateUserLocationTag(String uid, String locationTagId, String locationTagName)`: 사용자 LocationTag 업데이트
- `validateUserLocationAccess(String uid, String requestedLocationTagId)`: 지역 접근 권한 검증
- `handleLocationTagNotAvailable(String uid, String dongName)`: LocationTag 없는 경우 처리

### ProductRepository

#### 주요 메서드
- `getProductsByLocationTagId(String locationTagId)`: LocationTag ID로 상품 조회
- `getProductsByLocationTagName(String locationTagName)`: LocationTag Name으로 상품 조회
- `searchProductsInLocation(String query, String locationTagId)`: 지역 내 상품 검색

## 🚨 트러블슈팅

### 1. 빌드 오류
```bash
# .g.dart 파일 재생성
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### 2. 마이그레이션 실패
- Firestore 권한 확인
- 네트워크 연결 상태 확인
- 에러 로그 확인 (`result['errors']`)

### 3. LocationTag 없음
```dart
// 지원 지역 확인
final isSupported = await locationTagRepository.isSupportedRegion('새로운동');
if (!isSupported) {
  // 지원하지 않는 지역 처리
}
```

## 📞 지원

이슈나 질문이 있으시면 다음을 확인하세요:
1. 에러 로그 및 상태 메시지
2. Firestore 데이터 구조 확인
3. 마이그레이션 상태 확인

---

**📝 업데이트**: 2024년 버전
**👨‍💻 작성자**: Flutter LocationTag 리팩토링 팀 