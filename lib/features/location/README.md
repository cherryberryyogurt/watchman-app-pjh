# 🏷️ LocationTag 통합 관리 시스템

## 📋 개요

LocationTag 시스템은 지역 기반 서비스를 위한 **통합 위치 관리 솔루션**입니다. 
기존에 여러 곳에 분산되어 있던 LocationTag 관련 코드를 하나로 통합하여 일관성 있고 효율적인 지역 관리를 제공합니다.

## 🔄 중복 제거 완료

### ✅ 제거된 중복 파일들
- `lib/features/products/models/location_tag_model.dart` ❌ 삭제됨
- `lib/features/products/repositories/location_tag_repository.dart` ❌ 삭제됨
- `lib/features/products/repositories/location_tag_repository.g.dart` ❌ 삭제됨
- `lib/features/products/services/location_tag_migration_service.dart` ❌ 삭제됨

### ✅ 통합된 시스템
- `lib/features/location/models/location_tag_model.dart` ✅ **통합 모델**
- `lib/features/location/repositories/location_tag_repository.dart` ✅ **통합 Repository**
- `lib/features/location/exceptions/location_tag_exceptions.dart` ✅ **통합 예외 처리**

## 🏗️ 아키텍처

```
lib/features/location/
├── models/
│   └── location_tag_model.dart          # 통합 LocationTag 모델
├── repositories/
│   └── location_tag_repository.dart     # 통합 LocationTag Repository
├── exceptions/
│   └── location_tag_exceptions.dart     # 통합 예외 처리
├── examples/
│   └── location_tag_usage_example.dart  # 사용 예제
└── README.md                            # 이 문서
```

## 🔧 주요 기능

### 1. 기본 조회 기능
```dart
// 이름으로 조회
final locationTag = await locationTagRepository.getLocationTagByName('강남동');

// ID로 조회
final locationTag = await locationTagRepository.getLocationTagById('gangnam_dong');

// 지원 지역 목록 조회
final regions = await locationTagRepository.getSupportedRegions();
```

### 2. 위치 기반 검색
```dart
// 주소에서 LocationTag 추출
final locationTag = await locationTagRepository.findLocationTagByAddress('서울 강남구 강남동');

// 좌표에서 가장 가까운 LocationTag 찾기
final geoPoint = GeoPoint(37.4988, 127.0281);
final locationTag = await locationTagRepository.findLocationTagByCoordinates(geoPoint);
```

### 3. 검증 및 변환
```dart
// 유효성 검증
final isValid = await locationTagRepository.isValidLocationTagName('강남동');
final isSupported = await locationTagRepository.isSupportedRegion('강남동');

// ID ↔ Name 변환
final id = await locationTagRepository.convertLocationTagNameToId('강남동');
final name = await locationTagRepository.convertLocationTagIdToName('gangnam_dong');
```

## 🔗 의존성 주입

### Riverpod Provider 설정
```dart
// lib/features/common/providers/repository_providers.dart
@riverpod
LocationTagRepository locationTagRepository(Ref ref) {
  return LocationTagRepository(
    firestore: ref.watch(firestoreProvider),
  );
}
```

### 다른 Repository에서 사용
```dart
// AuthRepository에서 LocationTag 검증
class AuthRepository {
  final LocationTagRepository _locationTagRepository;
  
  AuthRepository({
    required LocationTagRepository locationTagRepository,
  }) : _locationTagRepository = locationTagRepository;
  
  Future<UserModel> signUp({...}) async {
    // LocationTag 검증 로직
    final locationResult = await _validateAndProcessLocation(inputAddress);
    // ...
  }
}

// ProductRepository에서 LocationTag 기반 상품 조회
class ProductRepository {
  final LocationTagRepository _locationTagRepository;
  
  ProductRepository({
    required LocationTagRepository locationTagRepository,
  }) : _locationTagRepository = locationTagRepository;
  
  Future<List<ProductModel>> getProductsByLocation(GeoPoint location) async {
    final locationTag = await _locationTagRepository.findLocationTagByCoordinates(location);
    // ...
  }
}
```

## 🚀 성능 최적화

### 메모리 캐시 시스템
- **캐시 만료 시간**: 5분
- **캐시 타입**: ID 캐시, Name 캐시, 전체 목록 캐시
- **자동 캐시 무효화**: 데이터 변경 시 자동 갱신

```dart
// 캐시 수동 지우기
locationTagRepository.clearCache();
```

## 📊 데이터 구조

### LocationTag Collection (Firestore)
```json
{
  "id": "gangnam_dong",
  "name": "강남동",
  "description": "서울 강남구 강남동 지역",
  "region": {
    "sido": "서울특별시",
    "sigungu": "강남구", 
    "dong": "강남동"
  },
  "coordinate": {
    "center": "GeoPoint(37.4988, 127.0281)",
    "radius": 2.0
  },
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### User Collection (위치 상태 관리)
```json
{
  "uid": "user123",
  "locationTagId": "gangnam_dong",
  "locationTagName": "강남동", 
  "locationStatus": "active", // active, pending, unavailable, none
  "pendingLocationName": null,
  // ... 기타 사용자 정보
}
```

## 🔄 마이그레이션 가이드

### 기존 코드에서 통합 시스템으로 변경

#### Before (중복된 시스템)
```dart
// ❌ 기존 products 디렉토리의 LocationTag 사용
import '../../products/models/location_tag_model.dart';
import '../../products/repositories/location_tag_repository.dart';
```

#### After (통합 시스템)
```dart
// ✅ 통합 location 디렉토리의 LocationTag 사용
import '../../location/models/location_tag_model.dart';
import '../../location/repositories/location_tag_repository.dart';
import '../../common/providers/repository_providers.dart';
```

### 메소드명 변경
```dart
// ❌ 기존 메소드명
await locationTagRepository.getSupportedLocationTags();

// ✅ 통합 메소드명  
await locationTagRepository.getSupportedRegions();
```

## 🧪 개발 도구

### 더미 데이터 생성
```dart
// 개발용 LocationTag 더미 데이터 추가
await locationTagRepository.addDummyLocationTags();
```

### 지원 지역 목록
현재 지원하는 지역:
- 강남동 (gangnam_dong)
- 서초동 (seocho_dong)  
- 송파동 (songpa_dong)
- 영등포동 (yeongdeungpo_dong)
- 강서동 (gangseo_dong)

## 🎯 사용 시나리오

### 1. 회원가입 시 위치 검증
```dart
final userLocationService = ref.read(userLocationServiceProvider);

final user = await userLocationService.registerUserWithLocation(
  name: '홍길동',
  inputAddress: '서울 강남구 강남동 123-45',
);

// 결과: user.locationStatus = 'active' (지원 지역인 경우)
//      user.locationStatus = 'pending' (지원 예정 지역인 경우)  
//      user.locationStatus = 'unavailable' (지원하지 않는 지역인 경우)
```

### 2. 상품 조회 시 지역 필터링
```dart
final productRepository = ref.read(productRepositoryProvider);

// 특정 지역의 상품 조회
final products = await productRepository.getProductsByLocationTagName('강남동');

// 좌표 기반 상품 조회
final geoPoint = GeoPoint(37.4988, 127.0281);
final nearbyProducts = await productRepository.getProductsByLocation(geoPoint);
```

### 3. 지역 가용성 확인
```dart
final locationTagRepository = ref.read(locationTagRepositoryProvider);

// 서비스 지원 여부 확인
final isSupported = await locationTagRepository.isSupportedRegion('강남동');

// LocationTag 활성화 여부 확인  
final isAvailable = await locationTagRepository.isLocationTagAvailable('강남동');
```

## 🔧 문제 해결

### 자주 발생하는 문제

1. **Import 경로 오류**
   ```dart
   // ❌ 잘못된 경로
   import '../../products/models/location_tag_model.dart';
   
   // ✅ 올바른 경로
   import '../../location/models/location_tag_model.dart';
   ```

2. **Provider 의존성 오류**
   ```dart
   // ✅ 올바른 Provider import
   import '../../common/providers/repository_providers.dart';
   
   // 사용
   final locationTagRepo = ref.read(locationTagRepositoryProvider);
   ```

3. **메소드명 불일치**
   - `getSupportedLocationTags()` → `getSupportedRegions()`
   - `isSupportedRegion()` → 통합 시스템에서 지원됨

## 📈 향후 계획

1. **지역 확장**: 새로운 지역 추가 시 Firestore 데이터만 추가하면 자동 지원
2. **성능 개선**: Redis 캐시 도입 검토
3. **실시간 업데이트**: Firestore 실시간 리스너 추가
4. **지역별 설정**: 지역별 배송비, 픽업 정보 등 세부 설정 지원

## 🤝 기여 가이드

새로운 지역 추가 시:
1. Firestore `locationTag` 컬렉션에 데이터 추가
2. 더미 데이터 생성 함수에 지역 정보 추가 (개발용)
3. 테스트 케이스 작성

---

**📞 문의사항이 있으시면 개발팀에 연락해주세요!** 