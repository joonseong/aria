# Supabase 작품 등록 디버깅 가이드

## 문제: 작품 등록 후 Supabase 테이블에 데이터가 나타나지 않음

### 확인 사항

1. **Supabase 테이블 구조 확인**
   - Supabase 대시보드 → Table Editor → `artworks` 테이블 확인
   - 다음 컬럼들이 있는지 확인:
     - `id` (uuid, primary key, default: uuid_generate_v4())
     - `image_urls` (text[] 또는 jsonb)
     - `title` (text, not null)
     - `description` (text, nullable)
     - `year` (text, not null)
     - `medium` (text, not null)
     - `size` (text, not null)
     - `artist_id` (uuid, nullable)
     - `artist_name` (text, nullable)
     - `artist_image_url` (text, nullable)
     - `created_at` (timestamptz, default: now())

2. **Row Level Security (RLS) 확인**
   - Supabase 대시보드 → Authentication → Policies
   - `artworks` 테이블의 RLS가 활성화되어 있으면 정책이 필요합니다
   - 테스트를 위해 일시적으로 RLS를 비활성화할 수 있습니다:
     ```sql
     ALTER TABLE artworks DISABLE ROW LEVEL SECURITY;
     ```

3. **API 요청 확인**
   - Xcode 콘솔에서 에러 메시지 확인
   - "❌ 작품 추가 실패: ..." 메시지 확인
   - HTTP 상태 코드 확인 (401, 403, 404, 500 등)

4. **엔드포인트 확인**
   - 현재 사용 중인 엔드포인트: `/rest/v1/artworks`
   - 전체 URL: `https://nagnnsfjvstazpfmvbfw.supabase.co/rest/v1/artworks`

5. **요청 데이터 형식 확인**
   - Supabase는 PostgreSQL을 사용하므로 컬럼명이 정확해야 합니다
   - 현재 요청 형식:
     ```json
     {
       "image_urls": ["url1", "url2"],
       "title": "작품명",
       "description": "설명",
       "year": "2024",
       "medium": "아크릴",
       "size": "100 cm X 100 cm"
     }
     ```

### 해결 방법

#### 방법 1: RLS 비활성화 (테스트용)

Supabase 대시보드에서:
1. Table Editor → `artworks` 테이블 선택
2. Settings → Row Level Security
3. "Enable RLS" 토글을 OFF로 설정

#### 방법 2: RLS 정책 추가 (프로덕션용)

```sql
-- 모든 사용자가 읽기 가능
CREATE POLICY "Enable read access for all users" ON artworks
    FOR SELECT USING (true);

-- 인증된 사용자가 삽입 가능
CREATE POLICY "Enable insert for authenticated users" ON artworks
    FOR INSERT WITH CHECK (true);
```

#### 방법 3: 컬럼명 확인

Supabase 테이블의 컬럼명이 요청 데이터의 키와 정확히 일치하는지 확인:
- `image_urls` (snake_case) ✅
- `title` ✅
- `description` ✅
- `year` ✅
- `medium` ✅
- `size` ✅

### 디버깅 코드 추가

`ArtworkStore.swift`의 `addArtworkToServer` 메서드에 디버깅 코드 추가:

```swift
print("📤 작품 등록 요청:")
print("   URL: \(APIConfig.baseAPIURL)\(APIEndpoint.createArtwork.path)")
print("   Method: \(APIEndpoint.createArtwork.method)")
print("   Body: \(try request.toDictionary())")
```

### 테스트 방법

1. 앱에서 작품 등록
2. Xcode 콘솔에서 에러 메시지 확인
3. Supabase 대시보드 → Table Editor → `artworks` 테이블 확인
4. Network 탭에서 실제 요청 확인 (필요시)

### 일반적인 오류

- **401 Unauthorized**: API Key가 잘못되었거나 RLS 정책 문제
- **403 Forbidden**: RLS 정책이 삽입을 허용하지 않음
- **404 Not Found**: 테이블이 존재하지 않음
- **400 Bad Request**: 요청 데이터 형식이 잘못됨 (컬럼명 불일치 등)

