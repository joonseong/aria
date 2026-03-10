# 서버 연동 가이드

## 📋 목차
1. [개요](#개요)
2. [API 클라이언트 설정](#api-클라이언트-설정)
3. [서버 API 엔드포인트](#서버-api-엔드포인트)
4. [데이터 모델 매핑](#데이터-모델-매핑)
5. [Store 클래스 수정](#store-클래스-수정)
6. [이미지 업로드](#이미지-업로드)
7. [인증 토큰 관리](#인증-토큰-관리)
8. [에러 처리](#에러-처리)

---

## 개요

현재 앱은 로컬 저장소(UserDefaults)를 사용하고 있습니다. 실제 서버와 연동하려면:

1. **APIClient**: 네트워크 요청을 처리하는 클라이언트
2. **ServerModels**: 서버 응답 형식에 맞는 데이터 모델
3. **Store 수정**: 각 Store 클래스에 서버 API 호출 추가
4. **이미지 업로드**: 이미지를 서버에 업로드하고 URL 받기
5. **토큰 관리**: 인증 토큰 저장 및 갱신

---

## API 클라이언트 설정

### 1. 서버 URL 설정

`APIClient.swift` 파일에서 서버 URL을 설정하세요:

```swift
struct APIConfig {
    static let baseURL = "https://your-server.com"  // 실제 서버 URL
    static let apiVersion = "v1"
}
```

### 2. 토큰 저장 방식

현재는 `UserDefaults`를 사용하지만, 프로덕션에서는 **Keychain**을 사용하는 것을 권장합니다.

---

## 서버 API 엔드포인트

### 인증 (Auth)

#### 1. 로그인
```
POST /v1/auth/login
Body: {
    "provider": "kakao" | "apple",
    "token": "oauth_token",
    "userId": "user_id"
}
Response: {
    "success": true,
    "data": {
        "accessToken": "jwt_token",
        "refreshToken": "refresh_token",
        "userId": "user_id",
        "userRole": "user" | "artist",
        "expiresIn": 3600
    }
}
```

#### 2. 로그아웃
```
POST /v1/auth/logout
Headers: {
    "Authorization": "Bearer {accessToken}"
}
```

#### 3. 토큰 갱신
```
PUT /v1/auth/refresh
Body: {
    "refreshToken": "refresh_token"
}
Response: {
    "accessToken": "new_jwt_token",
    "expiresIn": 3600
}
```

#### 4. 회원탈퇴
```
DELETE /v1/auth/delete
Headers: {
    "Authorization": "Bearer {accessToken}"
}
```

### 작품 (Artwork)

#### 1. 작품 목록 조회
```
GET /v1/artworks?limit=20&offset=0
Response: {
    "success": true,
    "data": [
        {
            "id": "uuid",
            "imageUrls": ["url1", "url2"],
            "title": "작품명",
            "description": "설명",
            "year": "2024",
            "medium": "아크릴",
            "size": "100 cm X 100 cm",
            "artistId": "artist_uuid",
            "artistName": "작가명",
            "artistImageUrl": "url",
            "createdAt": "2024-01-01T00:00:00Z",
            "likeCount": 10,
            "isLiked": false
        }
    ]
}
```

#### 2. 작품 생성
```
POST /v1/artworks
Headers: {
    "Authorization": "Bearer {accessToken}"
}
Body: {
    "imageUrls": ["url1", "url2"],
    "title": "작품명",
    "description": "설명",
    "year": "2024",
    "medium": "아크릴",
    "size": "100 cm X 100 cm"
}
```

#### 3. 작가별 작품 조회
```
GET /v1/artworks/artist/{artistId}
```

### 작가 프로필 (Artist Profile)

#### 1. 작가 프로필 조회
```
GET /v1/artist/{artistId}/profile
Response: {
    "userId": "uuid",
    "profileImageUrl": "url",
    "nickname": "작가명",
    "features": ["기법1", "기법2"],
    "description": "소개",
    "instagramLink": "url",
    "youtubeLink": "url",
    "kakaoLink": "url",
    "emailLink": "email",
    "followCount": 10,
    "isFollowing": false
}
```

#### 2. 작가 프로필 업데이트
```
POST /v1/artist/profile
Headers: {
    "Authorization": "Bearer {accessToken}"
}
Body: {
    "profileImageUrl": "url",
    "nickname": "작가명",
    "features": ["기법1", "기법2"],
    "description": "소개",
    "instagramLink": "url",
    "youtubeLink": "url",
    "kakaoLink": "url",
    "emailLink": "email"
}
```

### 좋아요 (Like)

#### 1. 작품 좋아요
```
POST /v1/artworks/{artworkId}/like
Headers: {
    "Authorization": "Bearer {accessToken}"
}
```

#### 2. 작품 좋아요 취소
```
DELETE /v1/artworks/{artworkId}/unlike
Headers: {
    "Authorization": "Bearer {accessToken}"
}
```

#### 3. 좋아요한 작품 목록
```
GET /v1/artworks/liked
Headers: {
    "Authorization": "Bearer {accessToken}"
}
```

### 팔로우 (Follow)

#### 1. 작가 팔로우
```
POST /v1/artist/{artistId}/follow
Headers: {
    "Authorization": "Bearer {accessToken}"
}
```

#### 2. 작가 언팔로우
```
DELETE /v1/artist/{artistId}/unfollow
Headers: {
    "Authorization": "Bearer {accessToken}"
}
```

#### 3. 팔로우한 작가 목록
```
GET /v1/artist/followed
Headers: {
    "Authorization": "Bearer {accessToken}"
}
```

### 방명록 (Guestbook)

#### 1. 방명록 조회
```
GET /v1/guestbook/{artistId}
```

#### 2. 방명록 작성
```
POST /v1/guestbook/{artistId}
Headers: {
    "Authorization": "Bearer {accessToken}"
}
Body: {
    "content": "방명록 내용"
}
```

### 검색 (Search)

#### 1. 작품 검색
```
GET /v1/search/artworks?query={검색어}&limit=20&offset=0
```

#### 2. 작가 검색
```
GET /v1/search/artists?query={검색어}&limit=20&offset=0
```

---

## 데이터 모델 매핑

서버 응답을 앱 내부 모델로 변환하는 로직이 `ServerModels.swift`에 정의되어 있습니다.

### 변환 예시

```swift
// 서버 응답 → 앱 모델
let serverArtwork: ServerArtwork = ...
let postedArtwork = serverArtwork.toPostedArtwork()

// 앱 모델 → 서버 요청
let request = CreateArtworkRequest(
    imageUrls: artwork.imageUrls,
    title: artwork.title,
    description: artwork.description,
    year: artwork.year,
    medium: artwork.medium,
    size: artwork.size
)
```

---

## Store 클래스 수정

각 Store 클래스에 서버 API 호출을 추가해야 합니다. 예시:

### ArtworkStore 수정 예시

```swift
class ArtworkStore: ObservableObject {
    private let apiClient = APIClient.shared
    
    // 작품 목록 가져오기 (서버에서)
    func fetchArtworks() async throws {
        let artworks: [ServerArtwork] = try await apiClient.request(
            endpoint: APIEndpoint.getArtworks.path,
            method: APIEndpoint.getArtworks.method
        )
        
        await MainActor.run {
            self.artworks = artworks.compactMap { $0.toPostedArtwork() }
        }
    }
    
    // 작품 추가 (서버에 저장)
    func addArtwork(_ artwork: PostedArtwork) async throws {
        // 1. 이미지 업로드
        let imageUrls = try await uploadArtworkImages(artwork.imageUrls)
        
        // 2. 작품 생성 요청
        let request = CreateArtworkRequest(
            imageUrls: imageUrls,
            title: artwork.title,
            description: artwork.description,
            year: artwork.year,
            medium: artwork.medium,
            size: artwork.size
        )
        
        let serverArtwork: ServerArtwork = try await apiClient.request(
            endpoint: APIEndpoint.createArtwork.path,
            method: APIEndpoint.createArtwork.method,
            body: try request.toDictionary()
        )
        
        if let postedArtwork = serverArtwork.toPostedArtwork() {
            await MainActor.run {
                self.artworks.insert(postedArtwork, at: 0)
            }
        }
    }
}
```

---

## 이미지 업로드

### 단일 이미지 업로드

```swift
let imageUrl = try await APIClient.shared.uploadImage(
    image,
    endpoint: APIEndpoint.uploadProfileImage.path
)
```

### 여러 이미지 업로드

```swift
let imageUrls = try await APIClient.shared.uploadImages(
    images,
    endpoint: APIEndpoint.uploadArtworkImages.path
)
```

---

## 인증 토큰 관리

### 로그인 후 토큰 저장

```swift
// AuthService.swift의 loginWithKakao()에서
let loginResponse: LoginResponse = try await apiClient.request(
    endpoint: APIEndpoint.login(...).path,
    method: "POST",
    body: loginRequest
)

// 토큰 저장
APIClient.shared.setAccessToken(loginResponse.accessToken)
```

### 토큰 갱신

```swift
func refreshToken() async throws {
    let response: LoginResponse = try await apiClient.request(
        endpoint: APIEndpoint.refreshToken.path,
        method: APIEndpoint.refreshToken.method,
        body: ["refreshToken": refreshToken]
    )
    
    APIClient.shared.setAccessToken(response.accessToken)
}
```

---

## 에러 처리

### 네트워크 에러 처리

```swift
do {
    let artworks = try await apiClient.request(...)
} catch APIError.unauthorized {
    // 토큰 갱신 또는 재로그인
    try await refreshToken()
} catch APIError.networkError(let error) {
    // 네트워크 오류 처리
    print("Network error: \(error)")
} catch {
    // 기타 오류
    print("Error: \(error)")
}
```

---

## 다음 단계

1. ✅ API 클라이언트 생성 완료
2. ✅ 서버 모델 정의 완료
3. ⏳ 각 Store 클래스에 서버 API 호출 추가
4. ⏳ AuthService에 실제 로그인 API 연동
5. ⏳ 이미지 업로드 로직 구현
6. ⏳ 토큰 갱신 로직 구현
7. ⏳ 오프라인 지원 (로컬 캐시)

---

## 참고사항

- **서버 URL**: `APIClient.swift`의 `APIConfig.baseURL`을 실제 서버 URL로 변경
- **토큰 저장**: 프로덕션에서는 Keychain 사용 권장
- **에러 처리**: 사용자에게 적절한 에러 메시지 표시
- **로딩 상태**: API 호출 중 로딩 인디케이터 표시
- **오프라인 지원**: 네트워크 오류 시 로컬 캐시 사용

