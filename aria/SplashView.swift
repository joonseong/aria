//
//  SplashView.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            // 배경색 - shapePrimary (빨간색)
            Color.shapePrimary
                .ignoresSafeArea()
            
            // 중앙 컨테이너
            VStack(spacing: 24) {
                // 로고 (icon.logo.white) - 흰색 배경이므로 흰색 로고 사용
                Image("icon.logo.white")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 213, height: 95)
                
                // 태그라인
                VStack(spacing: 0) {
                    Text("신인 아티스트를 위한")
                        .font(Typography.Body2.font)
                        .foregroundColor(.white)
                    Text("온라인 갤러리, 아리아")
                        .font(Typography.Body2.font)
                        .foregroundColor(.white)
                }
                .multilineTextAlignment(.center)
            }
            .offset(y: -50) // Figma 디자인 기준 중앙에서 약간 위로
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // 3초 후 다음 화면으로 전환 (로그인 상태에 따라 분기)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if authManager.isLoggedIn {
                    authManager.authState = .authenticated
                } else if authManager.isGuest {
                    authManager.authState = .guest
                } else {
                    authManager.authState = .login
                }
            }
        }
    }
}

#Preview {
    SplashView()
}

