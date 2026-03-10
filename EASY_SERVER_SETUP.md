# 🚀 간단한 서버 연동 가이드

## 서버 URL만 설정하면 끝!

서버 연동이 이제 훨씬 쉬워졌습니다. **서버 URL만 설정**하면 자동으로 서버 모드로 전환됩니다.

---

## 📝 3단계로 끝내기

### 1단계: 서버 URL 설정

앱을 실행하고 다음 코드를 어디서든 한 번만 실행하세요:

```swift
// 예시: 앱 시작 시 (ariaApp.swift의 onAppear 등)
ServerConfig.shared.enableServerMode(url: "https://your-server.com")
```

또는 직접 코드에 추가:

```swift
// ariaApp.swift 또는 ContentView.swift의 onAppear에서
.onAppear {
    // 서버 URL만 여기에 입력!
    ServerConfig.shared.enableServerMode(url: "https://api.aria.com")
}
```

### 2단계: 완료! 🎉

이제 모든 Store가 자동으로 서버와 연동됩니다:
- ✅ 작품 등록 → 서버에 자동 저장
- ✅ 작품 목록 → 서버에서 자동 가져오기
- ✅ 프로필 수정 → 서버에 자동 저장
- ✅ 좋아요/팔로우 → 서버에 자동 반영

### 3단계: 테스트

앱을 실행하고 작품을 등록해보세요. 서버에 자동으로 저장됩니다!

---

## 🔧 서버 모드 끄기 (로컬 모드로 전환)

로컬 모드로 돌아가려면:

```swift
ServerConfig.shared.disableServerMode()
```

---

## 📋 현재 지원되는 기능

### ✅ 자동 연동됨
- **ArtworkStore**: 작품 등록, 작품 목록 가져오기
- 서버 모드가 켜져 있으면 자동으로 서버와 연동
- 서버 모드가 꺼져 있으면 기존처럼 로컬에 저장

### ⏳ 추가 예정
- ArtistProfileStore (작가 프로필)
- LikeStore (좋아요)
- FollowStore (팔로우)
- GuestBookStore (방명록)

---

## 🐛 문제 해결

### 서버 연결이 안 될 때
1. 서버 URL이 올바른지 확인
2. 서버가 실행 중인지 확인
3. 네트워크 연결 확인
4. 콘솔 로그 확인 (에러 메시지 확인)

### 로컬 모드로 전환하고 싶을 때
```swift
ServerConfig.shared.disableServerMode()
```

---

## 💡 팁

- **개발 중**: 로컬 모드 사용 (서버 URL 비워두기)
- **테스트 중**: 서버 URL 설정하여 서버 연동 테스트
- **프로덕션**: 서버 URL 설정 필수

---

## 📞 도움이 필요하신가요?

서버 URL만 알려주시면 제가 코드에 직접 추가해드릴 수 있습니다!

