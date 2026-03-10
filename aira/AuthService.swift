//
//  AuthService.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import Foundation
import Combine
import AuthenticationServices
import KakaoSDKAuth
import KakaoSDKUser

// 로그인 결과 모델
struct AuthResult {
    let success: Bool
    let userId: String?
    let userRole: UserRole?
    let error: Error?
    
    static func success(userId: String, userRole: UserRole) -> AuthResult {
        return AuthResult(success: true, userId: userId, userRole: userRole, error: nil)
    }
    
    static func failure(error: Error) -> AuthResult {
        return AuthResult(success: false, userId: nil, userRole: nil, error: error)
    }
}

// 인증 서비스 프로토콜
protocol AuthServiceProtocol {
    func loginWithKakao() async -> AuthResult
    func loginWithApple() async -> AuthResult
    func logout() async
    func deleteAccount() async -> Bool
}

// 실제 인증 서비스 구현
// ⚠️ 카카오 SDK 연동을 위해서는:
// 1. Swift Package Manager로 KakaoSDK 추가
// 2. 아래 주석 처리된 코드의 주석 해제
// 3. airaApp.swift에서 KakaoSDK.initSDK() 호출
class AuthService: NSObject, AuthServiceProtocol, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = AuthService()
    private let apiClient = APIClient.shared
    
    private var appleLoginContinuation: CheckedContinuation<AuthResult, Never>?
    
    private override init() {
        super.init()
    }
    
    // MARK: - 카카오 로그인
    
    /// 카카오 로그인
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
        return await withCheckedContinuation { continuation in
            UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                if let error = error {
                    continuation.resume(returning: .failure(error: error))
                } else if let oauthToken = oauthToken {
                    Task {
                        let result = await self.handleKakaoLoginSuccess(oauthToken: oauthToken)
                        continuation.resume(returning: result)
                    }
                } else {
                    continuation.resume(returning: .failure(error: AuthError.unknown))
                }
            }
        }
    }
    
    private func loginWithKakaoAccount() async -> AuthResult {
        return await withCheckedContinuation { continuation in
            UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                if let error = error {
                    continuation.resume(returning: .failure(error: error))
                } else if let oauthToken = oauthToken {
                    Task {
                        let result = await self.handleKakaoLoginSuccess(oauthToken: oauthToken)
                        continuation.resume(returning: result)
                    }
                } else {
                    continuation.resume(returning: .failure(error: AuthError.unknown))
                }
            }
        }
    }
    
    private func handleKakaoLoginSuccess(oauthToken: OAuthToken) async -> AuthResult {
        return await withCheckedContinuation { continuation in
            UserApi.shared.me { user, error in
                if let error = error {
                    continuation.resume(returning: .failure(error: error))
                } else if let user = user {
                    let userId = "\(user.id ?? 0)"
                    let email = user.kakaoAccount?.email
                    UserDefaults.standard.set("kakao", forKey: "LoginProvider")
                    UserDefaults.standard.set(email ?? "", forKey: "UserEmail")
                    Task {
                        let userRole = await self.fetchUserRoleFromServer(userId: userId)
                        let result = AuthResult.success(userId: userId, userRole: userRole)
                        continuation.resume(returning: result)
                    }
                } else {
                    continuation.resume(returning: .failure(error: AuthError.unknown))
                }
            }
        }
    }
    
    // MARK: - 애플 로그인
    
    /// 애플 로그인
    /// AuthenticationServices 프레임워크 사용 (iOS 13+)
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
            let email = appleIDCredential.email ?? UserDefaults.standard.string(forKey: "apple_user_email")
            
            // 이름 정보 저장 (첫 로그인 시에만 제공됨)
            if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                let name = "\(familyName)\(givenName)"
                UserDefaults.standard.set(name, forKey: "apple_user_name")
            }
            
            // 이메일 저장 (첫 로그인 시에만 제공됨)
            if let email = appleIDCredential.email {
                UserDefaults.standard.set(email, forKey: "apple_user_email")
            }
            
            // 로그인 수단 및 이메일 (user_profiles 저장용)
            UserDefaults.standard.set("apple", forKey: "LoginProvider")
            UserDefaults.standard.set(email ?? "", forKey: "UserEmail")
            
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
            await withCheckedContinuation { continuation in
                UserApi.shared.logout { error in
                    if let error = error {
                        AppLogger.debug("카카오 로그아웃 실패: \(error)")
                    }
                    continuation.resume()
                }
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
            return await withCheckedContinuation { continuation in
                UserApi.shared.unlink { error in
                    if let error = error {
                        AppLogger.debug("카카오 계정 연결 해제 실패: \(error)")
                        continuation.resume(returning: false)
                    } else {
                        continuation.resume(returning: true)
                    }
                }
            }
        }
        
        // 서버에 회원탈퇴 요청
        // let success = await apiClient.deleteAccount()
        // return success
        
        return true
    }
    
    // MARK: - 서버에서 사용자 역할 정보 가져오기
    
    /// 서버(user_profiles)에서 사용자 역할 정보 가져오기 (로그인/자동 로그인 시 role 적용용)
    func fetchUserRoleFromServer(userId: String) async -> UserRole {
        do {
            let encodedUserId = URLEncodingHelper.encodeForQuery(userId)
            let endpoint = "/rest/v1/user_profiles?user_id=eq.\(encodedUserId)&select=role"
            let profiles: [UserProfileRoleResponse] = try await apiClient.request(
                endpoint: endpoint,
                method: "GET",
                body: nil as [String: Any]?
            )
            guard let role = profiles.first?.role else { return .user }
            return role == "artist" ? .artist : .user
        } catch {
            return .user
        }
    }
}

// 인증 에러 타입
enum AuthError: LocalizedError {
    case cancelled
    case networkError
    case invalidResponse
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "로그인이 취소되었습니다."
        case .networkError:
            return "네트워크 오류가 발생했습니다."
        case .invalidResponse:
            return "잘못된 응답입니다."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}

