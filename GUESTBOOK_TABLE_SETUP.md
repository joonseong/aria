# 방명록(guestbook) 테이블 생성 가이드

## 📋 Supabase에 guestbook 테이블 생성하기

Supabase 대시보드에서 다음 SQL을 실행하세요:

### 1. SQL Editor에서 실행

Supabase 대시보드 → **SQL Editor** → **New Query** 클릭 후 아래 SQL 실행:

```sql
-- guestbook 테이블 생성
CREATE TABLE IF NOT EXISTS public.guestbook (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  artist_name TEXT NOT NULL,  -- 작가 이름 (nickname)
  artist_id UUID,  -- 작가 ID (선택사항, artist_profiles 참조 가능)
  user_id UUID,  -- 작성자 ID (선택사항)
  user_name TEXT NOT NULL,  -- 작성자 이름
  user_image_url TEXT,  -- 작성자 프로필 이미지
  content TEXT NOT NULL,  -- 방명록 내용
  is_artist BOOLEAN DEFAULT false,  -- 작가가 작성한 글인지 여부
  created_at TIMESTAMPTZ DEFAULT NOW()  -- 작성 시간
);

-- 인덱스 생성 (작가별 조회 성능 향상)
CREATE INDEX IF NOT EXISTS idx_guestbook_artist_name ON public.guestbook(artist_name);
CREATE INDEX IF NOT EXISTS idx_guestbook_created_at ON public.guestbook(created_at DESC);

-- RLS 비활성화 (테스트용 - 프로덕션에서는 정책 설정 필요)
ALTER TABLE public.guestbook DISABLE ROW LEVEL SECURITY;

-- 또는 RLS 활성화하고 정책 설정 (권장)
-- ALTER TABLE public.guestbook ENABLE ROW LEVEL SECURITY;
-- 
-- -- 모든 사용자가 읽기 가능
-- CREATE POLICY "Anyone can read guestbook" ON public.guestbook
--   FOR SELECT USING (true);
-- 
-- -- 인증된 사용자만 작성 가능
-- CREATE POLICY "Authenticated users can insert" ON public.guestbook
--   FOR INSERT WITH CHECK (auth.role() = 'authenticated');
-- 
-- -- 작성자만 삭제 가능 (선택사항)
-- CREATE POLICY "Users can delete own entries" ON public.guestbook
--   FOR DELETE USING (auth.uid()::text = user_id::text);
```

### 2. 테이블 확인

SQL Editor에서 다음 쿼리로 테이블이 제대로 생성되었는지 확인:

```sql
-- 테이블 구조 확인
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'guestbook'
ORDER BY ordinal_position;

-- 테이블 존재 확인
SELECT * FROM public.guestbook LIMIT 1;
```

### 3. 테이블 필드 설명

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `id` | UUID | 고유 ID (자동 생성) |
| `artist_name` | TEXT | 작가 이름 (필수) |
| `artist_id` | UUID | 작가 ID (선택사항) |
| `user_id` | UUID | 작성자 ID (선택사항) |
| `user_name` | TEXT | 작성자 이름 (필수) |
| `user_image_url` | TEXT | 작성자 프로필 이미지 URL |
| `content` | TEXT | 방명록 내용 (필수) |
| `is_artist` | BOOLEAN | 작가가 작성한 글인지 여부 |
| `created_at` | TIMESTAMPTZ | 작성 시간 (자동 생성) |

### 4. API 테스트

Supabase 대시보드 → **API** → **REST**에서 테스트:

**GET 요청 (방명록 조회):**
```
GET https://your-project.supabase.co/rest/v1/guestbook?artist_name=eq.작가이름
Headers:
  apikey: your-anon-key
  Authorization: Bearer your-anon-key
```

**POST 요청 (방명록 작성):**
```
POST https://your-project.supabase.co/rest/v1/guestbook
Headers:
  apikey: your-anon-key
  Authorization: Bearer your-anon-key
  Content-Type: application/json
  Prefer: return=representation
Body:
{
  "artist_name": "작가이름",
  "user_name": "작성자이름",
  "content": "방명록 내용",
  "is_artist": false
}
```

### 5. 기존 테이블이 있는 경우

기존 테이블을 삭제하고 재생성하려면:

```sql
-- ⚠️ 주의: 기존 데이터가 모두 삭제됩니다!
DROP TABLE IF EXISTS public.guestbook CASCADE;

-- 위의 CREATE TABLE SQL 다시 실행
```

---

## ✅ 체크리스트

- [ ] SQL Editor에서 테이블 생성 SQL 실행 완료
- [ ] 테이블 구조 확인 완료
- [ ] 인덱스 생성 완료
- [ ] RLS 설정 완료 (또는 비활성화)
- [ ] API 테스트 성공 (200 응답)

---

**테이블 생성이 완료되면 앱에서 방명록 기능을 사용할 수 있습니다!** 🎉

