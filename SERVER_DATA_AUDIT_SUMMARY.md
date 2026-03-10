# 서버 데이터 연동 점검 요약

## 1. 이미 서버 연동된 항목 ✅

| 데이터 | 저장소 | Supabase 테이블 | 비고 |
|--------|--------|-----------------|------|
| 작품 | ArtworkStore | artworks | 이미지: artwork-images Storage |
| 작가 프로필 | ArtistProfileStore | artist_profiles | 프로필 이미지는 로컬/URL 혼용 |
| 방명록 | GuestBookStore | guestbook | 완전 서버 연동 |

---

## 2. 이번에 서버 연동 완료한 항목 ✅

| 데이터 | 저장소 | Supabase 테이블 | 변경 내용 |
|--------|--------|-----------------|-----------|
| 일반 유저 프로필 | UserProfileStore | user_profiles | fetch/save 서버 연동, 프로필 이미지 → profile-images Storage |
| 좋아요 | LikeStore | likes | fetch/toggle 서버 연동 |
| 팔로우 | FollowStore | follows | fetch/toggle, 팔로우 카운트 서버 연동 |

---

## 3. Supabase 추가 설정 필요

`SUPABASE_ADDITIONAL_TABLES.md` 파일을 참고하여 다음을 실행하세요:

1. **user_profiles** 테이블 생성
2. **likes** 테이블 생성
3. **follows** 테이블 생성
4. **profile-images** Storage 버킷 생성 (Public)

---

## 4. 로컬 캐시 용도 (유지)

다음은 서버 동기화를 위한 로컬 캐시로, 그대로 두는 것이 좋습니다:

- **UserDefaults**  
  - SavedArtworks: ArtworkStore 오프라인/이미지 경로 복원  
  - ArtistProfile, UserProfile: 로그인 후 빠른 표시용 캐시  
  - LikedArtworks, FollowedArtists: 서버 연동 실패 시 fallback  
- **AuthenticationManager**  
  - CurrentUserId, LastAccessDate: 자동 로그인(30일)  
- **ServerConfig**  
  - ServerURL, SupabaseAPIKey

---

## 5. 추가 고려 사항 (선택)

| 항목 | 설명 |
|------|------|
| ArtistProfile 이미지 | 현재 로컬 경로 저장. Supabase Storage 업로드 추가 시 다른 기기에서도 표시 가능 |
| AccountManager 탈퇴 | 로컬만 초기화. 서버 사용자/관련 데이터 삭제 API는 별도 구현 필요 |
