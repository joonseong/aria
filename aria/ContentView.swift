//
//  ContentView.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .splash:
                SplashView()
            case .login:
                LoginView()
            case .authenticated:
                HomeLoginView()
            case .guest:
                HomeLogoutView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: authManager.authState) { oldValue, newValue in
            AppLogger.debug("📱 ContentView - AuthState changed: \(oldValue) -> \(newValue)")
            if authManager.isLoggedIn {
                authManager.updateLastAccessDate()
                Task {
                    await UserProfileStore.shared.fetchProfileFromServer()
                    await LikeStore.shared.fetchLikesFromServer()
                    await FollowStore.shared.fetchFollowsFromServer()
                }
            }
        }
        .onAppear {
            AppLogger.debug("📱 ContentView appeared, current authState: \(authManager.authState)")
            if authManager.isLoggedIn {
                authManager.updateLastAccessDate()
                Task {
                    await UserProfileStore.shared.fetchProfileFromServer()
                    await LikeStore.shared.fetchLikesFromServer()
                    await FollowStore.shared.fetchFollowsFromServer()
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // 앱이 다시 활성화될 때(포그라운드 복귀) 서버에서 프로필/role 갱신
            if newPhase == .active, authManager.isLoggedIn {
                Task {
                    await UserProfileStore.shared.fetchProfileFromServer()
                }
            }
        }
    }
}

// 상단 네비게이션 바
struct TopNavigationBar: View {
    let isLoggedIn: Bool
    var onLoginTap: (() -> Void)? = nil
    var onProfileTap: (() -> Void)? = nil  // 프로필 버튼 클릭 시 콜백
    var onSearchTap: (() -> Void)? = nil  // 검색 버튼 클릭 시 콜백
    
    var body: some View {
        HStack {
            // 로고 (icon.logo.brand)
            Image("icon.logo.brand")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 63, height: 28)
            
            Spacer()
            
            // 아이콘들과 로그인 버튼 또는 프로필 아이콘
            HStack(spacing: 16) {
                // Search 아이콘
                Button(action: {
                    onSearchTap?()
                }) {
                    Image("icon.search")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .foregroundColor(.foregroundPrimary)
                }
                
                // 로그인 상태에 따라 프로필 아이콘 또는 로그인 버튼 표시
                if isLoggedIn {
                    // Profile 아이콘 (my 아이콘)
                    Button(action: {
                        onProfileTap?()
                    }) {
                        Image("icon.profile")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .foregroundColor(.foregroundPrimary)
                    }
                } else {
                    // 로그인 버튼
                    Button(action: {
                        onLoginTap?()
                    }) {
                        Text("로그인")
                            .font(Typography.Caption2.font)
                            .foregroundColor(Typography.Caption2.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.foregroundSecondary)
                            .cornerRadius(100)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 56)
        .background(Color.white.opacity(0.01))
    }
}


#Preview {
    ContentView()
}
