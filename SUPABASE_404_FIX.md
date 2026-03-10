# Supabase 404 에러 해결 가이드

## 🔴 문제: HTTP 404 에러

**에러 메시지**: `작품 추가 실패: httpError(statusCode: 404, message: nil)`

404 에러는 **요청한 리소스를 찾을 수 없다**는 의미입니다.

---

## ✅ 해결 방법

### 1단계: Supabase 테이블 확인

Supabase 대시보드에서 `artworks` 테이블이 생성되어 있는지 확인:

1. Supabase 대시보드 접속
2. 왼쪽 메뉴에서 **Table Editor** 클릭
3. `artworks` 테이블이 있는지 확인

**테이블이 없다면 생성하세요:**

```sql
CREATE TABLE artworks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  image_urls TEXT[],
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
```

### 2단계: 테이블 이름 확인

Supabase는 **대소문자를 구분**합니다. 테이블 이름이 정확히 `artworks`인지 확인하세요.

- ✅ `artworks` (소문자)
- ❌ `Artworks` (대문자)
- ❌ `ARTWORKS` (대문자)

### 3단계: RLS (Row Level Security) 확인

RLS가 활성화되어 있으면 정책이 필요합니다. 테스트를 위해 일시적으로 비활성화:

1. Table Editor → `artworks` 테이블 선택
2. Settings (톱니바퀴 아이콘) 클릭
3. **Row Level Security** 섹션
4. "Enable RLS" 토글을 **OFF**로 설정

또는 정책 추가:

```sql
-- 모든 사용자가 읽기 가능
CREATE POLICY "Enable read access for all users" ON artworks
    FOR SELECT USING (true);

-- 모든 사용자가 삽입 가능 (테스트용)
CREATE POLICY "Enable insert for all users" ON artworks
    FOR INSERT WITH CHECK (true);
```

### 4단계: API Key 확인

Supabase 대시보드에서:
1. Settings → API
2. **anon public** key가 올바른지 확인
3. 현재 사용 중인 key: `sb_publishable_BRgBtm2-xQDoAJS_hvGoJQ_MXf6QX-C`

⚠️ **주의**: `sb_publishable_`로 시작하는 key는 Supabase의 새로운 형식입니다. 
만약 `eyJhbGc...` 형식의 key를 사용해야 한다면 Supabase 대시보드에서 확인하세요.

### 5단계: URL 확인

현재 설정된 URL:
- Base URL: `https://nagnnsfjvstazpfmvbfw.supabase.co`
- Endpoint: `/rest/v1/artworks`
- **최종 URL**: `https://nagnnsfjvstazpfmvbfw.supabase.co/rest/v1/artworks`

이 URL이 올바른지 확인하세요.

---

## 🔍 디버깅

### Xcode 콘솔에서 확인할 정보

앱을 다시 실행하고 작품을 등록하면 다음 정보가 출력됩니다:

```
📤 작품 등록 요청:
   Full URL: https://nagnnsfjvstazpfmvbfw.supabase.co/rest/v1/artworks
   Method: POST
   Base URL: https://nagnnsfjvstazpfmvbfw.supabase.co
   Base API URL: https://nagnnsfjvstazpfmvbfw.supabase.co
   Endpoint: /rest/v1/artworks
   Body: [...]
```

### Supabase 대시보드 로그 확인

1. Supabase 대시보드 → **Logs** (왼쪽 메뉴)
2. **API Logs** 탭 선택
3. 최근 요청 확인
4. 404 에러의 상세 정보 확인

---

## 🎯 가장 가능성 높은 원인

1. **테이블이 생성되지 않음** (90% 확률)
   - 해결: 위의 SQL로 테이블 생성

2. **RLS 정책 문제** (5% 확률)
   - 해결: RLS 비활성화 또는 정책 추가

3. **테이블 이름 불일치** (5% 확률)
   - 해결: 테이블 이름 정확히 `artworks`로 확인

---

## 📝 체크리스트

- [ ] `artworks` 테이블이 Supabase에 생성되어 있음
- [ ] 테이블 이름이 정확히 `artworks` (소문자)
- [ ] RLS가 비활성화되어 있거나 정책이 설정되어 있음
- [ ] API Key가 올바름
- [ ] URL이 올바름 (`https://nagnnsfjvstazpfmvbfw.supabase.co/rest/v1/artworks`)

---

**테이블을 생성한 후 다시 시도해보세요!** 🚀

