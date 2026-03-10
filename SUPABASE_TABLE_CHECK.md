# Supabase 테이블 확인 가이드

## 🔍 404 에러가 계속 발생하는 경우

테이블을 생성했는데도 404가 발생한다면 다음을 확인하세요:

### 1. 테이블이 public 스키마에 있는지 확인

Supabase는 기본적으로 `public` 스키마를 사용합니다. 테이블이 다른 스키마에 있으면 접근할 수 없습니다.

**확인 방법:**
1. Supabase 대시보드 → Table Editor
2. `artworks` 테이블 선택
3. SQL Editor에서 다음 쿼리 실행:

```sql
SELECT table_schema, table_name 
FROM information_schema.tables 
WHERE table_name = 'artworks';
```

결과가 `public.artworks`여야 합니다.

### 2. 테이블이 실제로 존재하는지 확인

SQL Editor에서:

```sql
SELECT * FROM artworks LIMIT 1;
```

에러가 나지 않으면 테이블이 존재합니다.

### 3. 테이블 구조 확인

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'artworks'
ORDER BY ordinal_position;
```

다음 컬럼들이 있어야 합니다:
- `id` (uuid)
- `image_urls` (text[] 또는 jsonb)
- `title` (text)
- `description` (text)
- `year` (text)
- `medium` (text)
- `size` (text)
- `artist_name` (text)
- `artist_image_url` (text)
- `created_at` (timestamptz)

### 4. 테이블 재생성 (완전 삭제 후 재생성)

만약 테이블이 제대로 생성되지 않았다면:

```sql
-- 기존 테이블 삭제 (주의!)
DROP TABLE IF EXISTS artworks CASCADE;

-- 테이블 재생성
CREATE TABLE public.artworks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  image_urls TEXT[] DEFAULT '{}',
  title TEXT NOT NULL,
  description TEXT,
  year TEXT NOT NULL,
  medium TEXT NOT NULL,
  size TEXT NOT NULL,
  artist_id UUID,
  artist_name TEXT,
  artist_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 비활성화 (테스트용)
ALTER TABLE public.artworks DISABLE ROW LEVEL SECURITY;
```

### 5. API 접근 권한 확인

Supabase 대시보드 → Settings → API에서:
- **Project URL**이 올바른지 확인
- **anon public key**가 올바른지 확인

### 6. 직접 API 테스트

Supabase 대시보드 → API → REST에서 직접 테스트:

**GET 요청:**
```
GET https://nagnnsfjvstazpfmvbfw.supabase.co/rest/v1/artworks
Headers:
  apikey: sb_publishable_BRgBtm2-xQDoAJS_hvGoJQ_MXf6QX-C
  Authorization: Bearer sb_publishable_BRgBtm2-xQDoAJS_hvGoJQ_MXf6QX-C
```

**POST 요청:**
```
POST https://nagnnsfjvstazpfmvbfw.supabase.co/rest/v1/artworks
Headers:
  apikey: sb_publishable_BRgBtm2-xQDoAJS_hvGoJQ_MXf6QX-C
  Authorization: Bearer sb_publishable_BRgBtm2-xQDoAJS_hvGoJQ_MXf6QX-C
  Content-Type: application/json
  Prefer: return=representation
Body:
{
  "title": "테스트 작품",
  "year": "2024",
  "medium": "테스트",
  "size": "100 cm X 100 cm",
  "image_urls": []
}
```

---

## 🎯 체크리스트

- [ ] 테이블이 `public` 스키마에 있음
- [ ] 테이블 이름이 정확히 `artworks` (소문자)
- [ ] 모든 필수 컬럼이 존재함
- [ ] RLS가 비활성화되어 있음
- [ ] SQL Editor에서 `SELECT * FROM artworks` 쿼리가 성공함
- [ ] API에서 직접 GET 요청이 성공함 (200 응답)

---

**위의 SQL로 테이블을 재생성한 후 다시 시도해보세요!**

