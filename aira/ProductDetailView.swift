//
//  ProductDetailView.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI

struct ProductDetailView: View {
    let artwork: PostedArtwork
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var artworkStore = ArtworkStore.shared
    @StateObject private var likeStore = LikeStore.shared
    @StateObject private var profileStore = ArtistProfileStore.shared
    @State private var currentImageIndex: Int = 0
    @State private var showDeleteAlert = false
    @State private var showGuestBook = false
    @State private var scrollContentMinY: CGFloat = 0
    
    /// 스크롤이 최상단일 때 헤더 배경 투명(0%), 스크롤 시 불투명(100%). coordinateSpace 기준 minY가 0 근처면 최상단.
    private var headerBackgroundOpacity: Double {
        scrollContentMinY >= -20 ? 0 : 1
    }
    
    var body: some View {
        ZStack {
            Color.shapeDefault
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                DetailScreenHeader(backgroundOpacity: headerBackgroundOpacity) {
                    Button(action: { dismiss() }) {
                        Image("icon.back")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .foregroundColor(.foregroundPrimary)
                    }
                    Text("작품 상세")
                        .font(Typography.Heading3.font)
                        .foregroundColor(.foregroundPrimary)
                    Spacer()
                    Button(action: {
                        ShareHelper.shareArtwork(
                            title: artwork.title,
                            description: artwork.description,
                            imageUrl: artwork.imageUrls.first
                        )
                    }) {
                        Image("icon.share")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .foregroundColor(.foregroundPrimary)
                    }
                }
                
                // ScrollView Content
                GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 스크롤 위치 감지용 (최상단일 때 minY ≈ 0, 스크롤 시 음수)
                        Color.clear
                            .frame(height: 1)
                            .background(
                                GeometryReader { g in
                                    Color.clear.preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: g.frame(in: .named("productDetailScroll")).minY
                                    )
                                }
                            )
                        
                        // Product Image Container (Swipeable) — 원본 비율 유지 (fit) + 고정 높이
                        if !artwork.imageUrls.isEmpty {
                            ZStack(alignment: .bottom) {
                                TabView(selection: $currentImageIndex) {
                                    ForEach(Array(artwork.imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                                        SmartImageView(
                                            imageUrl: imageUrl,
                                            placeholder: Color.shapeDepth2,
                                            contentMode: .fit
                                        )
                                        .frame(width: geometry.size.width, height: 464)
                                        .clipped()
                                        .tag(index)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .frame(width: geometry.size.width, height: 464)
                                .onAppear {
                                    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.foregroundPrimary)
                                    UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.foregroundPlaceholder)
                                }
                                
                                // Pagination Dots (커스텀)
                                if artwork.imageUrls.count > 1 {
                                    HStack(spacing: 4) {
                                        ForEach(0..<artwork.imageUrls.count, id: \.self) { index in
                                            Circle()
                                                .fill(index == currentImageIndex ? Color.foregroundPrimary : Color.foregroundPlaceholder)
                                                .frame(width: 8, height: 8)
                                        }
                                    }
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                    
                    // Product Info Container
                    VStack(spacing: 24) {
                        // Post Container
                        VStack(alignment: .leading, spacing: 12) {
                            // Post Header
                            HStack {
                                // Author Info
                                HStack(spacing: 8) {
                                    Group {
                                        // 작가 프로필 이미지 가져오기 (프로필이 있으면 프로필에서, 없으면 artwork에서)
                                        let currentArtistName = profileStore.profile.nickname
                                        let isCurrentArtist = !currentArtistName.isEmpty && artwork.artistName == currentArtistName
                                        
                                        let artistImageUrl: String = {
                                            if isCurrentArtist, let profileImageUrl = profileStore.profile.profileImageUrl, !profileImageUrl.isEmpty {
                                                return profileImageUrl
                                            } else if !artwork.artistImageUrl.isEmpty {
                                                return artwork.artistImageUrl
                                            } else {
                                                return ""
                                            }
                                        }()
                                        
                                        if !artistImageUrl.isEmpty {
                                            // local:// 접두사 제거
                                            let cleanUrl = artistImageUrl.hasPrefix("local://") ? String(artistImageUrl.dropFirst(8)) : artistImageUrl
                                            
                                            if cleanUrl.hasPrefix("/") {
                                                // 로컬 파일 경로인 경우
                                                if let uiImage = UIImage(contentsOfFile: cleanUrl) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } else {
                                                    Circle()
                                                        .fill(Color.shapeDepth2)
                                                }
                                            } else if cleanUrl.hasPrefix("http://") || cleanUrl.hasPrefix("https://") {
                                                // URL인 경우 (캐시 무효화 쿼리 적용)
                                                AsyncImage(url: URL(string: ImageHelper.urlWithCacheBusting(cleanUrl))) { phase in
                                                    switch phase {
                                                    case .empty, .failure:
                                                        Circle()
                                                            .fill(Color.shapeDepth2)
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                    @unknown default:
                                                        Circle()
                                                            .fill(Color.shapeDepth2)
                                                    }
                                                }
                                            } else {
                                                Circle()
                                                    .fill(Color.shapeDepth2)
                                            }
                                        } else {
                                            Circle()
                                                .fill(Color.shapeDepth2)
                                        }
                                    }
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                                    
                                    Text(artwork.artistName)
                                        .font(Typography.Body4.font.weight(Typography.fontWeightBold))
                                        .foregroundColor(.foregroundSecondary)
                                }
                                
                                Spacer()
                                
                                // More 버튼 (내 작품일 때만 — Artist가 자신의 작품 볼 때만 삭제 가능)
                                if authManager.userRole == .artist && artwork.artistName == profileStore.profile.nickname {
                                    Button(action: {
                                        showDeleteAlert = true
                                    }) {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 20))
                                            .foregroundColor(.foregroundPrimary)
                                            .frame(width: 28, height: 28)
                                    }
                                }
                            }
                            
                            // Post Content
                            VStack(alignment: .leading, spacing: 8) {
                                Text(artwork.title)
                                    .font(Typography.Heading1.font)
                                    .foregroundColor(.foregroundPrimary)
                                
                                Text(artwork.description)
                                    .font(Typography.Body2.font)
                                    .foregroundColor(.foregroundSecondary)
                            }
                        }
                        
                        // Product Details Container
                        VStack(alignment: .leading, spacing: 8) {
                            Text("작품 상세 정보")
                                .font(Typography.Heading3.font)
                                .foregroundColor(.foregroundPrimary)
                            
                            VStack(spacing: 8) {
                                // 제작 년도
                                HStack {
                                    Text("제작 년도")
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundTertiary)
                                    
                                    Spacer()
                                    
                                    Text(artwork.year)
                                        .font(Typography.Body3.font)
                                        .foregroundColor(.foregroundSecondary)
                                }
                                
                                // 작품 크기
                                HStack {
                                    Text("작품 크기")
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundTertiary)
                                    
                                    Spacer()
                                    
                                    Text(artwork.size)
                                        .font(Typography.Body3.font)
                                        .foregroundColor(.foregroundSecondary)
                                }
                                
                                // 제작 기법
                                HStack {
                                    Text("제작 기법")
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundTertiary)
                                    
                                    Spacer()
                                    
                                    Text(artwork.medium)
                                        .font(Typography.Body3.font)
                                        .foregroundColor(.foregroundSecondary)
                                }
                            }
                            .padding(16)
                            .background(Color.shapeDepth1)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.shapeDepth2)
                        .frame(height: 8)
                    
                    // Message Container (User 권한: 일반 유저 또는 Artist가 다른 사람 작품 볼 때)
                    let isViewingMyArtwork = authManager.userRole == .artist && artwork.artistName == profileStore.profile.nickname
                    if !isViewingMyArtwork {
                        VStack(spacing: 24) {
                            VStack(spacing: 0) {
                                Text("작품이 마음에 드셨나요?")
                                    .font(Typography.Heading2.font)
                                    .foregroundColor(.foregroundPrimary)
                                
                                Text("작가에게 응원의 메시지를 보내보세요.")
                                    .font(Typography.Heading2.font)
                                    .foregroundColor(.foregroundPrimary)
                            }
                            .multilineTextAlignment(.center)
                            
                            AiraButton("방명록 남기기", style: .primary) {
                                showGuestBook = true
                            }
                        }
                        .padding(24)
                    }
                    }
                }
                .frame(width: geometry.size.width)
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { scrollContentMinY = $0 }
            }
            .coordinateSpace(name: "productDetailScroll")
            }
            }
        .alert("작품 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                artworkStore.deleteArtwork(artwork)
                dismiss()
            }
        } message: {
            Text("이 작품을 삭제하시겠습니까?")
        }
        .fullScreenCover(isPresented: $showGuestBook) {
            GuestBookView(
                artistName: artwork.artistName,
                isArtistViewing: false
            )
        }
    }
}

#Preview {
    ProductDetailView(artwork: PostedArtwork(
        imageUrls: ["http://localhost:3845/assets/22e93cd86b1c87caed791020ed9df8aa4ee4f0e4.png"],
        title: "오전 햇살",
        description: "혼란한 공간의 구원자라는 존재를 기존의 상식과는 다르게 비틀어 반영웅적인 이미지를 만들다.",
        year: "2023",
        medium: "아크릴 캔버스",
        size: "35.8 cm X 42.6 cm",
        artistName: "아리아",
        artistImageUrl: "http://localhost:3845/assets/169b8964c25d75d580e2c8f4c68f9d2c8ecc09e0.png"
    ))
}

