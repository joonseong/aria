//
//  ArtworkStore.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import Foundation
import SwiftUI
import Combine
import UIKit

// 작품 데이터 모델 확장 (작가가 등록한 작품 정보 추가)
struct PostedArtwork: Identifiable, Codable {
    let id: UUID
    var imageUrls: [String]  // 여러 이미지 (최대 10장)
    var title: String
    var description: String
    var year: String
    var medium: String
    var size: String
    let artistName: String
    let artistImageUrl: String
    let createdAt: Date
    
    init(imageUrls: [String], title: String, description: String, year: String, medium: String, size: String, artistName: String, artistImageUrl: String) {
        self.id = UUID()
        self.imageUrls = imageUrls
        self.title = title
        self.description = description
        self.year = year
        self.medium = medium
        self.size = size
        self.artistName = artistName
        self.artistImageUrl = artistImageUrl
        self.createdAt = Date()
    }
    
    // 서버 데이터로부터 초기화 (서버 연동용)
    init(id: UUID, imageUrls: [String], title: String, description: String, year: String, medium: String, size: String, artistName: String, artistImageUrl: String, createdAt: Date) {
        self.id = id
        self.imageUrls = imageUrls
        self.title = title
        self.description = description
        self.year = year
        self.medium = medium
        self.size = size
        self.artistName = artistName
        self.artistImageUrl = artistImageUrl
        self.createdAt = createdAt
    }
}

// 작품 저장소
class ArtworkStore: ObservableObject {
    static let shared = ArtworkStore()
    
    @Published var artworks: [PostedArtwork] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    private init() {
        // 서버에서 데이터 가져오기
        AppLogger.debug("🌐 서버에서 작품 데이터 가져오기")
        Task {
            await fetchArtworksFromServer()
        }
    }
    
    // 작품 추가 (서버에 저장)
    func addArtwork(_ artwork: PostedArtwork) {
        // 먼저 로컬에 임시 저장 (이미지 경로 보존 및 즉시 UI 반영)
        artworks.insert(artwork, at: 0)
        saveArtworks()
        
        // 서버에 저장
        Task {
            await addArtworkToServer(artwork)
        }
    }
    
    // 서버에 작품 추가
    @MainActor
    private func addArtworkToServer(_ artwork: PostedArtwork) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. 이미지를 Supabase Storage에 업로드
            var imageUrls: [String] = []
            
            // 로컬 파일 경로에서 UIImage 로드
            var imagesToUpload: [UIImage] = []
            for imagePath in artwork.imageUrls {
                if imagePath.hasPrefix("/") {
                    if let image = UIImage(contentsOfFile: imagePath) {
                        imagesToUpload.append(image)
                    } else {
                        AppLogger.debug("⚠️ 로컬 이미지 로드 실패: \(imagePath)")
                    }
                } else if imagePath.hasPrefix("http://") || imagePath.hasPrefix("https://") {
                    imageUrls.append(imagePath)
                }
            }
            if !artwork.imageUrls.isEmpty && imagesToUpload.isEmpty && imageUrls.isEmpty {
                AppLogger.debug("⚠️ 업로드할 이미지 없음 (경로 \(artwork.imageUrls.count)개 중 로드/URL 0개)")
            }
            
            // Supabase Storage에 업로드
            if !imagesToUpload.isEmpty {
                do {
                    let uploadedUrls = try await apiClient.uploadImagesToSupabaseStorage(
                        imagesToUpload,
                        bucket: SupabaseStorageBucket.artworkImages
                    )
                    imageUrls.append(contentsOf: uploadedUrls)
                    AppLogger.debug("✅ \(uploadedUrls.count)개 이미지 업로드 완료 → image_urls: \(uploadedUrls)")
                } catch {
                    AppLogger.debug("⚠️ 이미지 업로드 실패 (작품은 image_urls 없이 저장됨)")
                    AppLogger.debug("   localizedDescription: \(error.localizedDescription)")
                    AppLogger.debug("   String(describing:): \(String(describing: error))")
                    // 이미지 업로드 실패해도 작품은 저장 (이미지 없이)
                }
            }
            
            // 작품 생성 요청
            // Supabase는 snake_case를 사용하므로 컬럼명을 맞춰야 함
            var requestBody: [String: Any] = [
                "image_urls": imageUrls.isEmpty ? [] : imageUrls,
                "title": artwork.title,
                "year": artwork.year,
                "medium": artwork.medium,
                "size": artwork.size,
                "artist_name": artwork.artistName,
                "artist_image_url": artwork.artistImageUrl
            ]
            
            // description이 있으면 추가 (nil이 아닌 경우만)
            if !artwork.description.isEmpty {
                requestBody["description"] = artwork.description
            }
            
            // 디버깅: 요청 정보 출력
            let fullURL = "\(APIConfig.baseAPIURL)\(APIEndpoint.createArtwork.path)"
            AppLogger.debug("📤 작품 등록 요청:")
            AppLogger.debug("   Full URL: \(fullURL)")
            AppLogger.debug("   Method: \(APIEndpoint.createArtwork.method)")
            AppLogger.debug("   Base URL: \(APIConfig.baseURL)")
            AppLogger.debug("   Base API URL: \(APIConfig.baseAPIURL)")
            AppLogger.debug("   Endpoint: \(APIEndpoint.createArtwork.path)")
            AppLogger.debug("   Body: \(requestBody)")
            
            // Supabase는 배열을 직접 반환하므로 [ServerArtwork]로 받기
            let serverArtworks: [ServerArtwork] = try await apiClient.request(
                endpoint: APIEndpoint.createArtwork.path,
                method: APIEndpoint.createArtwork.method,
                body: requestBody
            )
            
            guard let serverArtwork = serverArtworks.first else {
                throw APIError.invalidResponse
            }
            
            AppLogger.debug("✅ 서버에 작품 등록 성공: \(serverArtwork.title)")
            
            // 서버에서 받은 데이터는 이미지 URL이 빈 배열일 수 있음
            // 로컬에 저장된 이미지 경로를 유지하기 위해 원본 artwork의 imageUrls 사용
            if var postedArtwork = serverArtwork.toPostedArtwork() {
                // 서버에서 받은 이미지 URL이 비어있으면 원본 artwork의 로컬 경로 사용
                if postedArtwork.imageUrls.isEmpty && !artwork.imageUrls.isEmpty {
                    postedArtwork.imageUrls = artwork.imageUrls
                }
                
                // 기존 작품 찾기: ID로 먼저 찾고, 없으면 title, artistName, year로 찾기
                // (로컬에서 생성한 ID와 서버에서 받은 ID가 다를 수 있음)
                var existingIndex: Int? = artworks.firstIndex(where: { $0.id == postedArtwork.id })
                
                if existingIndex == nil {
                    // ID로 찾지 못했으면 title, artistName, year로 찾기
                    existingIndex = artworks.firstIndex(where: { existingArtwork in
                        existingArtwork.title == postedArtwork.title &&
                        existingArtwork.artistName == postedArtwork.artistName &&
                        existingArtwork.year == postedArtwork.year
                    })
                }
                
                if let index = existingIndex {
                    // 기존 작품이 있으면 업데이트 (이미지 경로는 로컬 것을 우선)
                    if !artwork.imageUrls.isEmpty {
                        postedArtwork.imageUrls = artwork.imageUrls
                    }
                    // 서버에서 받은 ID로 업데이트
                    artworks[index] = postedArtwork
                    AppLogger.debug("✅ 기존 작품 업데이트: \(postedArtwork.title)")
                } else {
                    // 새 작품이면 추가 (이 경우는 거의 없어야 함)
                    artworks.insert(postedArtwork, at: 0)
                    AppLogger.debug("⚠️ 새 작품 추가 (기존 작품을 찾지 못함): \(postedArtwork.title)")
                }
                saveArtworks()
            }
        } catch {
            errorMessage = "작품 추가 실패: \(error.localizedDescription)"
            AppLogger.debug("❌ 작품 추가 실패: \(error)")
        }
        
        isLoading = false
    }
    
    // 서버에서 작품 목록 가져오기
    @MainActor
    func fetchArtworksFromServer() async {
        isLoading = true
        errorMessage = nil
        
        // 먼저 현재 로컬 데이터 백업 (이미지 경로 보존)
        let currentLocalArtworks = artworks
        
        do {
            let serverArtworks: [ServerArtwork] = try await apiClient.request(
                endpoint: APIEndpoint.getArtworks.path,
                method: APIEndpoint.getArtworks.method
            )
            
            AppLogger.debug("✅ 서버에서 작품 목록 가져오기 성공: \(serverArtworks.count)개")
            
            var convertedArtworks = serverArtworks.compactMap { $0.toPostedArtwork() }
            
            // 로컬에 저장된 작품 데이터와 병합하여 이미지 경로 복원
            let localArtworks = loadArtworksFromLocal()
            
            // 서버 데이터와 로컬 데이터를 병합
            let fileManager = FileManager.default
            for (index, serverArtwork) in convertedArtworks.enumerated() {
                // 서버에서 받은 이미지 URL이 비어있고, 로컬에 같은 ID의 작품이 있으면 로컬 이미지 경로 사용
                if serverArtwork.imageUrls.isEmpty {
                    var restoredImageUrls: [String] = []
                    
                    // 로컬 이미지 경로 복원 (ID 우선, 제목+작가명 차선)
                    if let localArtwork = localArtworks.first(where: { $0.id == serverArtwork.id }),
                       !localArtwork.imageUrls.isEmpty {
                        restoredImageUrls = localArtwork.imageUrls
                    } else if let currentArtwork = currentLocalArtworks.first(where: { $0.id == serverArtwork.id }),
                              !currentArtwork.imageUrls.isEmpty {
                        restoredImageUrls = currentArtwork.imageUrls
                    } else if let localArtwork = localArtworks.first(where: { 
                        $0.title == serverArtwork.title && 
                        $0.artistName == serverArtwork.artistName &&
                        !$0.imageUrls.isEmpty
                    }) {
                        restoredImageUrls = localArtwork.imageUrls
                    }
                    
                    // 파일 존재 여부 확인 후 복원
                    if !restoredImageUrls.isEmpty {
                        var validImageUrls: [String] = []
                        for imageUrl in restoredImageUrls {
                            let cleanUrl = imageUrl.hasPrefix("local://") ? String(imageUrl.dropFirst(8)) : imageUrl
                            if cleanUrl.hasPrefix("/") {
                                // 로컬 파일 경로인 경우 파일 존재 여부 확인
                                if fileManager.fileExists(atPath: cleanUrl) {
                                    validImageUrls.append(imageUrl)
                                }
                            } else {
                                // URL인 경우 그대로 추가
                                validImageUrls.append(imageUrl)
                            }
                        }
                        if !validImageUrls.isEmpty {
                            convertedArtworks[index].imageUrls = validImageUrls
                        }
                    }
                }
            }
            
            // 서버 데이터로 업데이트 (이미지 경로는 로컬에서 복원됨)
            artworks = convertedArtworks
            saveArtworks()
            
            AppLogger.debug("✅ 서버 데이터 동기화 완료: \(artworks.count)개 작품")
        } catch {
            errorMessage = "작품 목록 가져오기 실패: \(error.localizedDescription)"
            AppLogger.debug("❌ 작품 목록 가져오기 실패: \(error)")
            // 실패 시 기존 로컬 목록 유지 (목록 비우지 않음 → 홈/작가 상세에 계속 표시)
        }
        
        isLoading = false
    }
    
    // 작품 삭제
    func deleteArtwork(_ artwork: PostedArtwork) {
        artworks.removeAll { $0.id == artwork.id }
        saveArtworks()
        
        // 서버에서도 삭제
        Task {
            await deleteArtworkFromServer(artwork)
        }
    }
    
    // 서버에서 작품 삭제
    @MainActor
    private func deleteArtworkFromServer(_ artwork: PostedArtwork) async {
        do {
            // Supabase DELETE 요청
            let _: EmptyResponse = try await apiClient.request(
                endpoint: APIEndpoint.deleteArtwork(artworkId: artwork.id.uuidString).path,
                method: "DELETE"
            )
            AppLogger.debug("✅ 서버에서 작품 삭제 성공: \(artwork.title)")
        } catch {
            AppLogger.debug("❌ 서버에서 작품 삭제 실패: \(error)")
            errorMessage = "작품 삭제 실패: \(error.localizedDescription)"
        }
    }
    
    // 작품 업데이트
    func updateArtwork(_ artwork: PostedArtwork) {
        if let index = artworks.firstIndex(where: { $0.id == artwork.id }) {
            artworks[index] = artwork
            saveArtworks()
        }
    }
    
    // 작가별 작품 가져오기
    func getArtworksByArtist(_ artistName: String) -> [PostedArtwork] {
        return artworks.filter { $0.artistName == artistName }
    }
    
    // 모든 작가 목록 가져오기 (서버에 등록된 작가만 반환)
    func getAllArtists() -> [String] {
        // 서버에 등록된 작가만 반환하기 위해 ArtistProfileStore에서 작가 목록 가져오기
        // 하지만 비동기 작업이므로, 일단 artworks에서 작가 이름을 추출하고
        // 서버에 등록된 작가만 필터링하는 것은 별도로 처리해야 함
        // 여기서는 artworks에 있는 작가 이름을 반환하되, 실제 필터링은 호출하는 쪽에서 처리
        let artistNames = Set(artworks.map { $0.artistName }).filter { !$0.isEmpty }
        return Array(artistNames).sorted()
    }
    
    // 서버에 등록된 작가만 필터링하여 반환
    @MainActor
    func getRegisteredArtists() async -> [String] {
        // 서버에서 모든 작가 프로필 가져오기
        let registeredArtists = await ArtistProfileStore.shared.fetchAllArtistsFromServer()
        
        // artworks에 있는 작가 중 서버에 등록된 작가만 필터링
        let artworkArtists = Set(artworks.map { $0.artistName }).filter { !$0.isEmpty }
        let validArtists = artworkArtists.filter { registeredArtists.contains($0) }
        
        return Array(validArtists).sorted()
    }
    
    // 작가별 대표 작품 가져오기 (가장 최근 작품)
    func getRepresentativeArtwork(for artistName: String) -> PostedArtwork? {
        let artistArtworks = getArtworksByArtist(artistName)
        return artistArtworks.sorted { $0.createdAt > $1.createdAt }.first
    }
    
    // 모든 작품 데이터 초기화
    func clearAllArtworks() {
        artworks = []
        UserDefaults.standard.removeObject(forKey: "SavedArtworks")
        // 저장된 이미지 파일도 삭제
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesDirectory = documentsPath.appendingPathComponent("ArtworkImages")
        try? fileManager.removeItem(at: imagesDirectory)
    }
    
    // UserDefaults에 저장 (오프라인 지원 및 이미지 경로 보존용)
    func saveArtworks() {
        if let encoded = try? JSONEncoder().encode(artworks) {
            UserDefaults.standard.set(encoded, forKey: "SavedArtworks")
        }
    }
    
    // UserDefaults에서 작품 데이터 불러오기 (이미지 경로 복원용)
    private func loadArtworksFromLocal() -> [PostedArtwork] {
        if let data = UserDefaults.standard.data(forKey: "SavedArtworks"),
           let decoded = try? JSONDecoder().decode([PostedArtwork].self, from: data) {
            return decoded
        }
        return []
    }
}

// PostedArtwork를 ArtworkData로 변환하는 확장
extension PostedArtwork {
    func toArtworkData() -> ArtworkData {
        return ArtworkData(
            imageUrl: imageUrls.first ?? "",
            title: title,
            description: description,
            year: year,
            medium: medium,
            size: size,
            artistName: artistName,
            artistImageUrl: artistImageUrl
        )
    }
}

