//
//  airaApp.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct airaApp: App {
    init() {
        // 카카오 SDK 초기화
        KakaoSDK.initSDK(appKey: "bdf901ff6a8afbf4913f104591775bd9")
        
        // ✅ Supabase 연동 설정
        SupabaseClient.shared.configure(
            url: "https://nagnnsfjvstazpfmvbfw.supabase.co",
            apiKey: "sb_publishable_BRgBtm2-xQDoAJS_hvGoJQ_MXf6QX-C"
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthenticationManager.shared)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // 카카오 로그인 URL 콜백 처리
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
