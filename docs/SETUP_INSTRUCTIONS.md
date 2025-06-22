# 🔒 토스페이먼츠 보안 설정 가이드

## 📋 개요

이 가이드는 토스페이먼츠 시크릿 키를 Firebase Cloud Functions에서 안전하게 관리하는 방법을 설명합니다.

## 🚀 Firebase Cloud Functions 설정

### 1. Firebase CLI 설치 및 로그인

```bash
# Firebase CLI 설치
npm install -g firebase-tools

# Firebase 로그인
firebase login

# 프로젝트 초기화 (이미 완료된 경우 스킵)
firebase init functions
```

### 2. 환경 변수 설정

```bash
# 토스페이먼츠 시크릿 키 설정
firebase functions:config:set toss.secret_key="test_sk_9OLNqbzXKBEVynyMO3A67YmpXyZA"

# 설정 확인
firebase functions:config:get
```

### 3. Functions 의존성 설치 및 배포

```bash
# functions 디렉토리로 이동
cd functions

# 의존성 설치
npm install

# Cloud Functions 배포
firebase deploy --only functions
```

## 🔧 프로덕션 환경 설정

### 1. 실제 토스페이먼츠 키로 변경

```bash
# 실제 시크릿 키로 변경 (토스페이먼츠 개발자센터에서 발급)
firebase functions:config:set toss.secret_key="live_sk_실제키입력"

# 실제 클라이언트 키로 .env 파일 수정
# TOSS_CLIENT_KEY=live_ck_실제키입력

# 재배포
firebase deploy --only functions
```

### 2. CSP 설정 활성화

`web/index.html` 파일에서 CSP 주석을 해제하여 보안 강화:

```html
<!-- 프로덕션 배포 시 이 주석을 해제하세요 -->
<meta http-equiv="Content-Security-Policy" content="...">
```

## 🧪 테스트

### 1. 로컬 에뮬레이터 테스트

```bash
# Firebase 에뮬레이터 실행
firebase emulators:start --only functions

# Flutter 앱에서 에뮬레이터 사용하도록 설정
# lib/main.dart에서 useEmulator 설정
```

### 2. 결제 플로우 테스트

1. Flutter 앱 실행
2. 상품 주문 진행
3. 결제 화면에서 테스트 카드 정보 입력
4. 결제 승인이 Cloud Functions를 통해 처리되는지 확인

## 🔒 보안 체크리스트

- [ ] 시크릿 키가 클라이언트 코드에서 완전 제거됨
- [ ] Firebase Functions 환경 변수로 시크릿 키 설정됨
- [ ] CSP 설정이 프로덕션에서 활성화됨
- [ ] 실제 토스페이먼츠 키로 교체됨 (프로덕션)
- [ ] 결제 승인이 서버에서만 처리됨

## 🚨 주의사항

1. **시크릿 키 노출 금지**: GitHub 등 공개 저장소에 시크릿 키를 절대 커밋하지 마세요
2. **환경 분리**: 개발/테스트/프로덕션 환경별로 다른 키를 사용하세요
3. **정기적인 키 교체**: 보안을 위해 정기적으로 키를 교체하세요
4. **로그 모니터링**: Firebase Functions 로그를 정기적으로 확인하세요

## 📞 문제 해결

### Functions 배포 실패 시

```bash
# 로그 확인
firebase functions:log

# 강제 재배포
firebase deploy --only functions --force
```

### 환경 변수 설정 실패 시

```bash
# 현재 설정 확인
firebase functions:config:get

# 설정 삭제 후 재설정
firebase functions:config:unset toss
firebase functions:config:set toss.secret_key="새로운키"
```

## 📚 참고 자료

- [토스페이먼츠 개발자 가이드](https://docs.tosspayments.com/)
- [Firebase Functions 환경 설정](https://firebase.google.com/docs/functions/config-env)
- [Flutter Cloud Functions 연동](https://firebase.flutter.dev/docs/functions/usage/) 