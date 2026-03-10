//
//  UserProfile.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import Foundation
import UIKit

// 일반 유저 프로필 정보 모델
struct UserProfile: Codable {
    var profileImageUrl: String?  // 프로필 이미지 URL (Supabase Storage)
    var nickname: String  // 닉네임
    
    init() {
        self.nickname = ""
        self.profileImageUrl = nil
    }
    
    // 서버 데이터로부터 초기화 (서버 연동용)
    init(profileImageUrl: String?, nickname: String) {
        self.profileImageUrl = profileImageUrl
        self.nickname = nickname
    }
}

// MARK: - LikeStore (서버 연동)
class LikeStore: ObservableObject {
    static let shared = LikeStore()
    @Published var likedArtworkIds: [UUID] = []
    private let likeKey = "LikedArtworks"
    private let apiClient = APIClient.shared
    
    private init() {
        // 로그인 사용자면 서버에서만 로드 (서버가 단일 소스). 비로그인 시 로컬은 로그아웃 시 이미 비워짐.
        Task { await fetchLikesFromServer() }
    }
    
    func toggleLike(artworkId: UUID) {
        let isCurrentlyLiked = likedArtworkIds.contains(artworkId)
        
        // 낙관적 UI 업데이트
        if isCurrentlyLiked {
            likedArtworkIds.removeAll { $0 == artworkId }
        } else {
            likedArtworkIds.append(artworkId)
        }
        saveLikesToLocal()
        
        Task {
            await toggleLikeOnServer(artworkId: artworkId, add: !isCurrentlyLiked)
        }
    }
    
    func isLiked(artworkId: UUID) -> Bool {
        return likedArtworkIds.contains(artworkId)
    }
    
    func getLikedCount() -> Int {
        return likedArtworkIds.count
    }
    
    @MainActor
    func fetchLikesFromServer() async {
        guard let userId = AuthenticationManager.shared.userId else { return }
        
        do {
            let endpoint = "/rest/v1/likes?user_id=eq.\(userId)&select=artwork_id"
            let serverLikes: [ServerLike] = try await apiClient.request(
                endpoint: endpoint,
                method: "GET",
                body: nil as [String: Any]?
            )
            
            let ids = serverLikes.compactMap { UUID(uuidString: $0.artworkId) }
            likedArtworkIds = ids
            saveLikesToLocal()
            AppLogger.debug("✅ 서버에서 좋아요 목록 로드: \(ids.count)개")
        } catch {
            AppLogger.debug("⚠️ 좋아요 목록 로드 실패: \(error)")
        }
    }
    
    @MainActor
    private func toggleLikeOnServer(artworkId: UUID, add: Bool) async {
        guard let userId = AuthenticationManager.shared.userId else { return }
        
        do {
            if add {
                let endpoint = "/rest/v1/likes"
                let body: [String: Any] = [
                    "user_id": userId,
                    "artwork_id": artworkId.uuidString
                ]
                let _: [ServerLike] = try await apiClient.request(
                    endpoint: endpoint,
                    method: "POST",
                    body: body
                )
                AppLogger.debug("✅ 좋아요 추가 완료: \(artworkId)")
            } else {
                let endpoint = "/rest/v1/likes?user_id=eq.\(userId)&artwork_id=eq.\(artworkId.uuidString)"
                let _: EmptyResponse = try await apiClient.request(
                    endpoint: endpoint,
                    method: "DELETE"
                )
                AppLogger.debug("✅ 좋아요 삭제 완료: \(artworkId)")
            }
        } catch {
            AppLogger.debug("❌ 좋아요 토글 실패: \(error)")
            await fetchLikesFromServer()
        }
    }
    
    private func saveLikesToLocal() {
        if let encoded = try? JSONEncoder().encode(likedArtworkIds) {
            UserDefaults.standard.set(encoded, forKey: likeKey)
        }
    }
    
    private func loadLikesFromLocal() {
        if let data = UserDefaults.standard.data(forKey: likeKey),
           let decoded = try? JSONDecoder().decode([UUID].self, from: data) {
            likedArtworkIds = decoded
        }
    }
    
    /// 로그아웃 시 로컬 좋아요 데이터 삭제 (서버와 연동 정리)
    func clearLocal() {
        likedArtworkIds = []
        UserDefaults.standard.removeObject(forKey: likeKey)
    }
}

// 팔로우한 작가 정보 모델
struct FollowedArtist: Codable, Identifiable {
    let id: UUID
    let artistName: String
    let artistImageUrl: String?
    
    init(artistName: String, artistImageUrl: String?) {
        self.id = UUID()
        self.artistName = artistName
        self.artistImageUrl = artistImageUrl
    }
}

// 작가별 팔로우 카운트 저장소 (작가를 팔로우한 사람 수)
struct ArtistFollowCount: Codable {
    let artistName: String
    var count: Int
}

// MARK: - FollowStore (서버 연동)
class FollowStore: ObservableObject {
    static let shared = FollowStore()
    @Published var followedArtists: [FollowedArtist] = []
    @Published var artistFollowCounts: [String: Int] = [:]
    private let followKey = "FollowedArtists"
    private let followCountKey = "ArtistFollowCounts"
    private let apiClient = APIClient.shared
    
    private init() {
        // 로그인 사용자면 서버에서만 로드 (서버가 단일 소스)
        Task { await fetchFollowsFromServer() }
    }
    
    func toggleFollow(artistName: String, artistImageUrl: String?) {
        let isCurrentlyFollowing = isFollowing(artistName: artistName)
        
        if isCurrentlyFollowing {
            if let index = followedArtists.firstIndex(where: { $0.artistName == artistName }) {
                followedArtists.remove(at: index)
            }
            if let currentCount = artistFollowCounts[artistName], currentCount > 0 {
                artistFollowCounts[artistName] = currentCount - 1
            }
        } else {
            followedArtists.append(FollowedArtist(artistName: artistName, artistImageUrl: artistImageUrl))
            artistFollowCounts[artistName, default: 0] += 1
        }
        saveFollowsToLocal()
        saveFollowCountsToLocal()
        
        Task {
            await toggleFollowOnServer(artistName: artistName, artistImageUrl: artistImageUrl, add: !isCurrentlyFollowing)
        }
    }
    
    func isFollowing(artistName: String) -> Bool {
        return followedArtists.contains(where: { $0.artistName == artistName })
    }
    
    func getFollowCount() -> Int {
        return followedArtists.count
    }
    
    func getFollowCount(for artistName: String) -> Int {
        return artistFollowCounts[artistName] ?? 0
    }
    
    func getFollowedArtistNames() -> [String] {
        return followedArtists.map { $0.artistName }
    }
    
    func getArtistImageUrl(for artistName: String) -> String? {
        return followedArtists.first(where: { $0.artistName == artistName })?.artistImageUrl
    }
    
    // 팔로우하지 않은 작가 제거 (실제 팔로우 상태와 동기화)
    func cleanupUnfollowedArtists() {
        // 현재 팔로우 상태를 확인하여 실제로 팔로우하지 않은 작가 제거
        // 이 메서드는 팔로우 상태가 변경될 때마다 호출되어야 함
        // 하지만 현재는 toggleFollow에서 이미 처리되므로, 여기서는 중복 제거만 수행
        var uniqueArtists: [FollowedArtist] = []
        var seenNames: Set<String> = []
        
        for artist in followedArtists {
            if !seenNames.contains(artist.artistName) {
                uniqueArtists.append(artist)
                seenNames.insert(artist.artistName)
            }
        }
        
        if uniqueArtists.count != followedArtists.count {
            followedArtists = uniqueArtists
            saveFollowsToLocal()
        }
    }
    
    func clearAllFollows() {
        followedArtists = []
        artistFollowCounts = [:]
        UserDefaults.standard.removeObject(forKey: followKey)
        UserDefaults.standard.removeObject(forKey: followCountKey)
    }
    
    /// 로그아웃 시 호출 (로컬 팔로우 데이터 삭제)
    func clearLocal() {
        clearAllFollows()
    }
    
    @MainActor
    func fetchFollowsFromServer() async {
        guard let userId = AuthenticationManager.shared.userId else { return }
        
        do {
            let endpoint = "/rest/v1/follows?user_id=eq.\(userId)&select=user_id,artist_name,artist_image_url"
            let serverFollows: [ServerFollow] = try await apiClient.request(
                endpoint: endpoint,
                method: "GET",
                body: nil as [String: Any]?
            )
            
            followedArtists = serverFollows.map { sf in
                FollowedArtist(artistName: sf.artistName, artistImageUrl: sf.artistImageUrl)
            }
            saveFollowsToLocal()
            
            for artist in followedArtists {
                let count = await fetchFollowCountForArtist(artistName: artist.artistName)
                artistFollowCounts[artist.artistName] = count
            }
            saveFollowCountsToLocal()
            AppLogger.debug("✅ 서버에서 팔로우 목록 로드: \(followedArtists.count)명")
        } catch {
            AppLogger.debug("⚠️ 팔로우 목록 로드 실패: \(error)")
        }
    }
    
    @MainActor
    func fetchFollowCountForArtist(artistName: String) async -> Int {
        do {
            let encodedName = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? artistName
            let endpoint = "/rest/v1/follows?artist_name=eq.\(encodedName)&select=user_id,artist_name,artist_image_url"
            let serverFollows: [ServerFollow] = try await apiClient.request(
                endpoint: endpoint,
                method: "GET",
                body: nil as [String: Any]?
            )
            return serverFollows.count
        } catch {
            return artistFollowCounts[artistName] ?? 0
        }
    }
    
    @MainActor
    private func toggleFollowOnServer(artistName: String, artistImageUrl: String?, add: Bool) async {
        guard let userId = AuthenticationManager.shared.userId else { return }
        
        do {
            if add {
                var body: [String: Any] = [
                    "user_id": userId,
                    "artist_name": artistName
                ]
                if let url = artistImageUrl, !url.isEmpty {
                    body["artist_image_url"] = url
                }
                let endpoint = "/rest/v1/follows"
                let _: [ServerFollow] = try await apiClient.request(
                    endpoint: endpoint,
                    method: "POST",
                    body: body
                )
                let count = await fetchFollowCountForArtist(artistName: artistName)
                await MainActor.run {
                    artistFollowCounts[artistName] = count
                    saveFollowCountsToLocal()
                }
                AppLogger.debug("✅ 팔로우 추가 완료: \(artistName)")
            } else {
                let encodedName = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? artistName
                let endpoint = "/rest/v1/follows?user_id=eq.\(userId)&artist_name=eq.\(encodedName)"
                let _: EmptyResponse = try await apiClient.request(
                    endpoint: endpoint,
                    method: "DELETE"
                )
                let count = await fetchFollowCountForArtist(artistName: artistName)
                await MainActor.run {
                    artistFollowCounts[artistName] = count
                    saveFollowCountsToLocal()
                }
                AppLogger.debug("✅ 팔로우 삭제 완료: \(artistName)")
            }
        } catch {
            AppLogger.debug("❌ 팔로우 토글 실패: \(error)")
            await fetchFollowsFromServer()
        }
    }
    
    private func saveFollowsToLocal() {
        if let encoded = try? JSONEncoder().encode(followedArtists) {
            UserDefaults.standard.set(encoded, forKey: followKey)
        }
    }
    
    private func loadFollowsFromLocal() {
        if let data = UserDefaults.standard.data(forKey: followKey) {
            if let decoded = try? JSONDecoder().decode([FollowedArtist].self, from: data) {
                followedArtists = decoded
            } else if let decoded = try? JSONDecoder().decode([String].self, from: data) {
                followedArtists = decoded.map { FollowedArtist(artistName: $0, artistImageUrl: nil) }
                saveFollowsToLocal()
            }
        }
    }
    
    private func saveFollowCountsToLocal() {
        if let encoded = try? JSONEncoder().encode(artistFollowCounts) {
            UserDefaults.standard.set(encoded, forKey: followCountKey)
        }
    }
    
    private func loadFollowCountsFromLocal() {
        if let data = UserDefaults.standard.data(forKey: followCountKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            artistFollowCounts = decoded
        }
    }
}

// MARK: - UserProfileStore (서버 연동)
class UserProfileStore: ObservableObject {
    static let shared = UserProfileStore()
    @Published var profile: UserProfile = UserProfile()
    
    private let profileKey = "UserProfile"
    private let apiClient = APIClient.shared
    
    private init() {
        profile = UserProfile()
        Task { await fetchProfileFromServer() }
    }
    
    func saveProfile(_ profile: UserProfile) {
        self.profile = profile
        saveToUserDefaults()
    }
    
    func updateProfile(profileImageUrl: String? = nil, nickname: String? = nil) {
        // @Published가 감지하려면 프로필 전체를 새로 할당해야 함 (구조체 속성만 바꾸면 구독자에게 알림 안 감)
        let newImageUrl = profileImageUrl ?? self.profile.profileImageUrl
        let newNickname = nickname ?? self.profile.nickname
        self.profile = UserProfile(profileImageUrl: newImageUrl, nickname: newNickname)
        saveToUserDefaults()
        
        Task {
            await updateProfileToServer(profileImageUrl: profileImageUrl, nickname: nickname)
        }
    }
    
    @MainActor
    func fetchProfileFromServer() async {
        guard let userId = AuthenticationManager.shared.userId else { return }
        
        do {
            let encodedUserId = URLEncodingHelper.encodeForQuery(userId)
            let endpoint = "/rest/v1/user_profiles?user_id=eq.\(encodedUserId)"
            let serverProfiles: [ServerUserProfile] = try await apiClient.request(
                endpoint: endpoint,
                method: "GET",
                body: nil as [String: Any]?
            )
            
            if let serverProfile = serverProfiles.first {
                profile = serverProfile.toUserProfile()
                saveToUserDefaults()
                // 서버에 저장된 role을 앱에 반영 (Supabase user_profiles.role)
                let role: UserRole = (serverProfile.role == "artist") ? .artist : .user
                AuthenticationManager.shared.userRole = role
                AppLogger.debug("✅ 서버에서 유저 프로필 로드: \(profile.nickname), role: \(serverProfile.role ?? "user")")
            } else {
                // 프로필이 없으면 로그인 시 자동 생성 (랜덤 닉네임)
                await createProfileOnLogin(userId: userId)
            }
        } catch {
            AppLogger.debug("⚠️ 유저 프로필 로드 실패: \(error)")
        }
    }
    
    /// 로그인 시 프로필이 없을 때 자동 생성 (랜덤 닉네임, role, email, login_provider)
    @MainActor
    private func createProfileOnLogin(userId: String) async {
        let randomNickname = ArtNicknameGenerator.generate()
        let email = UserDefaults.standard.string(forKey: "UserEmail") ?? ""
        let loginProvider = UserDefaults.standard.string(forKey: "LoginProvider") ?? ""
        
        // Supabase user_profiles에 role, email, login_provider까지 저장 (컬럼명 그대로)
        let requestBody: [String: Any] = [
            "user_id": userId,
            "nickname": randomNickname,
            "role": "user",
            "email": email,
            "login_provider": loginProvider
        ]
        
        do {
            let postEndpoint = "/rest/v1/user_profiles"
            let _: [ServerUserProfile] = try await apiClient.request(
                endpoint: postEndpoint,
                method: "POST",
                body: requestBody
            )
            profile = UserProfile(profileImageUrl: nil, nickname: randomNickname)
            saveToUserDefaults()
            AppLogger.debug("✅ 로그인 시 유저 프로필 자동 생성: \(randomNickname)")
        } catch {
            AppLogger.debug("❌ 유저 프로필 자동 생성 실패: \(error)")
        }
    }
    
    @MainActor
    private func updateProfileToServer(profileImageUrl: String? = nil, nickname: String? = nil) async {
        guard let userId = AuthenticationManager.shared.userId else { return }
        
        let reqNickname = nickname ?? profile.nickname
        let reqImageUrl = profileImageUrl ?? profile.profileImageUrl
        
        var requestBody: [String: Any] = [
            "user_id": userId,
            "nickname": reqNickname
        ]
        if let url = reqImageUrl, !url.isEmpty {
            requestBody["profile_image_url"] = url
        } else {
            requestBody["profile_image_url"] = NSNull()
        }
        
        do {
            let encodedUserId = URLEncodingHelper.encodeForQuery(userId)
            let patchEndpoint = "/rest/v1/user_profiles?user_id=eq.\(encodedUserId)"
            let _: [ServerUserProfile] = try await apiClient.request(
                endpoint: patchEndpoint,
                method: "PATCH",
                body: requestBody
            )
            await fetchProfileFromServer()
            AppLogger.debug("✅ 서버에 유저 프로필 저장 완료")
        } catch {
            do {
                let postEndpoint = "/rest/v1/user_profiles"
                let _: [ServerUserProfile] = try await apiClient.request(
                    endpoint: postEndpoint,
                    method: "POST",
                    body: requestBody
                )
                await fetchProfileFromServer()
                AppLogger.debug("✅ 서버에 유저 프로필 생성 완료")
            } catch {
                AppLogger.debug("❌ 유저 프로필 저장 실패: \(error)")
            }
        }
    }
    
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    func clearProfile() {
        profile = UserProfile()
        UserDefaults.standard.removeObject(forKey: profileKey)
    }
}

