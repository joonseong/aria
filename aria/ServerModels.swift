//
//  ServerModels.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import Foundation

// MARK: - Server Response Models

// 서버에서 받는 작품 데이터 모델
struct ServerArtwork: Codable {
    let id: String  // 서버에서 받는 ID (UUID 문자열)
    let imageUrls: [String]
    let title: String
    let description: String?
    let year: String
    let medium: String
    let size: String
    let artistId: String?  // nullable로 변경 (Supabase에서 null일 수 있음)
    let artistName: String?
    let artistImageUrl: String?
    let createdAt: String  // ISO8601 형식
    let likeCount: Int?
    let isLiked: Bool?
    
    // Supabase는 snake_case를 사용하므로 CodingKeys로 매핑
    enum CodingKeys: String, CodingKey {
        case id
        case imageUrls = "image_urls"
        case title
        case description
        case year
        case medium
        case size
        case artistId = "artist_id"
        case artistName = "artist_name"
        case artistImageUrl = "artist_image_url"
        case createdAt = "created_at"
        case likeCount = "like_count"
        case isLiked = "is_liked"
    }
    
    // PostedArtwork로 변환
    func toPostedArtwork() -> PostedArtwork? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        
        let dateFormatter = ISO8601DateFormatter()
        let createdDate = dateFormatter.date(from: createdAt) ?? Date()
        
        return PostedArtwork(
            id: uuid,
            imageUrls: imageUrls,
            title: title,
            description: description ?? "",
            year: year,
            medium: medium,
            size: size,
            artistName: artistName ?? "",
            artistImageUrl: artistImageUrl ?? "",
            createdAt: createdDate
        )
    }
}

// 서버에서 받는 작가 프로필 모델 (select=nickname 등 일부 필드만 올 수 있음, user_id 없을 수 있음)
struct ServerArtistProfile: Codable {
    let userId: String?
    let profileImageUrl: String?
    let nickname: String
    let features: [String]
    let description: String?
    let instagramLink: String?
    let youtubeLink: String?
    let kakaoLink: String?
    let emailLink: String?
    let followCount: Int?
    let isFollowing: Bool?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case profileImageUrl = "profile_image_url"
        case nickname
        case features
        case description
        case instagramLink = "instagram_link"
        case youtubeLink = "youtube_link"
        case kakaoLink = "kakao_link"
        case emailLink = "email_link"
        case followCount = "follow_count"
        case isFollowing = "is_following"
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId = try c.decodeIfPresent(String.self, forKey: .userId)
        profileImageUrl = try c.decodeIfPresent(String.self, forKey: .profileImageUrl)
        nickname = (try? c.decode(String.self, forKey: .nickname)) ?? ""
        // Supabase가 features를 TEXT로 저장하면 "[\"a\",\"b\"]" 문자열로 옴 → 배열로 파싱
        if let arr = try? c.decode([String].self, forKey: .features) {
            features = arr
        } else if let str = try? c.decode(String.self, forKey: .features),
                  let data = str.data(using: .utf8),
                  let arr = try? JSONDecoder().decode([String].self, from: data) {
            features = arr
        } else {
            features = []
        }
        description = try c.decodeIfPresent(String.self, forKey: .description)
        instagramLink = try c.decodeIfPresent(String.self, forKey: .instagramLink)
        youtubeLink = try c.decodeIfPresent(String.self, forKey: .youtubeLink)
        kakaoLink = try c.decodeIfPresent(String.self, forKey: .kakaoLink)
        emailLink = try c.decodeIfPresent(String.self, forKey: .emailLink)
        followCount = try c.decodeIfPresent(Int.self, forKey: .followCount)
        isFollowing = try c.decodeIfPresent(Bool.self, forKey: .isFollowing)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(userId, forKey: .userId)
        try c.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try c.encode(nickname, forKey: .nickname)
        try c.encode(features, forKey: .features)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(instagramLink, forKey: .instagramLink)
        try c.encodeIfPresent(youtubeLink, forKey: .youtubeLink)
        try c.encodeIfPresent(kakaoLink, forKey: .kakaoLink)
        try c.encodeIfPresent(emailLink, forKey: .emailLink)
        try c.encodeIfPresent(followCount, forKey: .followCount)
        try c.encodeIfPresent(isFollowing, forKey: .isFollowing)
    }
    
    func toArtistProfile() -> ArtistProfile {
        return ArtistProfile(
            profileImageUrl: profileImageUrl,
            nickname: nickname,
            features: features,
            description: description ?? "",
            instagramLink: instagramLink,
            youtubeLink: youtubeLink,
            kakaoLink: kakaoLink,
            emailLink: emailLink
        )
    }
}

// user_profiles role 조회 응답 (fetchUserRoleFromServer용)
struct UserProfileRoleResponse: Codable {
    let role: String?
}

// 서버에서 받는 일반 유저 프로필 모델 (Supabase user_profiles 테이블)
struct ServerUserProfile: Codable {
    let userId: String
    let profileImageUrl: String?
    let nickname: String
    let role: String?       // "user" | "artist" — 서버에서 적용
    let email: String?     // 로그인 제공자에서 받은 이메일
    let loginProvider: String?  // "kakao" | "apple"
    
    // Supabase는 snake_case를 사용하므로 CodingKeys로 매핑
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case profileImageUrl = "profile_image_url"
        case nickname
        case role
        case email
        case loginProvider = "login_provider"
    }
    
    func toUserProfile() -> UserProfile {
        return UserProfile(
            profileImageUrl: profileImageUrl,
            nickname: nickname
        )
    }
}

// 서버에서 받는 로그인 응답
struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let userId: String
    let userRole: String  // "user" or "artist"
    let expiresIn: Int?  // 토큰 만료 시간 (초)
    
    func toUserRole() -> UserRole {
        return userRole == "artist" ? .artist : .user
    }
}

// 서버에서 받는 방명록 엔트리
struct ServerGuestBookEntry: Codable {
    let id: String
    let artistId: String?
    let artistName: String?  // 작가 이름 (Supabase에서 직접 받을 수 있도록)
    let userId: String?
    let userName: String?
    let userImageUrl: String?
    let content: String
    let createdAt: String  // ISO8601 형식
    let isArtist: Bool?
    
    // Supabase는 snake_case를 사용하므로 CodingKeys로 매핑
    enum CodingKeys: String, CodingKey {
        case id
        case artistId = "artist_id"
        case artistName = "artist_name"
        case userId = "user_id"
        case userName = "user_name"
        case userImageUrl = "user_image_url"
        case content
        case createdAt = "created_at"
        case isArtist = "is_artist"
    }
    
    func toGuestBookEntry() -> GuestBookEntry? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        
        let dateFormatter = ISO8601DateFormatter()
        let createdDate = dateFormatter.date(from: createdAt) ?? Date()
        
        // artistName을 우선 사용, 없으면 artistId 사용
        let finalArtistName = artistName ?? artistId ?? ""
        
        return GuestBookEntry(
            id: uuid,
            artistName: finalArtistName,
            authorName: userName ?? "",
            authorImageUrl: userImageUrl,
            content: content,
            createdAt: createdDate,
            isArtist: isArtist ?? false
        )
    }
}

// 서버에서 받는 좋아요 정보 (likes 테이블)
struct ServerLike: Codable {
    let id: String?
    let userId: String?
    let artworkId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artworkId = "artwork_id"
    }
}

// 서버에서 받는 팔로우 정보 (follows 테이블, 뷰/조인 시 nickname만 올 수 있음)
struct ServerFollow: Codable {
    let id: String?
    let userId: String?
    let artistName: String
    let artistImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case artistName = "artist_name"
        case artistImageUrl = "artist_image_url"
        case nickname  // 조인 결과로 nickname만 올 때 대비
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
        userId = try c.decodeIfPresent(String.self, forKey: .userId)
        let name = try? c.decode(String.self, forKey: .artistName)
        let nick = try? c.decode(String.self, forKey: .nickname)
        artistName = name ?? nick ?? ""
        artistImageUrl = try c.decodeIfPresent(String.self, forKey: .artistImageUrl)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(userId, forKey: .userId)
        try c.encode(artistName, forKey: .artistName)
        try c.encodeIfPresent(artistImageUrl, forKey: .artistImageUrl)
    }
}

// 서버에서 받는 팔로우한 작가 정보
struct ServerFollowedArtist: Codable {
    let artistId: String
    let artistName: String
    let artistImageUrl: String?
    let newArtworkCount: Int?
    
    // Supabase는 snake_case를 사용하므로 CodingKeys로 매핑
    enum CodingKeys: String, CodingKey {
        case artistId = "artist_id"
        case artistName = "artist_name"
        case artistImageUrl = "artist_image_url"
        case newArtworkCount = "new_artwork_count"
    }
    
    func toFollowedArtist() -> FollowedArtist {
        return FollowedArtist(
            artistName: artistName,
            artistImageUrl: artistImageUrl
        )
    }
}

// MARK: - Request Models

// 작품 생성 요청
struct CreateArtworkRequest: Codable {
    let imageUrls: [String]
    let title: String
    let description: String?
    let year: String
    let medium: String
    let size: String
}

// 작품 업데이트 요청
struct UpdateArtworkRequest: Codable {
    let imageUrls: [String]?
    let title: String?
    let description: String?
    let year: String?
    let medium: String?
    let size: String?
}

// 작가 프로필 업데이트 요청
struct UpdateArtistProfileRequest: Codable {
    let userId: String  // user_id 필수
    let profileImageUrl: String?
    let nickname: String
    let features: [String]
    let description: String?
    let instagramLink: String?
    let youtubeLink: String?
    let kakaoLink: String?
    let emailLink: String?
    
    // Supabase는 snake_case를 사용하므로 CodingKeys로 매핑
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case profileImageUrl = "profile_image_url"
        case nickname
        case features
        case description
        case instagramLink = "instagram_link"
        case youtubeLink = "youtube_link"
        case kakaoLink = "kakao_link"
        case emailLink = "email_link"
    }
}

// 일반 유저 프로필 업데이트 요청
struct UpdateUserProfileRequest: Codable {
    let profileImageUrl: String?
    let nickname: String
}

// 방명록 엔트리 생성 요청
struct CreateGuestBookEntryRequest: Codable {
    let content: String
}

// 검색 요청
struct SearchRequest: Codable {
    let query: String
    let limit: Int?
    let offset: Int?
}

// MARK: - Codable Extension for Dictionary Conversion

extension Encodable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "EncodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"])
        }
        return dictionary
    }
}

