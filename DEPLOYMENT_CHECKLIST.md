# aira 앱 배포 체크리스트

실제 스토어 제출 전 확인 사항입니다.

## ✅ 완료된 항목 (배포 직전 상태)

- **디버그 로그**: Release 빌드에서는 `AppLogger.debug()` 로그가 출력되지 않음
- **API/서버 로그**: URL·에러 상세는 Debug 빌드에서만 출력, API Key는 로그에 포함되지 않음
- **Info.plist**: 사진 라이브러리 사용 목적 설명(`NSPhotoLibraryUsageDescription`) 추가
- **Release 빌드**: `DEBUG` 미정의로 디버그 전용 코드 제외

## 제출 전 확인

1. **Xcode**
   - 스킴: **Any iOS Device** 또는 실제 기기 선택
   - **Product → Archive** 로 Archive 생성
   - **Distribute App** → App Store Connect 업로드

2. **App Store Connect**
   - 앱 정보, 스크린샷, 개인정보 처리방침 URL 등 필수 메타데이터 입력
   - 카카오/애플 로그인 사용 시: 앱 개인정보 처리방침에 로그인 제공자 명시

3. **키/설정** (현재 `airaApp.swift`에 하드코딩된 값)
   - **카카오 앱 키**: 프로덕션 네이티브 앱 키 사용 중인지 확인
   - **Supabase URL/Anon Key**: 프로덕션 프로젝트 URL·anon key 사용 중인지 확인  
   - (선택) 나중에 `.xcconfig` + Info.plist로 분리하면 환경별 전환 용이

4. **보안 권장 (선택)**
   - `APIClient`의 토큰 저장을 UserDefaults → Keychain 이전 권장 (코드 내 TODO 참고)

## 빌드 확인

```bash
# Release 빌드 테스트 (터미널)
xcodebuild -scheme aira -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' build
```

이 체크리스트와 현재 코드 상태로 **실제 배포 직전**까지 반영되어 있습니다.
