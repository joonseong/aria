# TestFlight로 aira 배포하기

TestFlight에 올려서 실제 기기에서 빌드를 확인하는 방법입니다.

## 준비 사항

- **Apple Developer Program** 가입 (연 $99) — [developer.apple.com](https://developer.apple.com)
- Xcode에 **Apple ID 로그인** (Xcode → Settings → Accounts)
- 프로젝트 **Development Team** 설정됨 (현재: `52FHKJ6Y4J`)

---

## 1단계: App Store Connect에 앱 등록

1. [App Store Connect](https://appstoreconnect.apple.com) 접속 후 로그인
2. **나의 앱** → **+** → **새로운 앱**
3. 다음 정보 입력:
   - **플랫폼**: iOS
   - **이름**: aira (또는 원하는 앱 이름)
   - **기본 언어**: 한국어
   - **번들 ID**: `aimers.aira` (Xcode와 동일해야 함)
   - **SKU**: 예: `aira-ios-001` (내부 식별용, 고유하면 됨)
4. **만들기** 클릭

---

## 2단계: Xcode에서 Archive & 업로드

### 2-1. 배포 대상 선택

1. Xcode에서 프로젝트 열기
2. 상단 스킴에서 **aira** 선택
3. 실행 대상(디바이스)을 **Any iOS Device (arm64)** 로 선택  
   (시뮬레이터가 선택되어 있으면 Archive가 비활성화됨)

### 2-2. Archive 생성

1. 메뉴 **Product** → **Archive**
2. 빌드가 끝나면 **Organizer** 창이 열림
3. 방금 만든 Archive가 목록에 보이면 성공

### 2-3. App Store Connect로 업로드

1. Organizer에서 해당 **Archive** 선택 후 **Distribute App** 클릭
2. **App Store Connect** → **Next**
3. **Upload** → **Next**
4. 옵션은 기본값 유지 (Upload your app’s symbols, Manage Version and Build Number 등) → **Next**
5. **Automatically manage signing** 선택된 상태로 **Next**
6. 내용 확인 후 **Upload**
7. 업로드 완료될 때까지 대기 (몇 분 소요될 수 있음)

---

## 3단계: App Store Connect에서 TestFlight 설정

1. [App Store Connect](https://appstoreconnect.apple.com) → **나의 앱** → **aira** 선택
2. 왼쪽 메뉴에서 **TestFlight** 탭 클릭
3. **iOS** 섹션에서:
   - 업로드한 빌드가 **처리 중**으로 보이다가, 10~30분 내 **테스트 가능**으로 바뀜
   - 빌드가 나오면 **빌드 번호** 옆 **+** 또는 **제출 검토** 등으로 해당 빌드를 TestFlight에 포함

### 내부 테스트 (즉시 사용)

- **내부 그룹**에 테스터 추가
- 최대 100명, App Store Connect 사용자(팀 멤버)만 가능
- **승인 대기 없이** 바로 설치 가능

**설정 방법:**

1. TestFlight 탭 → **내부 그룹** (또는 새 그룹 생성)
2. **App Store Connect 사용자 추가** → 팀원 이메일 추가
3. 해당 그룹에 **빌드 추가** (방금 업로드한 빌드 선택)

### 외부 테스트 (선택)

- **외부 그룹** 생성 후 테스터 이메일 추가 (최대 10,000명)
- **첫 외부 빌드**는 Apple의 **베타 앱 검토**가 필요 (보통 24~48시간)
- 검토 통과 후 초대 메일이 테스터에게 발송됨

---

## 4단계: 테스터가 앱 설치

1. 테스터 이메일로 **TestFlight 초대**가 옴 (외부는 검토 후)
2. 초대 메일의 **또는 TestFlight 앱에서 보기** 링크 클릭
3. **TestFlight** 앱(iOS에 설치) 열기
4. **aira** 빌드 선택 → **설치** → 기기에서 앱 실행

---

## 자주 하는 실수

| 문제 | 확인 사항 |
|------|-----------|
| **Archive가 비활성화됨** | 상단 디바이스를 **Any iOS Device**로 선택했는지 확인 |
| **서명 오류** | Xcode → 타깃 aira → **Signing & Capabilities**에서 Team 선택, Bundle ID `aimers.aira` 확인 |
| **업로드 후 빌드가 안 보임** | 10~30분 정도 기다리기. **활동** 탭에서 처리 상태 확인 |
| **같은 빌드 번호로 재업로드 불가** | Xcode에서 **CURRENT_PROJECT_VERSION** (Build) 값을 올린 뒤 다시 Archive |

---

## 빌드 번호 올리는 방법 (재업로드할 때)

매번 새 빌드를 올릴 때마다 **Build 번호**를 올려야 합니다.

1. Xcode에서 **aira** 프로젝트 클릭 → **aira** 타깃 선택
2. **General** 탭 → **Identity** 섹션
3. **Build** 값을 `1` → `2` → `3` … 처럼 증가

또는 `project.pbxproj`에서 `CURRENT_PROJECT_VERSION = 1` 을 `2`, `3` 등으로 수정해도 됩니다.

---

이 순서대로 하면 TestFlight에서 aira 빌드를 보고, 내부/외부 테스터에게 배포할 수 있습니다.
