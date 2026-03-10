# Supabase 추가 테이블 설정 (user_profiles, likes, follows)

로컬 데이터만 사용 중인 **일반 유저 프로필**, **좋아요**, **팔로우** 기능을 서버 연동하려면 아래 테이블을 Supabase에 추가하세요.

---

## 1. user_profiles 테이블 (일반 유저 프로필)

일반 유저(비작가)의 닉네임과 프로필 이미지를 저장합니다.

**자동 생성**: 로그인 시 프로필이 없으면 앱이 자동으로 행을 생성하며, 기본 닉네임은 미술 관련 형용사+명사 조합(예: 모던캔버스, 추상팔레트)으로 랜덤 부여됩니다. 사용자가 프로필 편집 화면에서 수정 가능합니다.

**역할(role)**: 계정당 하나만 부여. `user`(일반 유저) 또는 `artist`(작가). Supabase Table Editor에서 `artist`로 변경하면 작가 권한이 부여됩니다.

**이메일 & 로그인 수단**: 로그인 시 자동으로 저장됩니다.

```sql
-- user_profiles 테이블 생성
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT UNIQUE NOT NULL,  -- 카카오/애플 로그인 사용자 ID
  profile_image_url TEXT,        -- 프로필 이미지 URL (Supabase Storage)
  nickname TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL DEFAULT 'user',  -- 'user' | 'artist' (계정당 하나)
  email TEXT,                    -- 로그인 계정 이메일 (카카오/애플)
  login_provider TEXT,           -- 'kakao' | 'apple'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 기존 테이블에 컬럼 추가 (이미 테이블이 있는 경우)
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'user';
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS login_provider TEXT;

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);

-- RLS (테스트용 비활성화)
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- 또는 RLS 활성화 시 (프로덕션)
-- ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Users can read all profiles" ON public.user_profiles FOR SELECT USING (true);
-- CREATE POLICY "Users can insert own profile" ON public.user_profiles FOR INSERT WITH CHECK (true);
-- CREATE POLICY "Users can update own profile" ON public.user_profiles FOR UPDATE USING (true);
```

---

## 2. likes 테이블 (작품 좋아요)

사용자가 좋아요한 작품을 저장합니다.

```sql
-- likes 테이블 생성
CREATE TABLE IF NOT EXISTS public.likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,         -- 좋아요한 사용자 ID
  artwork_id UUID NOT NULL,      -- artworks 테이블의 id 참조
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, artwork_id)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON public.likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_artwork_id ON public.likes(artwork_id);

-- RLS (테스트용 비활성화)
ALTER TABLE public.likes DISABLE ROW LEVEL SECURITY;
```

---

## 3. follows 테이블 (작가 팔로우)

사용자가 팔로우한 작가를 저장합니다. `artist_name`(닉네임)으로 작가를 식별합니다.

```sql
-- follows 테이블 생성
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,         -- 팔로우하는 사용자 ID
  artist_name TEXT NOT NULL,     -- 작가 닉네임 (artist_profiles.nickname)
  artist_image_url TEXT,         -- 작가 프로필 이미지 (표시용 캐시)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, artist_name)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_follows_user_id ON public.follows(user_id);
CREATE INDEX IF NOT EXISTS idx_follows_artist_name ON public.follows(artist_name);

-- RLS (테스트용 비활성화)
ALTER TABLE public.follows DISABLE ROW LEVEL SECURITY;
```

---

## 4. profile-images Storage 버킷 (유저 프로필 이미지)

일반 유저 프로필 이미지를 저장하는 Storage 버킷입니다.

1. Supabase 대시보드 → **Storage** → **New bucket**
2. 이름: `profile-images`
3. Public bucket: **체크** (프로필 이미지 공개)
4. 생성 후 **Create** 클릭

RLS 정책 (선택):
- 모든 사용자 읽기 허용
- 인증된 사용자만 업로드 허용

---

## 5. 한 번에 실행할 SQL

```sql
-- user_profiles
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT UNIQUE NOT NULL,
  profile_image_url TEXT,
  nickname TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL DEFAULT 'user',
  email TEXT,
  login_provider TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- 기존 테이블에 컬럼 추가 (이미 user_profiles가 있는 경우)
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'user';
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS login_provider TEXT;

-- likes
CREATE TABLE IF NOT EXISTS public.likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,
  artwork_id UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, artwork_id)
);
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON public.likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_artwork_id ON public.likes(artwork_id);
ALTER TABLE public.likes DISABLE ROW LEVEL SECURITY;

-- follows
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,
  artist_name TEXT NOT NULL,
  artist_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, artist_name)
);
CREATE INDEX IF NOT EXISTS idx_follows_user_id ON public.follows(user_id);
CREATE INDEX IF NOT EXISTS idx_follows_artist_name ON public.follows(artist_name);
ALTER TABLE public.follows DISABLE ROW LEVEL SECURITY;
```

---

## 6. 전체 요약 (빠른 설정)

| 항목 | 상태 |
|------|------|
| user_profiles 테이블 | 로컬 → 서버 연동 완료 |
| likes 테이블 | 로컬 → 서버 연동 완료 |
| follows 테이블 | 로컬 → 서버 연동 완료 |
| profile-images 버킷 | UserProfileEditView에서 프로필 이미지 업로드 시 사용 |

---

## 7. 체크리스트

- [ ] user_profiles 테이블 생성 (위 SQL 실행)
- [ ] likes 테이블 생성 (위 SQL 실행)
- [ ] follows 테이블 생성 (위 SQL 실행)
- [ ] profile-images Storage 버킷 생성 (Public)
- [ ] 앱 빌드 및 테스트
