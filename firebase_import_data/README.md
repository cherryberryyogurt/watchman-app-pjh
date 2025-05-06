# Firebase 더미 데이터 가져오기 안내

이 디렉토리에는 Firebase에 가져올 수 있는 더미 데이터 JSON 파일이 포함되어 있습니다.

## 파일 설명
- `products.json`: 상품 데이터
- `users.json`: 사용자 데이터

## Firebase에 데이터 가져오기 방법

### 1. Firebase 콘솔에 로그인
Firebase 콘솔(https://console.firebase.google.com/)에 접속하여 프로젝트를 선택합니다.

### 2. Firestore 데이터베이스로 이동
좌측 메뉴에서 "Firestore Database"를 선택합니다.

### 3. 데이터 가져오기 (사용자 데이터)
1. 컬렉션 목록에서 `users` 컬렉션을 선택합니다. (없다면 컬렉션을 먼저 생성합니다.)
2. JSON 파일의 각 항목을 개별 문서로 추가합니다:
   - `users.json` 파일의 각 객체마다:
     - 문서 ID를 해당 객체의 `uid` 값으로 설정합니다.
     - 필드 데이터를 해당 객체의 내용으로 설정합니다.

### 4. 데이터 가져오기 (상품 데이터)
1. 컬렉션 목록에서 `products` 컬렉션을 선택합니다. (없다면 컬렉션을 먼저 생성합니다.)
2. JSON 파일의 각 항목을 개별 문서로 추가합니다:
   - `products.json` 파일의 각 객체마다:
     - 문서 ID는 자동 생성되도록 합니다.
     - 필드 데이터를 해당 객체의 내용으로 설정합니다.

### 주의사항
- Timestamp 타입 필드(`createdAt`, `updatedAt`)는 Firebase에서 자동으로 변환됩니다.
- GeoPoint 타입 필드(`coordinates`)는 Firebase에서 자동으로 변환됩니다.
- 실제 이미지 URL을 사용하려면 `imageUrls` 필드의 값을 실제 이미지 URL로 변경하세요.

## 자동화 스크립트 사용하기

Firebase Admin SDK를 사용하여 데이터를 자동으로 가져올 수도 있습니다. 이 방법을 사용하려면 다음과 같은 스크립트를 작성하여 실행할 수 있습니다:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');
const usersData = require('./users.json');
const productsData = require('./products.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function importData() {
  // Import users
  for (const user of usersData.users) {
    await db.collection('users').doc(user.uid).set(user);
    console.log(`Added user: ${user.name}`);
  }

  // Import products
  for (const product of productsData.products) {
    await db.collection('products').add(product);
    console.log(`Added product: ${product.name}`);
  }

  console.log('Import completed!');
}

importData().catch(console.error);
```

이 스크립트를 실행하려면 Firebase Admin SDK를 설치하고 서비스 계정 키가 필요합니다. 