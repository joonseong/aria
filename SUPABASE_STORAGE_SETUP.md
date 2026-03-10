# Supabase Storage 설정 가이드

**한 번에 SQL 적용:** 테이블 + Storage RLS까지 한꺼번에 넣으려면 프로젝트 루트의 **`supabase_full_setup.sql`** 을 SQL Editor에 붙여넣고 실행하세요.

## 📦 Storage 버킷 생성하기

### 1. Supabase 대시보드에서 Storage 생성

1. Supabase 대시보드 → **Storage** 메뉴 클릭
2. **Create a new bucket** 클릭
3. 버킷 정보 입력:
   - **Name**: `artwork-images` 또는 `profile-images` (아래 참고)
   - **Public bucket**: ✅ **체크** (public으로 열기)
   - **File size limit**: 원하는 크기 (예: 10MB)
   - **Allowed MIME types**: `image/jpeg, image/png, image/jpg` (또는 `image/*`로 모든 이미지 허용)
4. **Create bucket** 클릭

**필요한 버킷**
- `artwork-images`: 작품 이미지 업로드
- `profile-images`: 사용자/아티스트 프로필 이미지 업로드 (프로필 수정 시 사용)

### 2. Storage RLS 정책 (필수 – 업로드 403/400 방지)

**이미지 업로드 시 "new row violates row-level security policy" (403)가 나오면** `storage.objects` 테이블에 **INSERT** 정책이 없거나, anon이 막혀 있는 상태입니다.

1. Supabase 대시보드 → **Storage** → **Policies** (또는 **SQL Editor**)
2. **New Policy** 또는 아래 SQL 실행:

**옵션 A: anon으로도 업로드 허용 (카카오/애플 로그인 시 필수)**

아래 **두 정책 모두** SQL Editor에서 실행하세요. 프로필 이미지만 실패한다면 `profile-images` 정책이 없는 경우입니다.

```sql
-- 1) 작품 이미지 버킷
CREATE POLICY "Allow anon upload artwork-images"
ON storage.objects FOR INSERT TO anon WITH CHECK (bucket_id = 'artwork-images');

-- 2) 프로필 이미지 버킷 (프로필 수정 시 사용 — 이게 없으면 "new row violates row-level security policy" 403 발생)
CREATE POLICY "Allow anon upload profile-images"
ON storage.objects FOR INSERT TO anon WITH CHECK (bucket_id = 'profile-images');
```

이미 같은 이름의 정책이 있으면 에러가 나므로, **New Policy**로 하나씩 추가할 때는:
- **Policy name**: `Allow anon upload profile-images`
- **Allowed operation**: `INSERT`
- **Target roles**: `anon`
- **WITH CHECK expression**: `bucket_id = 'profile-images'`

**옵션 B: Supabase Auth 로그인 사용자만 업로드**

```sql
CREATE POLICY "Allow authenticated upload artwork"
ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'artwork-images');
CREATE POLICY "Allow authenticated upload profile"
ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'profile-images');
```

- **anon**: 앱에서 Supabase API Key만 쓰는 경우(카카오/애플 로그인) → **옵션 A** 사용
- **authenticated**: Supabase 로그인 JWT를 앱에서 쓰는 경우 → **옵션 B** 사용

### 3. API Key 확인

1. Settings → **API** 메뉴
2. **anon public key** 복사
3. 앱 코드에 설정 (이미 설정되어 있다면 확인만)

---

## ✅ 체크리스트

- [ ] `artwork-images` 버킷 생성 완료
- [ ] `profile-images` 버킷 생성 완료 (프로필 이미지용)
- [ ] Public bucket으로 설정 완료
- [ ] **Storage RLS: `storage.objects` INSERT 정책 추가** (위 2번 참고)
- [ ] File size limit 설정 완료
- [ ] Allowed MIME types 설정 완료
- [ ] API Key 확인 완료

---

## 🧪 테스트

버킷이 제대로 생성되었는지 확인:

1. Storage → `artwork-images` 버킷 클릭
2. **Upload file** 버튼으로 테스트 이미지 업로드
3. 업로드된 파일의 **Public URL** 확인
4. 브라우저에서 Public URL 접근 테스트

---

## 📝 참고사항

- **Public 버킷**: URL만 알면 누구나 접근 가능 (작품 이미지에 적합)
- **Private 버킷**: 인증 필요 (민감한 파일용)
- **파일 경로**: `{bucket}/{fileName}` 형식
- **Public URL 형식**: `https://{project}.supabase.co/storage/v1/object/public/{bucket}/{fileName}`

---

## 🔧 프로필 이미지 업로드가 403 / "new row violates row-level security policy" 일 때

1. **Supabase 대시보드** → **SQL Editor** 이동
2. 아래 SQL **그대로 실행** (프로필 버킷만 허용하는 정책 추가):

```sql
CREATE POLICY "Allow anon upload profile-images"
ON storage.objects FOR INSERT TO anon WITH CHECK (bucket_id = 'profile-images');
```

3. 이미 정책이 있다는 에러가 나면: **Storage** → **Policies** → `storage.objects` 테이블에서  
   `profile-images` 버킷에 대한 **INSERT for anon** 정책이 있는지 확인 후, 없으면 **New Policy**로 위 조건으로 추가
4. 앱 다시 실행 후 프로필 이미지 변경 → 저장

**버킷 생성이 완료되고 RLS 정책까지 적용되면 앱에서 이미지가 자동으로 업로드됩니다!** 🎉

