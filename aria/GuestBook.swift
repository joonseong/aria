//
//  GuestBook.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import Foundation

// 방명록 글 모델
struct GuestBookEntry: Identifiable, Codable {
    let id: UUID
    let artistName: String  // 방명록을 받는 작가 이름
    let authorName: String  // 글 작성자 이름
    let authorImageUrl: String?  // 글 작성자 프로필 이미지
    let content: String  // 글 내용
    let createdAt: Date  // 작성 시간
    let isArtist: Bool  // 작가가 쓴 글인지 여부
    
    init(artistName: String, authorName: String, authorImageUrl: String?, content: String, isArtist: Bool = false) {
        self.id = UUID()
        self.artistName = artistName
        self.authorName = authorName
        self.authorImageUrl = authorImageUrl
        self.content = content
        self.createdAt = Date()
        self.isArtist = isArtist
    }
    
    // 서버 데이터로부터 초기화 (서버 연동용)
    init(id: UUID, artistName: String, authorName: String, authorImageUrl: String?, content: String, createdAt: Date, isArtist: Bool) {
        self.id = id
        self.artistName = artistName
        self.authorName = authorName
        self.authorImageUrl = authorImageUrl
        self.content = content
        self.createdAt = createdAt
        self.isArtist = isArtist
    }
}

// 방명록 저장소 (서버 연동)
class GuestBookStore: ObservableObject {
    static let shared = GuestBookStore()
    @Published var entries: [GuestBookEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    private init() {
        // 서버 모드이므로 로컬 데이터 로드하지 않음
    }
    
    // 서버에서 방명록 가져오기 (작가 이름으로)
    @MainActor
    func fetchEntriesForArtist(_ artistName: String) async {
        isLoading = true
        errorMessage = nil
        
        // 작가 이름으로 artistId 존재 여부 확인
        guard await ArtistProfileStore.shared.fetchProfileByNickname(artistName) != nil else {
            isLoading = false
            errorMessage = "작가를 찾을 수 없습니다."
            return
        }
        
        // artistId는 nickname을 사용 (서버에서 nickname으로 조회)
        do {
            // Supabase REST API 형식으로 방명록 가져오기
            // artist_id는 실제로는 user_id이거나 nickname일 수 있음
            // Supabase 테이블 구조에 맞게 조정 필요
            let endpoint = "/rest/v1/guestbook?artist_name=eq.\(artistName)"
            let serverEntries: [ServerGuestBookEntry] = try await apiClient.request(
                endpoint: endpoint,
                method: "GET",
                body: nil as [String: Any]?
            )
            
            // 서버 데이터를 로컬 모델로 변환
            var convertedEntries: [GuestBookEntry] = []
            for serverEntry in serverEntries {
                if let entry = serverEntry.toGuestBookEntry() {
                    convertedEntries.append(entry)
                }
            }
            
            // 해당 작가의 방명록만 필터링
            entries = convertedEntries.filter { $0.artistName == artistName }
                .sorted { $0.createdAt > $1.createdAt }  // 최신순 정렬
            
            AppLogger.debug("✅ 서버에서 방명록 가져오기 성공: \(entries.count)개")
        } catch {
            errorMessage = "방명록을 가져오는데 실패했습니다: \(error.localizedDescription)"
            AppLogger.debug("❌ 방명록 가져오기 실패: \(error)")
            entries = []
        }
        
        isLoading = false
    }
    
    // 서버에 방명록 추가
    @MainActor
    func addEntry(_ entry: GuestBookEntry) async {
        isLoading = true
        errorMessage = nil
        
        // 작가 이름으로 artist 존재 여부 확인
        guard await ArtistProfileStore.shared.fetchProfileByNickname(entry.artistName) != nil else {
            isLoading = false
            errorMessage = "작가를 찾을 수 없습니다."
            return
        }
        
        do {
            let authManager = AuthenticationManager.shared
            let userProfileStore = UserProfileStore.shared
            let artistProfileStore = ArtistProfileStore.shared
            
            // 현재 사용자 정보 가져오기
            let userName: String
            let userImageUrl: String?
            let isArtist: Bool
            
            if authManager.userRole == .artist {
                userName = artistProfileStore.profile.nickname.isEmpty ? "작가" : artistProfileStore.profile.nickname
                userImageUrl = artistProfileStore.profile.profileImageUrl
                isArtist = true
            } else {
                userName = userProfileStore.profile.nickname.isEmpty ? "유저" : userProfileStore.profile.nickname
                userImageUrl = userProfileStore.profile.profileImageUrl
                isArtist = false
            }
            
            // 요청 본문 생성
            var requestBody: [String: Any] = [
                "artist_name": entry.artistName,
                "user_name": userName,
                "content": entry.content,
                "is_artist": isArtist
            ]
            
            if let userImageUrl = userImageUrl, !userImageUrl.isEmpty {
                requestBody["user_image_url"] = userImageUrl
            }
            
            // guestbook.user_id 컬럼이 UUID 타입이므로, 카카오/애플 숫자 ID("4732326643" 등)는 제외하고 UUID일 때만 전송
            if let userId = authManager.userId, UUID(uuidString: userId) != nil {
                requestBody["user_id"] = userId
            }
            
            // Supabase REST API 형식으로 방명록 추가
            let endpoint = "/rest/v1/guestbook"
            let serverEntries: [ServerGuestBookEntry] = try await apiClient.request(
                endpoint: endpoint,
                method: "POST",
                body: requestBody
            )
            
            guard let serverEntry = serverEntries.first,
                  let convertedEntry = serverEntry.toGuestBookEntry() else {
                throw NSError(domain: "GuestBookStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "서버 응답 변환 실패"])
            }
            
            // 로컬에 추가 (즉시 UI 반영)
            entries.insert(convertedEntry, at: 0)
            
            AppLogger.debug("✅ 서버에 방명록 추가 성공: \(entry.content)")
        } catch {
            errorMessage = "방명록 추가 실패: \(error.localizedDescription)"
            AppLogger.debug("❌ 방명록 추가 실패: \(error)")
        }
        
        isLoading = false
    }
    
    // 서버에서 방명록 삭제
    @MainActor
    func deleteEntry(_ entry: GuestBookEntry) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Supabase REST API 형식으로 방명록 삭제
            let endpoint = "/rest/v1/guestbook?id=eq.\(entry.id.uuidString)"
            let _: EmptyResponse = try await apiClient.request(
                endpoint: endpoint,
                method: "DELETE"
            )
            
            // 로컬에서도 삭제
            entries.removeAll { $0.id == entry.id }
            
            AppLogger.debug("✅ 서버에서 방명록 삭제 성공")
        } catch {
            errorMessage = "방명록 삭제 실패: \(error.localizedDescription)"
            AppLogger.debug("❌ 방명록 삭제 실패: \(error)")
        }
        
        isLoading = false
    }
    
    // 작가별 방명록 가져오기 (로컬 캐시에서)
    func getEntriesForArtist(_ artistName: String) -> [GuestBookEntry] {
        return entries.filter { $0.artistName == artistName }
            .sorted { $0.createdAt > $1.createdAt }  // 최신순 정렬
    }
    
    func clearAllEntries() {
        entries = []
        // 로컬 데이터 삭제는 더 이상 필요 없음
    }
}

// 시간 포맷팅 유틸리티
extension Date {
    func timeAgoString() -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(self)
        
        if timeInterval < 60 {
            // 1분 미만
            return "방금"
        } else if timeInterval < 3600 {
            // 1시간 미만
            let minutes = Int(timeInterval / 60)
            return "\(minutes)분 전"
        } else if timeInterval < 86400 {
            // 하루 미만
            let hours = Int(timeInterval / 3600)
            return "\(hours)시간 전"
        } else if timeInterval < 172800 {
            // 2일 미만 (어제)
            return "어제"
        } else {
            // 2일 이상
            let formatter = DateFormatter()
            formatter.dateFormat = "YYYY.MM.dd"
            return formatter.string(from: self)
        }
    }
}

