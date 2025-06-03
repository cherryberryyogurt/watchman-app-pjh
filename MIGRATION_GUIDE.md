# LocationTag 시스템 점진적 마이그레이션 가이드

## 📋 개요

이 문서는 기존 LocationTag 시스템에서 새로운 구조로의 점진적 마이그레이션 가이드입니다.

## 🔄 마이그레이션 단계

### 1단계: 핵심 오류 해결 ✅ (완료)

**완료된 작업:**
- ✅ UI 파일들의 ProductModel 호환성 수정
- ✅ AuthRepository signUp 메서드 매개변수 수정
- ✅ SignUpProvider의 locationTag 오류 수정
- ✅ UserLocationService Provider 의존성 수정
- ✅ ProductRepository에 누락된 메서드 추가

**결과:** 모든 컴파일 오류(`error`) 해결 완료

### 2단계: 점진적 개선 (권장)

#### 2.1 SignUpProvider 리팩토링

**현재 상태:**
- SignUpProvider는 임시로 KakaoMapService의 기존 구조를 새로운 구조로 변환 중
- `_convertLocationTagToId()` 헬퍼 메서드로 호환성 유지

**개선 계획:**
```dart
// 현재 (임시 해결책)
final convertedLocationTagId = _convertLocationTagToId(searchedLocationTag);

// 목표 (UserLocationService 사용)
final locationResult = await ref.read(userLocationServiceProvider)
    .validateAndMapLocation(inputAddress);
```

**실행 방법:**
1. 새로운 회원가입 플로우에서 UserLocationService 사용
2. 기존 코드는 단계적으로 교체
3. 테스트를 통해 안정성 확인

#### 2.2 KakaoMapService 통합

**현재 상태:**
- KakaoMapService는 기존 `locationTag` 필드만 반환
- UserLocationService와 별도로 운영

**개선 계획:**
```dart
// UserLocationService에서 KakaoMapService 사용하도록 통합
final addressInfo = await _kakaoMapService.searchAddressDetails(inputAddress);
final locationResult = await _mapAndValidateLocationTag(dongName);
```

### 3단계: 데이터 마이그레이션

#### 3.1 기존 데이터 마이그레이션

**마이그레이션 실행:**
```bash
# 마이그레이션 스크립트 실행
flutter run lib/debug_migration.dart
```

**마이그레이션 내용:**
- LocationTag 컬렉션 초기화
- 기존 Product 데이터 업데이트
- 기존 User 데이터 업데이트

#### 3.2 백업 및 복구

**백업 권장사항:**
```bash
# Firestore 백업 (Firebase CLI 필요)
gcloud firestore export gs://your-bucket-name/backup-$(date +%Y%m%d)
```

## 🧪 테스트 전략

### 필수 테스트 항목

1. **회원가입 플로우**
   - 새로운 사용자 회원가입
   - 주소 인증 과정
   - LocationTag 매핑

2. **상품 조회**
   - 위치 기반 상품 필터링
   - 카테고리별 조회
   - 검색 기능

3. **기존 사용자 호환성**
   - 기존 사용자 로그인
   - 프로필 업데이트
   - 주소 변경

### 테스트 코드 예시

```dart
// 회원가입 테스트
test('새로운 회원가입 플로우 테스트', () async {
  final service = UserLocationService(...);
  final result = await service.registerUserWithLocation(
    name: '테스트 사용자',
    inputAddress: '서울특별시 강남구 강남대로 396',
  );
  
  expect(result.locationStatus, 'active');
  expect(result.locationTagName, '강남동');
});
```

## 🚨 주의사항

### 현재 알려진 제한사항

1. **SignUpProvider 임시 해결책**
   - `_convertLocationTagToId()` 메서드는 임시적
   - 새로운 기능에서는 UserLocationService 사용 권장

2. **KakaoMapService 호환성**
   - 현재 기존 구조(`locationTag`)만 반환
   - UserLocationService와 중복 로직 존재

3. **마이그레이션 후 확인사항**
   - 모든 기존 데이터가 올바르게 변환되었는지 확인
   - LocationTag가 정상적으로 생성되었는지 확인

## 📈 성능 고려사항

### 최적화 권장사항

1. **캐싱 전략**
```dart
// LocationTag 캐싱
final cachedLocationTags = await _locationTagRepository.getCachedLocationTags();
```

2. **쿼리 최적화**
```dart
// 복합 인덱스 사용
.where('locationTagId', isEqualTo: locationTagId)
.where('isOnSale', isEqualTo: true)
.orderBy('createdAt', descending: true)
```

## 🔮 향후 계획

### 단기 계획 (1-2주)
- [ ] SignUpProvider UserLocationService 통합
- [ ] KakaoMapService 리팩토링
- [ ] 통합 테스트 작성

### 중기 계획 (1-2개월)
- [ ] 성능 최적화
- [ ] 오프라인 지원
- [ ] 고급 위치 기능 추가

### 장기 계획 (3개월+)
- [ ] 다중 지역 지원
- [ ] 동적 LocationTag 생성
- [ ] AI 기반 위치 추천

## 📞 문제 해결

### 자주 발생하는 문제

1. **마이그레이션 실패**
```bash
# 로그 확인
flutter logs

# 데이터베이스 상태 확인
# Firestore 콘솔에서 locationTags 컬렉션 확인
```

2. **호환성 문제**
```dart
// 기존 데이터와 새 구조 간 변환
final locationTagId = oldData['locationTag'] != null 
    ? convertLocationTagToId(oldData['locationTag'])
    : null;
```

3. **성능 문제**
```dart
// 인덱스 확인 및 쿼리 최적화
.limit(20) // 페이지네이션 사용
```

## 🔗 관련 문서

- [README_AUTH_REFACTORING.md](./README_AUTH_REFACTORING.md) - 기본 구조 설명
- [UserLocationService API 문서](./lib/features/auth/services/user_location_service.dart)
- [LocationTagRepository API 문서](./lib/features/products/repositories/location_tag_repository.dart) 