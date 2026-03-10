# 🚀 Supabase 연동 가이드 (5분 완성)

## 현재 앱 구조와 완벽 호환! 🎉

현재 앱은 이미 REST API 기반으로 설계되어 있어서, **Supabase URL만 설정하면 바로 사용 가능**합니다!

---

## 📋 단계별 가이드

### 1단계: Supabase 프로젝트 생성 (2분)

1. [supabase.com](https://supabase.com) 접속
2. "Start your project" 클릭
3. GitHub로 로그인 (또는 이메일 가입)
4. "New Project" 클릭
5. 프로젝트 정보 입력:
   - **Name**: aria (원하는 이름)
   - **Database Password**: 강한 비밀번호 입력 (저장해두세요!)
   - **Region**: 가장 가까운 지역 선택
6. "Create new project" 클릭
7. 프로젝트 생성 완료까지 2-3분 대기

### 2단계: API 정보 확인 (1분)

1. Supabase 대시보드에서 **Settings** (왼쪽 하단 톱니바퀴) 클릭
2. **API** 메뉴 클릭
3. 다음 정보 복사:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGc...` (긴 문자열)

### 3단계: 코드에 추가 (1분)

`ariaApp.swift` 파일을 열고:

```swift
@main
struct ariaApp: App {
    init() {
        // 카카오 SDK 초기화
        KakaoSDK.initSDK(appKey: "bdf901ff6a8afbf4913f104591775bd9")
        
        // ⚠️ Supabase 연동 (여기에 URL과 Key 입력!)
        SupabaseClient.shared.configure(
            url: "https://your-project.supabase.co",  // Project URL
            apiKey: "your-anon-key"  // anon public key
        )
        
        // 또는 간단하게 URL만 설정 (기존 방식)
        // ServerConfig.shared.enableServerMode(url: "https://your-project.supabase.co")
    }
    // ...
}
```

### 4단계: 완료! 🎉

이제 앱이 Supabase와 자동으로 연동됩니다!

---

## 📊 Supabase 테이블 구조 예시

Supabase 대시보드에서 다음 테이블들을 생성하세요:

### 1. `artworks` 테이블
```sql
CREATE TABLE artworks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  image_urls TEXT[],
  title TEXT NOT NULL,
  description TEXT,
  year TEXT NOT NULL,
  medium TEXT NOT NULL,
  size TEXT NOT NULL,
  artist_id UUID REFERENCES artist_profiles(id),
  artist_name TEXT,
  artist_image_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 2. `artist_profiles` 테이블
```sql
CREATE TABLE artist_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT UNIQUE NOT NULL,  -- 카카오/애플 로그인 시 숫자/문자 ID 사용 → TEXT 권장 (UUID면 400 발생)
  profile_image_url TEXT,
  nickname TEXT NOT NULL,
  features TEXT[],
  description TEXT,
  instagram_link TEXT,
  youtube_link TEXT,
  kakao_link TEXT,
  email_link TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```
**참고:** 이미 `user_id UUID`로 만들었다면, 카카오/애플 ID와 맞추려면 `ALTER TABLE artist_profiles ALTER COLUMN user_id TYPE TEXT USING user_id::text;` 로 변경하거나, 앱은 그대로 두고 artist 프로필은 user_profiles 폴백만 사용합니다.

### 3. `likes` 테이블
```sql
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  artwork_id UUID REFERENCES artworks(id),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, artwork_id)
);
```

### 4. `follows` 테이블
```sql
CREATE TABLE follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  artist_id UUID REFERENCES artist_profiles(id),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, artist_id)
);
```

---

## 🔧 APIClient에 Supabase 헤더 추가

Supabase는 API Key를 헤더에 포함해야 합니다. `APIClient.swift`를 약간 수정:

```swift
// APIClient.swift의 request 메서드에서
private func request<T: Codable>(...) async throws -> T {
    // ...
    
    // Supabase API Key 추가
    if let supabaseKey = UserDefaults.standard.string(forKey: "SupabaseAPIKey") {
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue(supabaseKey, forHTTPHeaderField: "Authorization")
    }
    
    // ...
}
```

---

## 🎯 다음 단계

1. ✅ Supabase 프로젝트 생성
2. ✅ 테이블 생성 (위 SQL 사용)
3. ✅ API URL과 Key를 코드에 추가
4. ✅ 테스트!

---

## 💡 팁

- **Row Level Security (RLS)**: Supabase는 기본적으로 RLS가 활성화되어 있습니다. 테스트 중에는 비활성화하거나 정책을 설정하세요.
- **실시간 기능**: Supabase는 실시간 구독을 지원합니다. 필요하면 추가 가능합니다.
- **스토리지**: 이미지 업로드는 Supabase Storage를 사용하세요.

---

## 🆘 문제 해결

### "401 Unauthorized" 오류
- API Key가 올바른지 확인
- RLS 정책 확인

### "404 Not Found" 오류
- 테이블 이름이 정확한지 확인
- 엔드포인트 경로 확인 (`/rest/v1/테이블명`)

### "관계 오류"
- Foreign Key 제약조건 확인
- 참조하는 테이블이 존재하는지 확인

---

**Supabase 연동이 완료되면 알려주세요! 추가 도움이 필요하면 언제든 말씀하세요.** 🚀

