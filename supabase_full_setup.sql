-- =============================================================================
-- Aria Supabase 전체 설정 SQL
-- Supabase 대시보드 → SQL Editor에 붙여넣고 한 번에 실행하세요.
-- (이미 있는 테이블/정책은 IF NOT EXISTS / DROP IF EXISTS로 재실행해도 안전합니다.)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. artist_profiles (작가 프로필)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.artist_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT UNIQUE NOT NULL,
  profile_image_url TEXT,
  nickname TEXT NOT NULL,
  features TEXT[] DEFAULT '{}',
  description TEXT,
  instagram_link TEXT,
  youtube_link TEXT,
  kakao_link TEXT,
  email_link TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.artist_profiles DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- 2. user_profiles (일반 유저 프로필, 카카오/애플 로그인)
-- -----------------------------------------------------------------------------
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
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'user';
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS login_provider TEXT;
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- 3. artworks (작품)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.artworks (
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
ALTER TABLE public.artworks DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- 4. likes (작품 좋아요)
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 5. follows (작가 팔로우)
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 6. guestbook (방명록)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.guestbook (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  artist_name TEXT NOT NULL,
  artist_id UUID,
  user_id UUID,
  user_name TEXT NOT NULL,
  user_image_url TEXT,
  content TEXT NOT NULL,
  is_artist BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_guestbook_artist_name ON public.guestbook(artist_name);
CREATE INDEX IF NOT EXISTS idx_guestbook_created_at ON public.guestbook(created_at DESC);
ALTER TABLE public.guestbook DISABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- 7. Storage RLS (이미지 업로드 허용 — anon)
-- 버킷: artwork-images, profile-images (대시보드에서 버킷 생성 후 실행)
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Allow anon upload artwork-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow anon upload profile-images" ON storage.objects;

CREATE POLICY "Allow anon upload artwork-images"
ON storage.objects FOR INSERT TO anon WITH CHECK (bucket_id = 'artwork-images');

CREATE POLICY "Allow anon upload profile-images"
ON storage.objects FOR INSERT TO anon WITH CHECK (bucket_id = 'profile-images');

-- =============================================================================
-- 끝. Storage 버킷은 대시보드 Storage 메뉴에서 수동 생성하세요.
--   - artwork-images (Public)
--   - profile-images (Public)
-- =============================================================================
