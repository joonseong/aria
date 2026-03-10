# Role Hierarchy & Permission 정의 준수 현황

## 요약

| 항목 | 준수 | 비고 |
|------|------|------|
| canUpload()는 Artist만 통과 | ✅ | `AuthenticationManager.canUpload()` 추가 및 적용 |
| User: 작품 탐색/상호작용만, 업로드 불가 | ✅ | 업로드 진입점에 canUpload() 적용 |
| Artist: User 권한 + 작품 업로드/관리 | ✅ | 작품 등록·삭제는 Artist만 |
| 다른 사람 작품 볼 때 Artist도 User 권한으로 | ✅ | ProductDetailView에서 isViewingMyArtwork로 분기 |
| 데이터: Role 속성 기반 | ✅ | user_profiles.role, authManager.userRole |
| 상호작용: 작품 올릴 때 isArtist 체크 | ✅ | canUpload() 및 진입점 guard |

---

## 1. 권한 체크: canUpload()

- **위치**: `AuthenticationManager.canUpload() -> Bool`
- **규칙**: `userRole == .artist` 일 때만 `true`
- **사용처**:
  - `ProductRegisterButton`: 버튼을 `canUpload()` 일 때만 표시
  - `ProductEnterView.onAppear`: `!canUpload()` 이면 즉시 dismiss (이중 방어)

---

## 2. User (Base Role)

- **작품 탐색**: 홈·검색·작가별 작품 목록 — 로그인/게스트 모두 동일 UI
- **Like, Comment 등**: LikeStore, GuestBook 등으로 상호작용 가능
- **제한**: 작품 업로드 불가 — `canUpload()` 가 false 이므로 작품 등록 버튼 비노출, ProductEnterView 진입 시에도 dismiss

---

## 3. Artist (Extended Role)

- **User 기능 포함**: 동일한 탐색·좋아요·방명록 등
- **추가 기능**:
  - 작품 등록: `ProductRegisterButton` → `ProductEnterView` (canUpload() 통과 시만)
  - 작품 관리(삭제): `ProductDetailView`에서 **본인 작품일 때만** More(삭제) 버튼 표시  
    `artwork.artistName == profileStore.profile.nickname`
- **다른 사람 작품 볼 때**: User 권한으로 동작  
  - "작품이 마음에 드셨나요?" + 방명록 남기기 표시  
  - 삭제 버튼 미표시  
  - `isViewingMyArtwork == false` 로 분기

---

## 4. 데이터 모델링

- **Role 속성 기반**: Supabase `user_profiles.role` ("user" | "artist"), 앱에서는 `AuthenticationManager.userRole` (UserRole.user / .artist)
- **구조**: `UserProfile`(닉네임, 프로필 이미지) + `ArtistProfile`(작가용 확장 필드) 별도 모델. 서버는 `user_profiles` 한 테이블에 role 포함.  
  *(선택) 장기적으로 Artist가 User 프로필을 참조하는 Composition 모델로 정리 가능*

---

## 5. 상호작용 정리

- **작품 올릴 때**: `canUpload()` 체크 필수 — ProductRegisterButton 노출 조건 + ProductEnterView.onAppear guard
- **작품 감상할 때**: User 인터페이스 공통 사용 (좋아요, 방명록 등). Artist가 다른 사람 작품 볼 때도 동일 UI (`!isViewingMyArtwork`)

---

## 6. 수정된 파일 (이번 검증 반영)

- `AuthenticationManager.swift`: `canUpload()` 추가
- `DetailComponents.swift`: `ProductRegisterButton`에서 `canUpload()` 로 버튼 표시 제한
- `ProductEnterView.swift`: `onAppear`에서 `!canUpload()` 시 dismiss
- `ProductDetailView.swift`:  
  - 삭제 버튼: Artist + 본인 작품일 때만  
  - 메시지/방명록: `!isViewingMyArtwork` (User 또는 Artist가 타인 작품 볼 때)
