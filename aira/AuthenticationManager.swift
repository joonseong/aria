//
//  AuthenticationManager.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import Combine

enum AuthState {
    case splash
    case login
    case authenticated
    case guest
}

enum UserRole {
    case user       // 일반 유저
    case artist     // 작가 (어드민에서 작가로 설정된 유저)
}

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var authState: AuthState = .splash
    @Published var isLoggedIn: Bool = false
    @Published var isGuest: Bool = false
    @Published var userRole: UserRole = .user  // 기본값은 일반 유저
    @Published var userId: String?  // 현재 로그인한 사용자 ID
    
    private init() {
        // 기존에 저장된 userId가 있으면 불러오기
        self.userId = UserDefaults.standard.string(forKey: "CurrentUserId")
        
        // 자동 로그인 확인 (30일 이내 접속 시)
        checkAutoLogin()
    }
    
    // 자동 로그인 확인 (마지막 접속일로부터 30일 이내면 자동 로그인)
    private func checkAutoLogin() {
        guard let userId = UserDefaults.standard.string(forKey: "CurrentUserId"),
              !userId.isEmpty else {
            // userId가 없으면 로그인 상태 아님 (스플래시 이후 Login으로 이동)
            self.isLoggedIn = false
            self.isGuest = false
            return
        }
        
        // 마지막 접속일 확인
        if let lastAccessDate = UserDefaults.standard.object(forKey: "LastAccessDate") as? Date {
            let daysSinceLastAccess = Calendar.current.dateComponents([.day], from: lastAccessDate, to: Date()).day ?? 0
            
            if daysSinceLastAccess <= 30 {
                // 30일 이내면 자동 로그인
                self.userId = userId
                self.isLoggedIn = true
                self.isGuest = false
                
                // 마지막 접속일 업데이트
                updateLastAccessDate()
                
                // 서버에서 role 불러와 적용 (Supabase user_profiles와 동기화)
                Task {
                    let role = await authService.fetchUserRoleFromServer(userId: userId)
                    await MainActor.run { self.userRole = role }
                }
                
                AppLogger.debug("✅ 자동 로그인 성공 (마지막 접속: \(daysSinceLastAccess)일 전)")
            } else {
                // 30일 초과면 로그아웃 처리
                self.userId = nil
                self.isLoggedIn = false
                self.isGuest = false
                UserDefaults.standard.removeObject(forKey: "CurrentUserId")
                UserDefaults.standard.removeObject(forKey: "LastAccessDate")
                AppLogger.debug("⚠️ 자동 로그인 만료 (마지막 접속: \(daysSinceLastAccess)일 전)")
            }
        } else {
            // 마지막 접속일이 없으면 로그인 상태 아님
            self.isLoggedIn = false
            self.isGuest = false
        }
    }
    
    // 마지막 접속일 업데이트 (외부에서도 호출 가능하도록 public)
    func updateLastAccessDate() {
        UserDefaults.standard.set(Date(), forKey: "LastAccessDate")
    }
    
    @Published var isLoading: Bool = false
    @Published var authError: String?
    
    private let authService = AuthService.shared
    
    func loginWithKakao() {
        isLoading = true
        authError = nil
        
        Task {
            let result = await authService.loginWithKakao()
            
            await MainActor.run {
                isLoading = false
                
                if result.success {
                    if let role = result.userRole {
                        self.userRole = role
                    }
                    // 카카오/애플에서 받은 고정 userId 사용 (같은 계정 = 같은 userId)
                    if let userId = result.userId {
                        self.userId = userId
                        UserDefaults.standard.set(userId, forKey: "CurrentUserId")
                    }
                    self.isLoggedIn = true
                    self.isGuest = false
                    self.updateLastAccessDate()  // 마지막 접속일 업데이트
                    self.authState = .authenticated
                    // 서버 프로필/role 동기화 (user_profiles에서 role·email 반영)
                    Task { await UserProfileStore.shared.fetchProfileFromServer() }
                } else {
                    self.authError = result.error?.localizedDescription ?? "로그인에 실패했습니다."
                }
            }
        }
    }
    
    func loginWithApple() {
        isLoading = true
        authError = nil
        
        Task {
            let result = await authService.loginWithApple()
            
            await MainActor.run {
                isLoading = false
                
                if result.success {
                    if let role = result.userRole {
                        self.userRole = role
                    }
                    // 카카오/애플에서 받은 고정 userId 사용 (같은 계정 = 같은 userId)
                    if let userId = result.userId {
                        self.userId = userId
                        UserDefaults.standard.set(userId, forKey: "CurrentUserId")
                    }
                    self.isLoggedIn = true
                    self.isGuest = false
                    self.updateLastAccessDate()  // 마지막 접속일 업데이트
                    self.authState = .authenticated
                    // 서버 프로필/role 동기화 (user_profiles에서 role·email 반영)
                    Task { await UserProfileStore.shared.fetchProfileFromServer() }
                } else {
                    self.authError = result.error?.localizedDescription ?? "로그인에 실패했습니다."
                }
            }
        }
    }
    
    func browseAsGuest() {
        isLoggedIn = false
        isGuest = true
        authState = .guest
        userRole = .user // 게스트는 항상 일반 유저
    }
    
    func logout() {
        Task {
            await authService.logout()
            
            await MainActor.run {
                isLoggedIn = false
                isGuest = false
                authState = .login
                userRole = .user
                userId = nil
                
                // 로그인 관련 로컬 데이터 삭제
                UserDefaults.standard.removeObject(forKey: "CurrentUserId")
                UserDefaults.standard.removeObject(forKey: "LastAccessDate")
                UserDefaults.standard.removeObject(forKey: "LoginProvider")
                UserDefaults.standard.removeObject(forKey: "UserEmail")
                // apple_user_email은 유지 (애플은 재로그인 시 이메일 미제공)
                
                // 모든 앱 로컬 캐시 삭제 — 서버가 단일 소스가 되도록
                UserProfileStore.shared.clearProfile()
                LikeStore.shared.clearLocal()
                FollowStore.shared.clearLocal()
                ArtworkStore.shared.clearAllArtworks()
                ArtistProfileStore.shared.clearLocal()
            }
        }
    }
    
    /// 권한: 작품 업로드 — Artist 역할만 true (Role Hierarchy 규칙)
    func canUpload() -> Bool {
        return userRole == .artist
    }
    
    // 테스트용: 작가 역할로 설정하는 메서드 (추후 서버 연동 시 제거)
    func setArtistRole() {
        userRole = .artist
    }
    
    // 테스트용: 일반 유저 역할로 설정하는 메서드 (추후 서버 연동 시 제거)
    func setUserRole() {
        userRole = .user
    }
}

