# Firebase Storage 규칙 설정 - 채팅 이미지

## 📌 설정 방법

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. **ondongne-e494a** 프로젝트 선택
3. 왼쪽 메뉴에서 **Storage** 클릭
4. 상단 탭에서 **Rules** 클릭
5. 아래 규칙 복사 → 붙여넣기 → **게시** 버튼 클릭

---

## 📝 Storage 규칙 (전체)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 상품 이미지
    match /products/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // 소식 이미지
    match /news/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // 프로필 이미지
    match /profile/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // ✨ 채팅 이미지 (새로 추가)
    match /chat/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

---

## ⚠️ 주의사항

- **read: if true** → 모든 사람이 이미지 볼 수 있음 (공개)
- **write: if request.auth != null** → 로그인한 사용자만 업로드 가능

---

## ✅ 설정 완료 확인

규칙 게시 후 **"규칙이 게시되었습니다"** 메시지가 나오면 완료!

---

이제 Flutter 코드에서 채팅 이미지를 업로드할 수 있어요! 📸

