//
//  SupabaseClient.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//
//  Supabase 연동을 위한 클라이언트
//  기존 APIClient를 Supabase에 맞게 확장
//

import Foundation

/// Supabase 전용 클라이언트
/// 기존 APIClient를 Supabase REST API에 맞게 사용
class SupabaseClient {
    static let shared = SupabaseClient()
    
    private let apiClient = APIClient.shared
    private var supabaseURL: String = ""
    private var supabaseKey: String = ""
    
    private init() {}
    
    /// Supabase 설정
    /// - Parameters:
    ///   - url: Supabase 프로젝트 URL (예: https://xxx.supabase.co)
    ///   - apiKey: Supabase Anon Key (Settings → API → anon public)
    func configure(url: String, apiKey: String) {
        self.supabaseURL = url
        self.supabaseKey = apiKey
        
        // APIClient에 Supabase URL 설정
        ServerConfig.shared.configure(url: url)
        
        // APIClient에 Supabase API Key 설정
        apiClient.setSupabaseAPIKey(apiKey)
        
        AppLogger.debug("✅ Supabase 연동 완료!")
        AppLogger.debug("   URL: \(url)")
        #if DEBUG
        AppLogger.debug("   API Key: \(String(apiKey.prefix(20)))...")
        #endif
    }
    
    /// Supabase REST API 엔드포인트 생성
    func endpoint(_ table: String, action: String = "") -> String {
        let base = "/rest/v1/\(table)"
        return action.isEmpty ? base : "\(base)/\(action)"
    }
}

// MARK: - Supabase API Endpoints

extension APIEndpoint {
    // Supabase는 REST API를 사용하므로 기존 엔드포인트를 Supabase 형식으로 변환
    
    // 작품 (artworks 테이블)
    static func supabaseArtworks() -> String {
        return "/rest/v1/artworks"
    }
    
    static func supabaseArtwork(id: String) -> String {
        return "/rest/v1/artworks?id=eq.\(id)"
    }
    
    static func supabaseArtworksByArtist(artistId: String) -> String {
        return "/rest/v1/artworks?artist_id=eq.\(artistId)"
    }
    
    // 작가 프로필 (artist_profiles 테이블)
    static func supabaseArtistProfile(artistId: String) -> String {
        return "/rest/v1/artist_profiles?id=eq.\(artistId)"
    }
    
    // 좋아요 (likes 테이블)
    static func supabaseLikes(artworkId: String) -> String {
        return "/rest/v1/likes?artwork_id=eq.\(artworkId)"
    }
    
    // 팔로우 (follows 테이블)
    static func supabaseFollows(artistId: String) -> String {
        return "/rest/v1/follows?artist_id=eq.\(artistId)"
    }
}


