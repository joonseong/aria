# 서버 연동 체크리스트

## ✅ 완료된 작업

1. **APIClient.swift** - 네트워크 요청 처리 클라이언트 생성
2. **ServerModels.swift** - 서버 응답 모델 및 변환 로직 정의
3. **ServerIntegrationExample.swift** - 각 Store 클래스별 서버 연동 예시 코드
4. **SERVER_INTEGRATION_GUIDE.md** - 상세한 서버 연동 가이드 문서

## 📋 다음 단계

### 1. 서버 URL 설정

`APIClient.swift` 파일을 열고 실제 서버 URL로 변경:

```swift
struct APIConfig {
    static let baseURL = "https://your-actual-server.com"  // ⚠️ 여기를 변경
    static let apiVersion = "v1"
}
```

### 2. 서버 API 엔드포인트 확인

서버 개발자와 함께 다음 사항을 확인:

- [ ] 인증 엔드포인트 (`/auth/login`, `/auth/logout` 등)
- [ ] 작품 관련 엔드포인트 (`/artworks`, `/artworks/{id}` 등)
- [ ] 프로필 관련 엔드포인트 (`/artist/profile`, `/user/profile` 등)
- [ ] 이미지 업로드 엔드포인트 (`/artworks/images`, `/artist/profile/image` 등)
- [ ] 응답 형식 (APIResponse 래퍼 사용 여부)
- [ ] 인증 방식 (Bearer Token, API Key 등)

### 3. Store 클래스 수정

각 Store 클래스에 서버 API 호출을 추가:

#### ArtworkStore
- [ ] `fetchArtworksFromServer()` - 서버에서 작품 목록 가져오기
- [ ] `addArtworkToServer()` - 서버에 작품 추가
- [ ] `fetchArtworksByArtistFromServer()` - 작가별 작품 가져오기

**참고**: `ServerIntegrationExample.swift`의 `ArtworkStore` extension 참고

#### ArtistProfileStore
- [ ] `fetchProfileFromServer()` - 서버에서 프로필 가져오기
- [ ] `updateProfileToServer()` - 서버에 프로필 업데이트

**참고**: `ServerIntegrationExample.swift`의 `ArtistProfileStore` extension 참고

#### LikeStore
- [ ] `toggleLikeOnServer()` - 서버에 좋아요 추가/제거
- [ ] `fetchLikedArtworksFromServer()` - 좋아요한 작품 목록 가져오기

**참고**: `ServerIntegrationExample.swift`의 `LikeStore` extension 참고

#### FollowStore
- [ ] `toggleFollowOnServer()` - 서버에 팔로우 추가/제거
- [ ] `fetchFollowedArtistsFromServer()` - 팔로우한 작가 목록 가져오기
- [ ] `fetchFollowCountFromServer()` - 팔로우 카운트 가져오기

**참고**: `ServerIntegrationExample.swift`의 `FollowStore` extension 참고

#### GuestBookStore
- [ ] 서버에서 방명록 가져오기
- [ ] 서버에 방명록 작성
- [ ] 서버에서 방명록 삭제

### 4. AuthService 수정

`AuthService.swift`의 로그인 메서드를 서버 API와 연동:

- [ ] `handleKakaoLoginSuccess()` - 카카오 로그인 후 서버에 로그인 요청
- [ ] `handleAppleLoginSuccess()` - 애플 로그인 후 서버에 로그인 요청
- [ ] `fetchUserRoleFromServer()` - 서버에서 사용자 역할 가져오기

**참고**: `ServerIntegrationExample.swift`의 `AuthService` extension 참고

### 5. 이미지 업로드 처리

이미지 업로드 로직 확인:

- [ ] 프로필 이미지 업로드 (`uploadProfileImage`)
- [ ] 작품 이미지 업로드 (`uploadArtworkImages`)
- [ ] 업로드된 이미지 URL 저장

### 6. 토큰 관리

인증 토큰 저장 방식 개선:

- [ ] 현재: `UserDefaults` 사용
- [ ] 권장: **Keychain** 사용 (보안 강화)
- [ ] 토큰 갱신 로직 구현 (`refreshToken`)

### 7. 에러 처리

사용자에게 적절한 에러 메시지 표시:

- [ ] 네트워크 오류 처리
- [ ] 인증 오류 처리 (401 Unauthorized)
- [ ] 서버 오류 처리 (500 등)
- [ ] 오프라인 모드 지원 (로컬 캐시 사용)

### 8. 로딩 상태

API 호출 중 로딩 인디케이터 표시:

- [ ] 각 View에 로딩 상태 추가
- [ ] 사용자 경험 개선

### 9. 테스트

- [ ] 실제 서버와 연동 테스트
- [ ] 네트워크 오류 시나리오 테스트
- [ ] 오프라인 모드 테스트

## 🔧 주요 파일 위치

- **API 클라이언트**: `aria/APIClient.swift`
- **서버 모델**: `aria/ServerModels.swift`
- **연동 예시**: `aria/ServerIntegrationExample.swift`
- **상세 가이드**: `SERVER_INTEGRATION_GUIDE.md`

## 📝 참고사항

1. **서버 응답 형식**: 서버의 실제 응답 형식에 맞게 `ServerModels.swift` 수정 필요
2. **에러 처리**: 서버의 에러 응답 형식에 맞게 `APIClient.swift` 수정 필요
3. **오프라인 지원**: 네트워크 오류 시 로컬 캐시를 사용하도록 구현 권장
4. **보안**: 프로덕션에서는 토큰을 Keychain에 저장하는 것을 강력히 권장

## 🚀 빠른 시작

1. `APIClient.swift`에서 서버 URL 설정
2. `ServerIntegrationExample.swift`의 예시 코드를 각 Store 클래스에 통합
3. `AuthService.swift`에 실제 로그인 API 호출 추가
4. 테스트 및 디버깅

---

**질문이나 문제가 있으면 `SERVER_INTEGRATION_GUIDE.md`를 참고하세요!**

