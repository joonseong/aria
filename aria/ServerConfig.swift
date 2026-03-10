//
//  ServerConfig.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import Foundation

/// 서버 연동 설정
/// 서버 URL을 설정하여 Supabase와 연동합니다.
class ServerConfig {
    static let shared = ServerConfig()
    
    /// 서버 URL (Supabase 프로젝트 URL)
    var serverURL: String {
        get {
            return UserDefaults.standard.string(forKey: "ServerURL") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ServerURL")
            APIConfig.baseURL = newValue
        }
    }
    
    private init() {
        // 저장된 서버 URL이 있으면 APIClient에 적용
        if !serverURL.isEmpty {
            APIConfig.baseURL = serverURL
        }
    }
    
    /// 서버 URL 설정
    func configure(url: String) {
        serverURL = url
        AppLogger.debug("✅ 서버 URL 설정: \(url)")
    }
}

