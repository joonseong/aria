//
//  HomeEmptyViews.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI

// Home - User Empty View
struct HomeUserEmptyView: View {
    let isLoggedIn: Bool  // 로그인 여부를 파라미터로 받음
    var onLoginTap: (() -> Void)? = nil  // 로그인 버튼 탭 시 콜백
    
    init(isLoggedIn: Bool = false, onLoginTap: (() -> Void)? = nil) {
        self.isLoggedIn = isLoggedIn
        self.onLoginTap = onLoginTap
    }
    
    var body: some View {
        // Header는 상위 뷰(HomeLoginView/HomeLogoutView)에서 이미 표시되므로 여기서는 제거
        ZStack {
            Color.shapeDepth2
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Empty Content
                VStack(spacing: 4) {
                    Text("아직 등록된 작가가 없어요.")
                        .font(Typography.Heading2.font)
                        .foregroundColor(Color(hex: "1B1A1A"))
                    
                    Text("곧 멋진 작가들을 준비할게요.")
                        .font(Typography.Body2.font)
                        .foregroundColor(.foregroundSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .multilineTextAlignment(.center)
                
                // Submit Button
                Button(action: {
                    // 외부 링크로 이동 (일단 빈 링크 - TODO: 실제 링크로 교체)
                    // TODO: 실제 작가 추천 링크로 교체
                }) {
                    Text("작가 추천하기")
                        .font(Typography.Body1.font)
                        .foregroundColor(.foregroundInvertPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.shapePrimary)
                        .cornerRadius(100)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
    }
}

#Preview("User Empty") {
    HomeUserEmptyView()
}

