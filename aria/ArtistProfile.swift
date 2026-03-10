//
//  ArtistProfile.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import Foundation
import UIKit

// 작가 프로필 정보 모델
struct ArtistProfile: Codable {
    var profileImageUrl: String?  // 프로필 이미지 (로컬 파일 경로 또는 URL)
    var nickname: String  // 닉네임 (필수)
    var features: [String]  // 특징 (최대 3개, 필수 최소 1개)
    var description: String  // 소개 문구
    var instagramLink: String?  // 인스타그램 링크
    var youtubeLink: String?  // 유튜브 링크
    var kakaoLink: String?  // 카카오톡 오픈프로필 링크
    var emailLink: String?  // 이메일 링크
    
    init() {
        self.nickname = ""
        self.features = []
        self.description = ""
        self.profileImageUrl = nil
        self.instagramLink = nil
        self.youtubeLink = nil
        self.kakaoLink = nil
        self.emailLink = nil
    }
    
    // 서버 데이터로부터 초기화 (서버 연동용)
    init(profileImageUrl: String?, nickname: String, features: [String], description: String, instagramLink: String?, youtubeLink: String?, kakaoLink: String?, emailLink: String?) {
        self.profileImageUrl = profileImageUrl
        self.nickname = nickname
        self.features = features
        self.description = description
        self.instagramLink = instagramLink
        self.youtubeLink = youtubeLink
        self.kakaoLink = kakaoLink
        self.emailLink = emailLink
    }
}

// 작가 프로필 저장소
class ArtistProfileStore: ObservableObject {
    static let shared = ArtistProfileStore()
    
    @Published var profile: ArtistProfile = ArtistProfile()
    
    private let profileKey = "ArtistProfile"
    
    private init() {
        // 저장된 프로필이 있으면 먼저 로드 (수정 화면 진입 시 빈 폼 방지)
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(ArtistProfile.self, from: data) {
            profile = decoded
        } else {
            profile = ArtistProfile()
        }
        
        // 로그인 상태면 서버에서 최신 프로필 가져오기
        Task {
            await fetchProfileFromServer()
        }
    }
    
    // 서버에서 프로필 가져오기 (현재 로그인한 작가)
    @MainActor
    func fetchProfileFromServer() async {
        let apiClient = APIClient.shared
        let authManager = AuthenticationManager.shared
        
        guard let userId = authManager.userId else {
            return
        }
        
        do {
            // user_id 타입(UUID/TEXT)에 상관없이 항상 artist_profiles를 user_id 기준으로 조회
            let encodedUserId = URLEncodingHelper.encodeForQuery(userId)
            let endpoint = "/rest/v1/artist_profiles?user_id=eq.\(encodedUserId)"
            let serverProfiles: [ServerArtistProfile] = try await apiClient.request(
                endpoint: endpoint,
                method: "GET",
                body: nil as [String: Any]?
            )
            if let serverProfile = serverProfiles.first {
                let keepLocalImage = self.profile.profileImageUrl?.hasPrefix("/") == true ? self.profile.profileImageUrl : nil
                self.profile = serverProfile.toArtistProfile()
                if let keep = keepLocalImage { self.profile.profileImageUrl = keep }
                self.saveToUserDefaults()
                AppLogger.debug("✅ 서버에서 프로필 로드 성공: \(serverProfile.nickname)")
                return
            }
            
            // artist_profiles에 행이 없고, 앱에서 role은 artist인 경우 user_profiles 값으로 보강
            if authManager.userRole == .artist {
                // 기존에 있는 값(방금 저장한 이미지 등)은 덮어쓰지 않음.
                let userProfile = UserProfileStore.shared.profile
                if self.profile.nickname.isEmpty { self.profile.nickname = userProfile.nickname }
                if self.profile.profileImageUrl == nil || self.profile.profileImageUrl?.isEmpty == true {
                    self.profile.profileImageUrl = userProfile.profileImageUrl
                }
                saveToUserDefaults()
                AppLogger.debug("✅ artist_profiles 미조회 → user_profiles로 보강(기존 값 유지)")
            }
        } catch {
            AppLogger.debug("⚠️ 서버에서 프로필 로드 실패: \(error)")
        }
    }
    
    // 서버에서 작가 이름으로 프로필 가져오기 (다른 작가의 프로필 조회용)
    @MainActor
    func fetchProfileByNickname(_ nickname: String) async -> ArtistProfile? {
        let apiClient = APIClient.shared
        
        guard !nickname.isEmpty, nickname != "current_artist" else {
            return nil  // 플레이스홀더는 서버 쿼리하지 않음
        }
        
        do {
            let encodedNickname = URLEncodingHelper.encodeForQuery(nickname)
            let endpoint = "/rest/v1/artist_profiles?nickname=eq.\(encodedNickname)"
            let serverProfiles: [ServerArtistProfile] = try await apiClient.request(
                endpoint: endpoint,
                method: "GET",
                body: nil as [String: Any]?
            )
            
            if let serverProfile = serverProfiles.first {
                return serverProfile.toArtistProfile()
            }
        } catch {
            AppLogger.debug("⚠️ 서버에서 작가 프로필 로드 실패 (nickname: \(nickname)): \(error)")
        }
        
        return nil
    }
    
    // 서버에서 모든 작가 프로필 목록 가져오기 (Supabase에 등록된 작가만)
    @MainActor
    func fetchAllArtistsFromServer() async -> [String] {
        let apiClient = APIClient.shared
        
        do {
            let endpoint = "/rest/v1/artist_profiles?select=nickname"
            let serverProfiles: [ServerArtistProfile] = try await apiClient.request(
                endpoint: endpoint,
                method: "GET",
                body: nil as [String: Any]?
            )
            
            let artistNames = serverProfiles.map { $0.nickname }.filter { !$0.isEmpty }
            AppLogger.debug("✅ 서버에서 작가 목록 가져오기 성공: \(artistNames.count)명")
            return artistNames
        } catch {
            AppLogger.debug("⚠️ 서버에서 작가 목록 가져오기 실패: \(error)")
            return []
        }
    }
    
    // 프로필 저장
    func saveProfile(_ profile: ArtistProfile) {
        self.profile = profile
        saveToUserDefaults()
    }
    
    // 프로필 업데이트
    func updateProfile(
        profileImageUrl: String? = nil,
        nickname: String? = nil,
        features: [String]? = nil,
        description: String? = nil,
        instagramLink: String? = nil,
        youtubeLink: String? = nil,
        kakaoLink: String? = nil,
        emailLink: String? = nil
    ) {
        if let profileImageUrl = profileImageUrl {
            self.profile.profileImageUrl = profileImageUrl
        }
        if let nickname = nickname {
            self.profile.nickname = nickname
        }
        if let features = features {
            self.profile.features = features
        }
        if let description = description {
            self.profile.description = description
        }
        if let instagramLink = instagramLink {
            self.profile.instagramLink = instagramLink.isEmpty ? nil : instagramLink
        }
        if let youtubeLink = youtubeLink {
            self.profile.youtubeLink = youtubeLink.isEmpty ? nil : youtubeLink
        }
        if let kakaoLink = kakaoLink {
            self.profile.kakaoLink = kakaoLink.isEmpty ? nil : kakaoLink
        }
        if let emailLink = emailLink {
            self.profile.emailLink = emailLink.isEmpty ? nil : emailLink
        }
        
        // 서버에 저장
        Task {
            await updateProfileToServer(
                profileImageUrl: profileImageUrl,
                nickname: nickname,
                features: features,
                description: description,
                instagramLink: instagramLink,
                youtubeLink: youtubeLink,
                kakaoLink: kakaoLink,
                emailLink: emailLink
            )
            // 저장 후 서버에서 최신 프로필 다시 가져오기
            await fetchProfileFromServer()
        }
        
        // 로컬에도 저장 (오프라인 지원)
        saveToUserDefaults()
    }
    
    // UserDefaults에 저장
    internal func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    // 서버에 프로필 저장/업데이트
    @MainActor
    private func updateProfileToServer(
        profileImageUrl: String?,
        nickname: String?,
        features: [String]?,
        description: String?,
        instagramLink: String?,
        youtubeLink: String?,
        kakaoLink: String?,
        emailLink: String?
    ) async {
        let apiClient = APIClient.shared
        let authManager = AuthenticationManager.shared
        
        guard let userId = authManager.userId else {
            AppLogger.debug("❌ 사용자 ID가 없습니다. 로그인 후 다시 시도해주세요.")
            return
        }
        // Supabase artist_profiles.user_id가 TEXT이어야 카카오/애플 ID 저장 가능 (UUID면 400 → DB에서 컬럼 타입 변경 필요)
        
        // 닉네임이 비어 있으면 user_profiles 값 사용 (artist_profiles에 행 없을 때 첫 저장 시 NOT NULL 대비)
        let rawNickname = nickname ?? profile.nickname
        let effectiveNickname = rawNickname.isEmpty ? UserProfileStore.shared.profile.nickname : rawNickname
        
        // 로컬 파일 경로는 서버로 보내지 않음 (Supabase/다른 기기에서 접근 불가 → 기존 URL 유지)
        let rawImageUrl = profileImageUrl ?? profile.profileImageUrl
        let profileImageUrlForServer: String? = rawImageUrl.flatMap { url in
            url.hasPrefix("/") ? nil : (url.isEmpty ? nil : url)
        }
        
        // 현재 프로필 값 사용 (파라미터가 nil이면 기존 값 유지)
        let request = UpdateArtistProfileRequest(
            userId: userId,
            profileImageUrl: profileImageUrlForServer,
            nickname: effectiveNickname.isEmpty ? "artist" : effectiveNickname,
            features: features ?? profile.features,
            description: description ?? profile.description,
            instagramLink: instagramLink ?? profile.instagramLink,
            youtubeLink: youtubeLink ?? profile.youtubeLink,
            kakaoLink: kakaoLink ?? profile.kakaoLink,
            emailLink: emailLink ?? profile.emailLink
        )
        
        do {
            var requestBody = try request.toDictionary()
            // 사진을 안 넣었을 때는 서버에 null로 보내서 컬럼을 비움 (랜덤 이미지 방지)
            if profileImageUrlForServer == nil {
                requestBody["profile_image_url"] = NSNull()
            }
            
            // 디버깅: requestBody 확인
            AppLogger.debug("📤 프로필 저장 요청:")
            AppLogger.debug("   userId: \(userId)")
            AppLogger.debug("   requestBody: \(requestBody)")
            
            // Supabase REST API: UPSERT를 위해 user_id로 찾아서 업데이트 (user_id는 URL 인코딩)
            let encodedUserId = URLEncodingHelper.encodeForQuery(userId)
            let endpoint = "/rest/v1/artist_profiles?user_id=eq.\(encodedUserId)"
            
            AppLogger.debug("   Endpoint: \(endpoint)")
            
            // 먼저 PATCH로 업데이트 시도 (기존 프로필이 있으면 업데이트)
            do {
                let serverProfiles: [ServerArtistProfile] = try await apiClient.request(
                    endpoint: endpoint,
                    method: "PATCH",
                    body: requestBody
                )
                
                if let serverProfile = serverProfiles.first {
                    await MainActor.run {
                        self.profile = serverProfile.toArtistProfile()
                        self.saveToUserDefaults()
                        AppLogger.debug("✅ 서버에 프로필 업데이트 성공: \(serverProfile.nickname)")
                    }
                    return
                } else {
                    AppLogger.debug("⚠️ PATCH 성공했지만 반환된 프로필이 없음, POST로 새로 생성 시도")
                }
            } catch {
                AppLogger.debug("⚠️ PATCH 실패, POST로 새로 생성 시도: \(error)")
            }
            
            // PATCH 실패 시 POST로 새로 생성
            let createEndpoint = "/rest/v1/artist_profiles"
            AppLogger.debug("📤 POST로 새 프로필 생성 시도: \(createEndpoint)")
            let createdProfiles: [ServerArtistProfile] = try await apiClient.request(
                endpoint: createEndpoint,
                method: "POST",
                body: requestBody
            )
            
            if let serverProfile = createdProfiles.first {
                await MainActor.run {
                    self.profile = serverProfile.toArtistProfile()
                    self.saveToUserDefaults()
                    AppLogger.debug("✅ 서버에 프로필 생성 성공: \(serverProfile.nickname)")
                }
            } else {
                AppLogger.debug("⚠️ POST 성공했지만 반환된 프로필이 없음")
            }
        } catch {
            AppLogger.debug("❌ 서버에 프로필 저장 실패: \(error)")
            // 에러가 발생해도 로컬에는 저장되어 있음
        }
    }
    
    
    // 프로필 이미지 저장 (로컬)
    func saveProfileImage(_ image: UIImage) -> String? {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesDirectory = documentsPath.appendingPathComponent("ProfileImages")
        
        do {
            try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            AppLogger.debug("Failed to create profile images directory: \(error)")
            return nil
        }
        
        let fileName = "profile_\(UUID().uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: fileURL)
                return fileURL.path
            } catch {
                AppLogger.debug("Failed to save profile image: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    // 프로필 이미지 삭제
    func deleteProfileImage() {
        if let imageUrl = profile.profileImageUrl, imageUrl.hasPrefix("/") {
            let fileManager = FileManager.default
            try? fileManager.removeItem(atPath: imageUrl)
        }
        profile.profileImageUrl = nil
        saveToUserDefaults()
    }
    
    // 프로필 데이터 초기화
    func clearProfile() {
        profile = ArtistProfile()
        UserDefaults.standard.removeObject(forKey: profileKey)
        // 저장된 프로필 이미지 파일도 삭제
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesDirectory = documentsPath.appendingPathComponent("ProfileImages")
        try? fileManager.removeItem(at: imagesDirectory)
    }
    
    /// 로그아웃 시 호출 (로컬 작가 프로필 캐시 삭제)
    func clearLocal() {
        clearProfile()
    }
}

