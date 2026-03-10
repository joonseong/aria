# 카카오 & 애플 로그인 연동 가이드

## 📋 목차
1. [카카오 로그인 연동](#카카오-로그인-연동)
2. [애플 로그인 연동](#애플-로그인-연동)
3. [코드 구현](#코드-구현)
4. [테스트 방법](#테스트-방법)

---

## 카카오 로그인 연동

### 1. 카카오 개발자 콘솔 설정

#### 1.1 앱 등록
1. [카카오 개발자 콘솔](https://developers.kakao.com/) 접속
2. 내 애플리케이션 → 애플리케이션 추가하기
3. 앱 이름, 사업자명 입력 후 저장

#### 1.2 플랫폼 설정
1. 앱 설정 → 플랫폼 → iOS 플랫폼 등록
2. **번들 ID** 입력 (예: `com.yourcompany.aira`)
3. 저장

#### 1.3 카카오 로그인 활성화
1. 제품 설정 → 카카오 로그인 → 활성화 설정: ON
2. Redirect URI 등록:
   - iOS: `{YOUR_BUNDLE_ID}://oauth` (예: `com.yourcompany.aira://oauth`)
   - 저장

#### 1.4 앱 키 확인
- **네이티브 앱 키** 복사 (나중에 사용)

### 2. Xcode 프로젝트 설정

#### 2.1 KakaoSDK 추가

**방법 1: Swift Package Manager (권장)**
1. Xcode에서 프로젝트 열기
2. File → Add Packages...
3. URL 입력: `https://github.com/kakao/kakao-ios-sdk`
4. Version: `2.20.0` 이상 선택
5. Add to Target: `aira` 선택
6. Add Package

**방법 2: CocoaPods**
```ruby
# Podfile에 추가
pod 'KakaoSDK', '~> 2.20.0'
```

#### 2.2 Info.plist 설정

프로젝트의 Info 탭에서 다음 설정 추가:

**URL Types 추가:**
1. Target → Info 탭
2. URL Types → + 버튼
3. URL Schemes: `{YOUR_BUNDLE_ID}` (예: `com.yourcompany.aira`)
4. Identifier: `kakao`

**또는 Info.plist 파일 직접 수정:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>{YOUR_BUNDLE_ID}</string>
        </array>
        <key>CFBundleURLName</key>
        <string>kakao</string>
    </dict>
</array>
```

#### 2.3 AppDelegate 설정

`airaApp.swift` 파일 수정:

```swift
import SwiftUI
import KakaoSDKCommon

@main
struct airaApp: App {
    init() {
        // 카카오 SDK 초기화
        KakaoSDK.initSDK(appKey: "YOUR_NATIVE_APP_KEY")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**중요:** `YOUR_NATIVE_APP_KEY`를 카카오 개발자 콘솔에서 복사한 네이티브 앱 키로 교체하세요.

---

## 애플 로그인 연동

### 1. Apple Developer 설정

#### 1.1 App ID 설정
1. [Apple Developer](https://developer.apple.com/) 접속
2. Certificates, Identifiers & Profiles → Identifiers
3. App IDs 선택 → 앱 ID 선택 또는 생성
4. **Sign In with Apple** 기능 활성화
5. 저장

#### 1.2 Capabilities 설정
1. Xcode에서 프로젝트 열기
2. Target → Signing & Capabilities 탭
3. + Capability 클릭
4. **Sign In with Apple** 추가

### 2. 코드 구현

애플 로그인은 iOS 13+에서 기본 제공되므로 별도 SDK 설치 불필요합니다.

---

## 코드 구현

### 1. AuthService.swift 업데이트

`AuthService.swift` 파일을 다음과 같이 수정:

```swift
import Foundation
import Combine
import KakaoSDKAuth
import KakaoSDKUser
import AuthenticationServices

// ... 기존 AuthResult, AuthServiceProtocol 코드 ...

class AuthService: NSObject, AuthServiceProtocol, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = AuthService()
    
    private var appleLoginContinuation: CheckedContinuation<AuthResult, Never>?
    
    private override init() {
        super.init()
    }
    
    // MARK: - 카카오 로그인
    func loginWithKakao() async -> AuthResult {
        // 카카오톡 앱으로 로그인 시도
        if UserApi.isKakaoTalkLoginAvailable() {
            return await loginWithKakaoTalk()
        } else {
            // 카카오톡 앱이 없으면 카카오계정으로 로그인
            return await loginWithKakaoAccount()
        }
    }
    
    private func loginWithKakaoTalk() async -> AuthResult {
        do {
            let oauthToken = try await UserApi.shared.loginWithKakaoTalk()
            return await handleKakaoLoginSuccess(oauthToken: oauthToken)
        } catch {
            return .failure(error: error)
        }
    }
    
    private func loginWithKakaoAccount() async -> AuthResult {
        do {
            let oauthToken = try await UserApi.shared.loginWithKakaoAccount()
            return await handleKakaoLoginSuccess(oauthToken: oauthToken)
        } catch {
            return .failure(error: error)
        }
    }
    
    private func handleKakaoLoginSuccess(oauthToken: OAuthToken) async -> AuthResult {
        do {
            // 사용자 정보 가져오기
            let user = try await UserApi.shared.me()
            let userId = "\(user.id ?? 0)"
            
            // 서버에 사용자 정보 전송 및 역할 정보 받기
            // TODO: 실제 서버 API 호출로 교체
            let userRole = await fetchUserRoleFromServer(userId: userId)
            
            // 토큰 저장 (선택사항)
            // UserDefaults.standard.set(oauthToken.accessToken, forKey: "kakao_access_token")
            
            return .success(userId: userId, userRole: userRole)
        } catch {
            return .failure(error: error)
        }
    }
    
    // MARK: - 애플 로그인
    func loginWithApple() async -> AuthResult {
        return await withCheckedContinuation { continuation in
            self.appleLoginContinuation = continuation
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userId = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            // 이름 정보 저장 (첫 로그인 시에만 제공됨)
            if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                let name = "\(familyName)\(givenName)"
                UserDefaults.standard.set(name, forKey: "apple_user_name")
            }
            
            // 이메일 저장 (첫 로그인 시에만 제공됨)
            if let email = email {
                UserDefaults.standard.set(email, forKey: "apple_user_email")
            }
            
            Task {
                // 서버에 사용자 정보 전송 및 역할 정보 받기
                let userRole = await fetchUserRoleFromServer(userId: userId)
                let result = AuthResult.success(userId: userId, userRole: userRole)
                appleLoginContinuation?.resume(returning: result)
                appleLoginContinuation = nil
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError: AuthError
        if let asError = error as? ASAuthorizationError {
            switch asError.code {
            case .canceled:
                authError = .cancelled
            default:
                authError = .unknown
            }
        } else {
            authError = .unknown
        }
        
        let result = AuthResult.failure(error: authError)
        appleLoginContinuation?.resume(returning: result)
        appleLoginContinuation = nil
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 현재 활성화된 윈도우 반환
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
    
    // MARK: - 로그아웃
    func logout() async {
        // 카카오 로그아웃
        if AuthApi.hasToken() {
            Task {
                try? await UserApi.shared.logout()
            }
        }
        
        // 애플 로그인은 로컬 토큰만 삭제
        // (애플은 별도 로그아웃 API 없음)
        
        // 서버에 로그아웃 요청 (선택사항)
        // await apiClient.logout()
    }
    
    // MARK: - 회원탈퇴
    func deleteAccount() async -> Bool {
        // 카카오 계정 연결 해제
        if AuthApi.hasToken() {
            do {
                try await UserApi.shared.unlink()
            } catch {
                print("카카오 계정 연결 해제 실패: \(error)")
                return false
            }
        }
        
        // 서버에 회원탈퇴 요청
        // let success = await apiClient.deleteAccount()
        // return success
        
        return true
    }
    
    // MARK: - 서버에서 사용자 역할 정보 가져오기
    private func fetchUserRoleFromServer(userId: String) async -> UserRole {
        // TODO: 실제 서버 API 호출
        // 예시:
        // do {
        //     let response = try await apiClient.getUserRole(userId: userId)
        //     return response.isArtist ? .artist : .user
        // } catch {
        //     return .user // 기본값
        // }
        
        // 현재는 Mock 응답
        return .user
    }
}
```

### 2. airaApp.swift 업데이트

```swift
import SwiftUI
import KakaoSDKCommon

@main
struct airaApp: App {
    init() {
        // 카카오 SDK 초기화
        // ⚠️ 실제 앱 키로 교체 필요!
        KakaoSDK.initSDK(appKey: "YOUR_NATIVE_APP_KEY")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 3. URL Scheme 처리 (카카오 로그인용)

`airaApp.swift`에 URL 처리 추가:

```swift
import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct airaApp: App {
    init() {
        KakaoSDK.initSDK(appKey: "YOUR_NATIVE_APP_KEY")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // 카카오 로그인 콜백 처리
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
```

---

## 테스트 방법

### 카카오 로그인 테스트

1. **시뮬레이터 테스트:**
   - 카카오톡 앱이 설치되지 않은 시뮬레이터에서는 카카오계정 로그인으로 자동 전환됩니다.
   - 웹뷰가 열리며 카카오계정으로 로그인할 수 있습니다.

2. **실기기 테스트:**
   - 카카오톡 앱이 설치된 경우: 카카오톡 앱으로 로그인
   - 카카오톡 앱이 없는 경우: 카카오계정 웹 로그인

### 애플 로그인 테스트

1. **시뮬레이터:**
   - iOS 13+ 시뮬레이터에서 테스트 가능
   - 실제 Apple ID로 로그인 (테스트용 계정 사용 권장)

2. **실기기:**
   - 실제 기기에서 테스트 가능
   - Face ID 또는 Touch ID로 인증

### 디버깅 팁

1. **카카오 로그인 오류:**
   - Info.plist의 URL Scheme 확인
   - 카카오 개발자 콘솔의 Redirect URI 확인
   - 네이티브 앱 키 확인

2. **애플 로그인 오류:**
   - Sign In with Apple Capability 추가 확인
   - Apple Developer에서 App ID 설정 확인
   - 실제 기기에서 테스트 (시뮬레이터 제한 있음)

---

## 주의사항

### 보안
- ⚠️ **절대 앱 키를 코드에 하드코딩하지 마세요!**
- 환경 변수나 설정 파일로 관리하거나, 서버에서 받아오는 방식 권장
- 프로덕션 빌드 시 앱 키 노출 주의

### 서버 연동
- 현재 코드는 Mock 응답을 사용합니다.
- 실제 서버 API와 연동 시 `fetchUserRoleFromServer` 메서드를 구현하세요.
- 사용자 정보를 서버에 저장하고, 역할(artist/user) 정보를 받아와야 합니다.

### 사용자 정보 관리
- 카카오: 사용자 ID, 닉네임, 프로필 이미지 등 제공
- 애플: 사용자 ID만 제공 (이름, 이메일은 첫 로그인 시에만 제공)
- 애플 로그인의 경우, 첫 로그인 시 받은 정보를 로컬에 저장해야 합니다.

---

## 다음 단계

1. ✅ 카카오 SDK 설치 및 초기화
2. ✅ 애플 로그인 Capability 추가
3. ✅ AuthService 코드 업데이트
4. ⏳ 실제 서버 API 연동
5. ⏳ 사용자 정보 저장 및 관리
6. ⏳ 토큰 관리 및 자동 로그인 구현

---

## 참고 자료

- [카카오 iOS SDK 가이드](https://developers.kakao.com/docs/latest/ko/getting-started/sdk-ios)
- [Apple Sign In 가이드](https://developer.apple.com/sign-in-with-apple/)
- [카카오 개발자 콘솔](https://developers.kakao.com/)
- [Apple Developer](https://developer.apple.com/)

