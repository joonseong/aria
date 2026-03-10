//
//  APIClient.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import Foundation
import UIKit

// MARK: - API Configuration

/// Supabase Storage 버킷 이름 (소문자로 정확히 사용)
enum SupabaseStorageBucket {
    static let artworkImages = "artwork-images"
    static let profileImages = "profile-images"
}

struct APIConfig {
    // ⚠️ ServerConfig.shared.serverURL을 통해 설정됩니다
    // 직접 변경하지 말고 ServerConfig를 사용하세요
    static var baseURL: String {
        get {
            return UserDefaults.standard.string(forKey: "ServerURL") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ServerURL")
        }
    }
    static let apiVersion = "v1"
    
    static var baseAPIURL: String {
        let url = baseURL.isEmpty ? "https://api.aria.com" : baseURL
        // Supabase는 /rest/v1 형식을 사용하므로 apiVersion을 사용하지 않음
        // Supabase URL이면 그대로 사용, 아니면 /v1 추가
        if url.contains("supabase.co") {
            return url  // Supabase는 baseURL 그대로 사용
        }
        return "\(url)/\(apiVersion)"
    }
}

// MARK: - API Error

enum APIError: LocalizedError, CustomStringConvertible {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .invalidResponse:
            return "잘못된 응답입니다."
        case .httpError(let statusCode, let message):
            return message ?? "HTTP 오류 (\(statusCode))"
        case .decodingError(let error):
            return "데이터 파싱 오류: \(error.localizedDescription)"
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .unauthorized:
            return "인증이 필요합니다."
        case .serverError(let message):
            return "서버 오류: \(message)"
        }
    }
    
    /// 400 등 에러 시 서버 JSON 응답까지 확인하려면 String(describing: error)로 출력
    var description: String {
        switch self {
        case .httpError(let statusCode, let message):
            return "APIError.httpError(\(statusCode), message: \(message ?? "nil"))"
        default:
            return errorDescription ?? "\(type(of: self))"
        }
    }
}

// MARK: - API Response Models

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

struct EmptyResponse: Codable {}

// MARK: - API Client

class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private var accessToken: String? {
        // TODO: Keychain 또는 안전한 저장소에서 토큰 가져오기
        return UserDefaults.standard.string(forKey: "accessToken")
    }
    
    // Supabase API Key
    private var supabaseAPIKey: String? {
        return UserDefaults.standard.string(forKey: "SupabaseAPIKey")
    }
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }
    
    /// Supabase API Key 설정
    func setSupabaseAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "SupabaseAPIKey")
    }
    
    /// Supabase API Key 제거
    func clearSupabaseAPIKey() {
        UserDefaults.standard.removeObject(forKey: "SupabaseAPIKey")
    }
    
    // MARK: - Token Management
    
    func setAccessToken(_ token: String) {
        // TODO: Keychain에 저장하는 것이 더 안전함
        UserDefaults.standard.set(token, forKey: "accessToken")
    }
    
    func clearAccessToken() {
        UserDefaults.standard.removeObject(forKey: "accessToken")
    }
    
    // MARK: - Generic Request Method
    
    func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        var fullURLString = "\(APIConfig.baseAPIURL)\(endpoint)"
        // GET 요청 시 캐시 무효화용 타임스탬프 추가 (Supabase PostgREST 제외 — /rest/v1/ 은 쿼리 파라미터를 필터로 해석해 t= 값이 PGRST100 파싱 에러 유발)
        if method == "GET", !endpoint.contains("/rest/v1/") {
            let separator = fullURLString.contains("?") ? "&" : "?"
            fullURLString += "\(separator)t=\(Int(Date().timeIntervalSince1970))"
        }
        AppLogger.debug("🌐 API 요청:")
        AppLogger.debug("   Full URL: \(fullURLString)")
        AppLogger.debug("   Method: \(method)")
        
        guard let url = URL(string: fullURLString) else {
            AppLogger.debug("❌ 잘못된 URL: \(fullURLString)")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Supabase API Key 추가 (Supabase 사용 시)
        if let supabaseKey = supabaseAPIKey {
            request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            // PATCH/POST 시 수정·생성된 행을 응답에 포함 (빈 응답이면 디코딩 에러 방지)
            if method == "PATCH" || method == "POST" {
                request.setValue("return=representation", forHTTPHeaderField: "Prefer")
            }
        } else if let token = accessToken {
            // 일반 인증 토큰 (Supabase가 아닌 경우)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 추가 헤더
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Request Body
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // HTTP 상태 코드 확인
            guard (200...299).contains(httpResponse.statusCode) else {
                #if DEBUG
                if let errorData = String(data: data, encoding: .utf8) {
                    AppLogger.debug("❌ HTTP 에러 응답:")
                    AppLogger.debug("   Status Code: \(httpResponse.statusCode)")
                    AppLogger.debug("   URL: \(url.absoluteString)")
                    AppLogger.debug("   Response: \(errorData)")
                }
                #endif
                
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                throw APIError.httpError(
                    statusCode: httpResponse.statusCode,
                    message: errorMessage?["message"] ?? errorMessage?["error"]
                )
            }
            
            // 응답 디코딩
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // APIResponse 래퍼가 있는 경우
            if let apiResponse = try? decoder.decode(APIResponse<T>.self, from: data) {
                if apiResponse.success, let data = apiResponse.data {
                    return data
                } else {
                    throw APIError.serverError(apiResponse.error ?? apiResponse.message ?? "알 수 없는 오류")
                }
            }
            
            // 직접 데이터인 경우
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                if let errorData = String(data: data, encoding: .utf8) {
                    AppLogger.debug("❌ 디코딩 에러:")
                    AppLogger.debug("   Expected Type: \(T.self)")
                    AppLogger.debug("   Response Data: \(errorData.prefix(500))")
                    AppLogger.debug("   Error: \(error)")
                }
                #endif
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Image Upload
    
    func uploadImage(_ image: UIImage, endpoint: String) async throws -> String {
        guard let url = URL(string: "\(APIConfig.baseAPIURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 인증 토큰 추가
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Multipart Form Data 생성
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 이미지 데이터 추가
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.invalidResponse
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: nil)
            }
            
            // 서버에서 이미지 URL 반환 (형식에 맞게 수정 필요)
            struct ImageUploadResponse: Codable {
                let imageUrl: String
            }
            
            let decoder = JSONDecoder()
            if let apiResponse = try? decoder.decode(APIResponse<ImageUploadResponse>.self, from: data) {
                if let imageUrl = apiResponse.data?.imageUrl {
                    return imageUrl
                }
            }
            
            // 직접 응답인 경우
            let imageResponse = try decoder.decode(ImageUploadResponse.self, from: data)
            return imageResponse.imageUrl
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Multiple Images Upload
    
    func uploadImages(_ images: [UIImage], endpoint: String) async throws -> [String] {
        var uploadedUrls: [String] = []
        
        for image in images {
            let url = try await uploadImage(image, endpoint: endpoint)
            uploadedUrls.append(url)
        }
        
        return uploadedUrls
    }
    
    // MARK: - Supabase Storage Upload
    
    /// UIImage를 용량 제한 내로 JPEG Data로 변환 (HDR 제거 후 압축 품질 단계적 감소)
    /// - Parameters:
    ///   - image: 원본 이미지
    ///   - maxByteCount: 목표 최대 용량 (기본 1MB)
    ///   - maxDimension: 긴 변 최대 픽셀 (넘으면 리사이즈 후 압축)
    /// - Returns: JPEG Data
    private func jpegDataWithCompression(image: UIImage, maxByteCount: Int = 1_048_576, maxDimension: CGFloat = 1920) -> Data? {
        // HDR 메타데이터 제거 (IIOCallConvertHDRData -50 방지)
        var target = image.byStrippingHDR()
        // 큰 이미지는 리사이즈하여 용량 절감
        let w = target.size.width, h = target.size.height
        if w > maxDimension || h > maxDimension {
            let scale = min(maxDimension / w, maxDimension / h)
            let newSize = CGSize(width: w * scale, height: h * scale)
            let format = UIGraphicsImageRendererFormat()
            format.scale = target.scale
            format.opaque = false
            format.preferredRange = .standard
            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            target = renderer.image { _ in target.draw(in: CGRect(origin: .zero, size: newSize)) }
        }
        let qualities: [CGFloat] = [0.8, 0.65, 0.5, 0.4, 0.3]
        for q in qualities {
            guard let data = target.jpegData(compressionQuality: q), data.count <= maxByteCount else { continue }
            return data
        }
        // 여전히 크면 최저 품질로 반환
        return target.jpegData(compressionQuality: 0.25)
    }
    
    /// Supabase Storage에 이미지 업로드하고 public URL 반환.
    /// REST API 사용 시 FileOptions에 해당하는 설정: Content-Type으로 contentType 전달.
    func uploadImageToSupabaseStorage(_ image: UIImage, bucket: String, fileName: String) async throws -> String {
        let base = APIConfig.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let uploadURLString = "\(base)/storage/v1/object/\(bucket)/\(fileName)"
        guard let uploadURL = URL(string: uploadURLString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        
        if let apiKey = supabaseAPIKey {
            request.setValue(apiKey, forHTTPHeaderField: "apikey")
            if let token = accessToken, !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
        }
        // options: FileOptions(contentType: "image/jpeg") — 빠지면 Supabase가 400 에러를 반환할 수 있음
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        // upsert: true — 동일 경로 덮어쓰기 허용 (필수)
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        
        guard let imageData = jpegDataWithCompression(image: image) else {
            throw APIError.invalidResponse
        }
        request.httpBody = imageData
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let rawMessage = String(data: data, encoding: .utf8) ?? ""
                let err = APIError.httpError(statusCode: httpResponse.statusCode, message: rawMessage)
                #if DEBUG
                AppLogger.debug("❌ Storage 업로드 실패: \(httpResponse.statusCode)")
                AppLogger.debug("   localizedDescription: \(err.localizedDescription)")
                AppLogger.debug("   String(describing:): \(String(describing: err))")
                #endif
                if httpResponse.statusCode == 403 {
                    let rlsMessage = """
                    Storage RLS 정책 위반 (403 Forbidden).
                    서버 응답: \(rawMessage)
                    → Supabase 대시보드 Storage → Policies에서 storage.objects INSERT 정책을 확인하세요. (bucket_id = '\(bucket)')
                    """
                    throw APIError.httpError(statusCode: 403, message: rlsMessage)
                }
                throw err
            }
            
            let fullPath = "\(bucket)/\(fileName)"
            let publicURL = "\(base)/storage/v1/object/public/\(bucket)/\(fileName)"
            #if DEBUG
            AppLogger.debug("✅ Storage 업로드 성공")
            AppLogger.debug("   fullPath: \(fullPath)")
            AppLogger.debug("   publicURL: \(publicURL)")
            ImageHelper.logImageUrlIfNeeded(publicURL, context: "업로드 반환 URL")
            #endif
            return publicURL
            
        } catch let error as APIError {
            #if DEBUG
            AppLogger.debug("❌ Storage 업로드 APIError - localizedDescription: \(error.localizedDescription)")
            AppLogger.debug("❌ Storage 업로드 APIError - String(describing:): \(String(describing: error))")
            #endif
            throw error
        } catch {
            #if DEBUG
            AppLogger.debug("❌ Storage 업로드 기타 에러 - localizedDescription: \(error.localizedDescription)")
            AppLogger.debug("❌ Storage 업로드 기타 에러 - String(describing:): \(String(describing: error))")
            #endif
            throw APIError.networkError(error)
        }
    }
    
    /// 여러 이미지를 Supabase Storage에 업로드 (파일명: UUID().uuidString + ".jpg" — Safe Path)
    func uploadImagesToSupabaseStorage(_ images: [UIImage], bucket: String) async throws -> [String] {
        var uploadedUrls: [String] = []
        
        for image in images {
            let fileName = UUID().uuidString + ".jpg"
            let publicURL = try await uploadImageToSupabaseStorage(image, bucket: bucket, fileName: fileName)
            uploadedUrls.append(publicURL)
        }
        
        return uploadedUrls
    }
}

// MARK: - API Endpoints

enum APIEndpoint {
    // Auth
    case login(kakaoToken: String?, appleToken: String?)
    case logout
    case refreshToken
    case deleteAccount
    
    // User
    case getUserProfile
    case updateUserProfile
    case getUserRole(userId: String)
    
    // Artist
    case getArtistProfile(artistId: String)
    case updateArtistProfile
    case uploadProfileImage
    
    // Artwork
    case getArtworks
    case getArtwork(artworkId: String)
    case createArtwork
    case updateArtwork(artworkId: String)
    case deleteArtwork(artworkId: String)
    case getArtworksByArtist(artistId: String)
    case uploadArtworkImages
    
    // Like
    case likeArtwork(artworkId: String)
    case unlikeArtwork(artworkId: String)
    case getLikedArtworks
    
    // Follow
    case followArtist(artistId: String)
    case unfollowArtist(artistId: String)
    case getFollowedArtists
    case getFollowCount(artistId: String)
    
    // Guestbook
    case getGuestbookEntries(artistId: String)
    case createGuestbookEntry(artistId: String)
    case deleteGuestbookEntry(entryId: String)
    
    // Search
    case searchArtworks(query: String)
    case searchArtists(query: String)
    
    var path: String {
        switch self {
        // Auth
        case .login:
            return "/auth/login"
        case .logout:
            return "/auth/logout"
        case .refreshToken:
            return "/auth/refresh"
        case .deleteAccount:
            return "/auth/delete"
        
        // User
        case .getUserProfile:
            return "/user/profile"
        case .updateUserProfile:
            return "/user/profile"
        case .getUserRole(let userId):
            return "/user/\(userId)/role"
        
        // Artist
        case .getArtistProfile(let artistId):
            return "/artist/\(artistId)/profile"
        case .updateArtistProfile:
            return "/artist/profile"
        case .uploadProfileImage:
            return "/artist/profile/image"
        
        // Artwork (Supabase REST API 형식)
        case .getArtworks:
            return "/rest/v1/artworks"
        case .getArtwork(let artworkId):
            return "/rest/v1/artworks?id=eq.\(artworkId)"
        case .createArtwork:
            return "/rest/v1/artworks"
        case .updateArtwork(let artworkId):
            return "/rest/v1/artworks?id=eq.\(artworkId)"
        case .deleteArtwork(let artworkId):
            return "/rest/v1/artworks?id=eq.\(artworkId)"
        case .getArtworksByArtist(let artistId):
            return "/rest/v1/artworks?artist_id=eq.\(artistId)"
        case .uploadArtworkImages:
            return "/storage/v1/object/\(SupabaseStorageBucket.artworkImages)"
        
        // Like
        case .likeArtwork(let artworkId):
            return "/artworks/\(artworkId)/like"
        case .unlikeArtwork(let artworkId):
            return "/artworks/\(artworkId)/unlike"
        case .getLikedArtworks:
            return "/artworks/liked"
        
        // Follow
        case .followArtist(let artistId):
            return "/artist/\(artistId)/follow"
        case .unfollowArtist(let artistId):
            return "/artist/\(artistId)/unfollow"
        case .getFollowedArtists:
            return "/artist/followed"
        case .getFollowCount(let artistId):
            return "/artist/\(artistId)/follow/count"
        
        // Guestbook
        case .getGuestbookEntries(let artistId):
            return "/guestbook/\(artistId)"
        case .createGuestbookEntry(let artistId):
            return "/guestbook/\(artistId)"
        case .deleteGuestbookEntry(let entryId):
            return "/guestbook/entry/\(entryId)"
        
        // Search
        case .searchArtworks:
            return "/search/artworks"
        case .searchArtists:
            return "/search/artists"
        }
    }
    
    var method: String {
        switch self {
        case .getUserProfile, .getArtistProfile, .getArtworks, .getArtwork, .getArtworksByArtist,
             .getLikedArtworks, .getFollowedArtists, .getFollowCount, .getGuestbookEntries,
             .getUserRole, .searchArtworks, .searchArtists:
            return "GET"
        case .login, .createArtwork, .createGuestbookEntry, .likeArtwork, .followArtist,
             .updateUserProfile, .updateArtistProfile, .uploadProfileImage, .uploadArtworkImages:
            return "POST"
        case .updateArtwork, .refreshToken:
            return "PUT"
        case .logout, .deleteAccount, .deleteArtwork, .unlikeArtwork, .unfollowArtist,
             .deleteGuestbookEntry:
            return "DELETE"
        }
    }
}

