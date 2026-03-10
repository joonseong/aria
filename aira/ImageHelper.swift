//
//  ImageHelper.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import UIKit

/// 이미지 URL을 처리하는 헬퍼
struct ImageHelper {
    /// 이미지 URL을 정리 (local:// 접두사 제거)
    static func cleanImageUrl(_ url: String) -> String {
        if url.hasPrefix("local://") {
            return String(url.dropFirst(8))
        }
        return url
    }
    
    /// 이미지 URL이 로컬 파일 경로인지 확인
    static func isLocalPath(_ url: String) -> Bool {
        let cleanUrl = cleanImageUrl(url)
        return cleanUrl.hasPrefix("/")
    }
    
    /// 이미지 URL이 원격 URL인지 확인
    static func isRemoteUrl(_ url: String) -> Bool {
        let cleanUrl = cleanImageUrl(url)
        return cleanUrl.hasPrefix("http://") || cleanUrl.hasPrefix("https://")
    }
    
    /// 로컬 이미지 로드 (HDR 메타데이터 제거하여 표준 sRGB로 반환 — IIOCallConvertHDRData -50 방지)
    static func loadLocalImage(_ url: String) -> UIImage? {
        let cleanUrl = cleanImageUrl(url)
        guard let image = UIImage(contentsOfFile: cleanUrl) else { return nil }
        return image.byStrippingHDR()
    }
    
    /// 캐시 무효화를 위해 URL 뒤에 타임스탬프 쿼리 파라미터 추가 (?t= 또는 &t=)
    static func urlWithCacheBusting(_ urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, isRemoteUrl(trimmed) else { return urlString }
        let separator = trimmed.contains("?") ? "&" : "?"
        return "\(trimmed)\(separator)t=\(Int(Date().timeIntervalSince1970))"
    }
    
    /// 이미지 URL 검수 로그 (https://.../storage/v1/object/public/... 형태 및 유효성)
    static func logImageUrlIfNeeded(_ urlString: String, context: String = "이미지 URL") {
        let clean = cleanImageUrl(urlString)
        guard !clean.isEmpty else { return }
        #if DEBUG
        let isPublicStorage = clean.contains("storage/v1/object/public/")
        let isHttps = clean.hasPrefix("https://")
        AppLogger.debug("🖼 \(context): \(clean)")
        AppLogger.debug("   형식 OK: https+public=\(isHttps && isPublicStorage), 경로=\(isPublicStorage ? "storage/public" : "기타")")
        #endif
    }
}

/// 이미지 캐시 정리 (URLCache). Kingfisher 도입 시 ImageCache.default.clearMemoryCache() / clearDiskCache() 호출 추가 가능.
enum ImageCacheManager {
    /// 메모리 캐시 비우기
    static func clearMemoryCache() {
        URLCache.shared.removeAllCachedResponses()
    }
    
    /// 디스크 캐시 비우기
    static func clearDiskCache() {
        URLCache.shared.removeAllCachedResponses()
    }
    
    /// 메모리 + 디스크 캐시 모두 비우기
    static func clearAllCaches() {
        clearMemoryCache()
        clearDiskCache()
    }
}

/// 플레이스홀더용 아이콘 뷰 (이미지 로드 실패/빈 URL 시 그레이 박스 대신 표시)
private struct PlaceholderIconView: View {
    var body: some View {
        ZStack {
            Color.shapeDepth2
            Image(systemName: "person.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(Color.foregroundPlaceholder)
        }
    }
}

/// 이미지 뷰 (로컬/원격 지원, 크기 고정·플레이스홀더 아이콘)
/// - 호출부에서 .frame(width:height:) 또는 .frame(maxWidth:maxHeight:)로 크기를 지정해 거대 그레이 박스 방지.
struct SmartImageView: View {
    let imageUrl: String
    let placeholder: Color
    var contentMode: ContentMode = .fill
    
    init(imageUrl: String, placeholder: Color = Color.shapeDepth2, contentMode: ContentMode = .fill) {
        self.imageUrl = imageUrl
        self.placeholder = placeholder
        self.contentMode = contentMode
    }
    
    var body: some View {
        smartImageContent
            .clipped()
    }
    
    private var cleanedUrl: String {
        ImageHelper.cleanImageUrl(imageUrl)
    }
    
    @ViewBuilder
    private var smartImageContent: some View {
        if imageUrl.isEmpty {
            PlaceholderIconView()
        } else if ImageHelper.isLocalPath(cleanedUrl) {
            if let uiImage = ImageHelper.loadLocalImage(cleanedUrl) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                PlaceholderIconView()
            }
        } else if ImageHelper.isRemoteUrl(cleanedUrl) {
            RemoteImageView(urlString: ImageHelper.urlWithCacheBusting(cleanedUrl), contentMode: contentMode)
        } else {
            PlaceholderIconView()
        }
    }
}

/// 원격 URL 전용 서브뷰 (AsyncImage 타입 추론 분리)
private struct RemoteImageView: View {
    let urlString: String
    var contentMode: ContentMode = .fill
    
    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .empty:
                PlaceholderIconView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                PlaceholderIconView()
            @unknown default:
                PlaceholderIconView()
            }
        }
        .onAppear { ImageHelper.logImageUrlIfNeeded(urlString, context: "SmartImageView 원격") }
    }
}

