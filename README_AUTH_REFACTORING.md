# AuthRepository 리팩토링 & UserLocationService 가이드

## 🎯 개요

기존 AuthRepository의 LocationTag 관련 로직을 리팩토링하여 **단일 책임 원칙**을 적용하고, 복잡한 위치 검증 비즈니스 로직을 별도의 서비스 레이어로 분리했습니다.

## 🏗️ 새로운 아키텍처

### 기존 구조 (문제점)
```
UI Layer ──▶ AuthRepository (인증 + 위치 검증 + 데이터 저장)
```
**문제점:**
- AuthRepository가 너무 많은 책임을 가짐
- 위치 검증 로직과 데이터 저장 로직이 섞임
- 테스트와 유지보수가 어려움

### 새로운 구조 (개선)
```
UI Layer ──▶ UserLocationService ──▶ AuthRepository
                    │                     │
                    └──▶ LocationTagRepository
```
**개선점:**
- **AuthRepository**: 인증과 기본 데이터 저장만 담당
- **UserLocationService**: 복잡한 위치 검증 비즈니스 로직 담당
- **LocationTagRepository**: LocationTag 관련 데이터 조회

## 📦 새로 추가된 컴포넌트

### 1. 모델 클래스
- **LocationResultModel**: 위치 검증 결과 캡슐화
- **UserLocationException**: 위치 관련 예외 처리

### 2. 서비스 클래스
- **UserLocationService**: 위치 관련 비즈니스 로직 처리

### 3. 수정된 기존 클래스
- **AuthRepository**: 메서드 시그니처 수정, LocationTag 필드 추가

## 🚀 사용법

### 1. 회원가입 (위치 포함)

#### Before (기존 방식)
```dart
// 기존: AuthRepository에서 직접 처리
final user = await authRepository.signUp(
  name: name,
  phoneNumber: phoneNumber,
  locationTag: locationTag, // 단순 문자열
);
```

#### After (개선된 방식)
```dart
// 개선: UserLocationService를 통해 처리
final userLocationService = ref.read(userLocationServiceProvider);

final user = await userLocationService.registerUserWithLocation(
  name: '홍길동',
  inputAddress: '서울특별시 강남구 강남대로 396',
  phoneNumber: '010-1234-5678',
);

// 결과 확인
print('사용자 상태: ${user.locationStatusMessage}');
print('LocationTag ID: ${user.locationTagId}');
print('LocationTag Name: ${user.locationTagName}');
```

### 2. 사용자 위치 정보 업데이트

```dart
final userLocationService = ref.read(userLocationServiceProvider);

final updatedUser = await userLocationService.updateUserLocation(
  uid: user.uid,
  inputAddress: '서울특별시 서초구 서초대로 294',
  name: '홍길동',
  phoneNumber: '010-1234-5678',
);

// 상태 확인
if (updatedUser.hasActiveLocationTag) {
  print('위치 설정 완료: ${updatedUser.locationTagName}');
} else if (updatedUser.isLocationPending) {
  print('서비스 준비중: ${updatedUser.pendingLocationName}');
} else if (updatedUser.isLocationUnavailable) {
  print('지원하지 않는 지역입니다');
}
```

### 3. 기존 사용자 프로필 저장

```dart
final userLocationService = ref.read(userLocationServiceProvider);

final user = await userLocationService.saveExistingUserWithLocation(
  uid: firebaseUser.uid,
  name: '홍길동',
  inputAddress: '서울특별시 송파구 송파대로 28길',
  phoneNumber: '010-1234-5678',
);
```

### 4. 위치 정보 없이 회원가입

```dart
final userLocationService = ref.read(userLocationServiceProvider);

// 나중에 위치 설정할 수 있도록 회원가입
final user = await userLocationService.registerUserWithoutLocation(
  name: '홍길동',
  phoneNumber: '010-1234-5678',
);

print('위치 상태: ${user.locationStatus}'); // 'none'
```

### 5. 사용자 위치 상태 조회

```dart
final userLocationService = ref.read(userLocationServiceProvider);

final locationStatus = await userLocationService.getUserLocationStatus(user.uid);

if (locationStatus.isActiveLocation) {
  print('활성 위치: ${locationStatus.locationTagName}');
} else if (locationStatus.isPending) {
  print('대기 중: ${locationStatus.pendingLocationName}');
} else if (locationStatus.isUnavailable) {
  print('오류: ${locationStatus.errorMessage}');
}
```

### 6. 지원 지역 목록 조회

```dart
final userLocationService = ref.read(userLocationServiceProvider);

final supportedRegions = await userLocationService.getSupportedRegions();

for (final region in supportedRegions) {
  print('지원 지역: ${region.name}');
  print('픽업 정보: ${region.activePickupInfos.length}개');
}
```

## 🔄 LocationStatus 관리

### 상태 종류
- **"active"**: LocationTag가 설정되고 활성 상태
- **"pending"**: 지원 지역이지만 LocationTag가 아직 생성되지 않음
- **"unavailable"**: 지원하지 않는 지역
- **"none"**: LocationTag가 설정되지 않음

### 상태 전환 흐름
```
사용자 주소 입력
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

## 🧪 UI에서 상태별 처리 예시

```dart
class LocationStatusWidget extends ConsumerWidget {
  final UserModel user;
  
  const LocationStatusWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (user.locationStatus) {
      case 'active':
        return Card(
          color: Colors.green[50],
          child: ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('위치 인증 완료'),
            subtitle: Text('${user.locationTagName} 지역'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
        );
        
      case 'pending':
        return Card(
          color: Colors.orange[50],
          child: ListTile(
            leading: Icon(Icons.schedule, color: Colors.orange),
            title: Text('서비스 준비중'),
            subtitle: Text('${user.pendingLocationName} 지역은 곧 서비스 예정입니다'),
          ),
        );
        
      case 'unavailable':
        return Card(
          color: Colors.red[50],
          child: ListTile(
            leading: Icon(Icons.error, color: Colors.red),
            title: Text('지원하지 않는 지역'),
            subtitle: Text('다른 지역으로 변경해주세요'),
            trailing: TextButton(
              onPressed: () => _showAddressChangeDialog(context),
              child: Text('주소 변경'),
            ),
          ),
        );
        
      case 'none':
      default:
        return Card(
          color: Colors.grey[50],
          child: ListTile(
            leading: Icon(Icons.location_off, color: Colors.grey),
            title: Text('위치 미설정'),
            subtitle: Text('주소를 설정해주세요'),
            trailing: TextButton(
              onPressed: () => _showAddressInputDialog(context),
              child: Text('주소 설정'),
            ),
          ),
        );
    }
  }
  
  void _showAddressInputDialog(BuildContext context) {
    // 주소 입력 다이얼로그 표시
    // UserLocationService.updateUserLocation() 호출
  }
  
  void _showAddressChangeDialog(BuildContext context) {
    // 주소 변경 다이얼로그 표시
    // UserLocationService.updateUserLocation() 호출
  }
}
```

## 🔧 예외 처리

### UserLocationService 예외 처리
```dart
try {
  final user = await userLocationService.registerUserWithLocation(
    name: name,
    inputAddress: inputAddress,
  );
  
  // 성공 처리
  
} on AddressValidationException catch (e) {
  // 주소 검증 실패
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('주소 검증 실패'),
      content: Text(e.toString()),
    ),
  );
  
} on LocationTagMappingException catch (e) {
  // LocationTag 매핑 실패
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('위치 설정 실패'),
      content: Text(e.toString()),
    ),
  );
  
} on UnsupportedRegionException catch (e) {
  // 지원하지 않는 지역
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('지원하지 않는 지역'),
      content: Text(e.toString()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('다른 주소 입력'),
        ),
      ],
    ),
  );
  
} on UserLocationException catch (e) {
  // 일반적인 위치 오류
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.toString())),
  );
  
} catch (e) {
  // 기타 오류
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('알 수 없는 오류가 발생했습니다: $e')),
  );
}
```

## 📊 마이그레이션 체크리스트

### UI 레이어 수정 사항
- [ ] AuthRepository 직접 호출을 UserLocationService 호출로 변경
- [ ] 위치 관련 로직에서 UserLocationService 사용
- [ ] 예외 처리 코드 업데이트 (UserLocationException 계열)
- [ ] UI에서 locationStatus 기반 상태 표시

### 기존 코드 호환성
- [ ] 기존 AuthRepository 메서드들은 그대로 사용 가능
- [ ] UserModel의 새로운 필드들 추가 확인
- [ ] 기존 locationTag 필드는 마이그레이션 후 제거 예정

## 🚨 주의사항

### 1. 주소 검증 로직 구현 필요
현재 `UserLocationService._validateAddress()` 메서드는 더미 데이터를 반환합니다.
실제 구현에서는 다음 로직을 추가해야 합니다:

```dart
// TODO: 실제 구현 필요
Future<Map<String, dynamic>> _validateAddress(String inputAddress) async {
  // 1. 카카오맵 API로 주소 정보 조회
  // 2. GPS로 현재 위치 확인  
  // 3. 입력된 주소와 현재 위치의 거리 계산
  // 4. 10km 이내인지 검증
}
```

### 2. 성능 고려사항
- LocationTag 정보는 중복 저장으로 성능 최적화
- 자주 조회되는 경우 캐싱 고려
- LocationTagRepository의 쿼리 최적화

### 3. 테스트
```dart
// UserLocationService 단위 테스트 예시
test('should return active location when LocationTag exists', () async {
  // given
  when(mockLocationTagRepository.getLocationTagByName('강남동'))
      .thenAnswer((_) async => mockLocationTag);
  
  // when
  final result = await userLocationService.registerUserWithLocation(
    name: '테스트',
    inputAddress: '서울특별시 강남구 강남동',
  );
  
  // then
  expect(result.locationStatus, equals('active'));
  expect(result.locationTagName, equals('강남동'));
});
```

---

**📝 업데이트**: 2024년 버전  
**👨‍💻 작성자**: Flutter AuthRepository 리팩토링 팀 