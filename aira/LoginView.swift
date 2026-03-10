//
//  LoginView.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        ZStack {
            // 배경색 - 흰색
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단: 로고와 태그라인
                VStack(spacing: 24) {
                    Spacer()
                    
                    // 로고 (icon.logo.brand) - 빨간색
                    Image("icon.logo.brand")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 213, height: 95)
                    
                    // 태그라인
                    VStack(spacing: 0) {
                        Text("신인 아티스트를 위한")
                            .font(Typography.Body2.font)
                            .foregroundColor(.foregroundSecondary)
                        Text("온라인 갤러리, 아리아")
                            .font(Typography.Body2.font)
                            .foregroundColor(.foregroundSecondary)
                    }
                    .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 중간: 소셜 미디어 로그인 버튼
                HStack(spacing: 16) {
                    // 카카오톡 로그인 버튼
                    Button(action: {
                        authManager.loginWithKakao()
                    }) {
                        ZStack {
                            // 원형 배경
                            Circle()
                                .fill(Color(hex: "FEE500"))
                                .frame(width: 64, height: 64)
                            
                            // 카카오톡 아이콘
                            Image("icon.sns.kakaotalk")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                        }
                    }
                    
                    // 애플 로그인 버튼
                    Button(action: {
                        authManager.loginWithApple()
                    }) {
                        ZStack {
                            // 원형 배경
                            Circle()
                                .fill(Color.black)
                                .frame(width: 64, height: 64)
                            
                            // 애플 아이콘 (Assets에 없으므로 system icon 사용)
                            Image(systemName: "applelogo")
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                .padding(.bottom, 24)
                
                // 하단: 둘러보기 버튼 (Tertiary - 로그인이 메인이므로)
                VStack(spacing: 0) {
                    AiraButton("둘러보기", style: .tertiary) {
                        authManager.browseAsGuest()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager.shared)
}

