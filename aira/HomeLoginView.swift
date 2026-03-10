//
//  HomeLoginView.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI

struct HomeLoginView: View {
    @State private var selectedArtist: String?  // 작가 상세로 이동
    @State private var isArtistDetailPresented = false
    @State private var selectedPostedArtwork: PostedArtwork?  // 작품 상세로 이동
    @State private var showUserProfile = false
    @State private var showSearch = false
    @State private var registeredArtists: [String] = []
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var artworkStore = ArtworkStore.shared
    @StateObject private var profileStore = ArtistProfileStore.shared
    @StateObject private var userProfileStore = UserProfileStore.shared
    
    var body: some View {
        ZStack {
            // 배경색
            Color.shapeDepth1
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 네비게이션 바 (상단 고정)
                TopNavigationBar(
                    isLoggedIn: true,
                    onProfileTap: {
                        // 작가인 경우 detail - artist로 이동, 일반 유저인 경우 user - profile로 이동
                        AppLogger.debug("🔍 프로필 버튼 클릭 - 현재 역할: \(authManager.userRole)")
                        if authManager.userRole == .artist {
                            AppLogger.debug("✅ 작가로 인식 - DetailUserView로 이동")
                            let artistName = profileStore.profile.nickname
                            // selectedArtist만 먼저 설정 → onChange에서 시트 오픈 (검정화면 방지)
                            selectedArtist = artistName.isEmpty ? "current_artist" : artistName
                        } else {
                            AppLogger.debug("✅ 일반 유저로 인식 - UserProfileView로 이동")
                            showUserProfile = true
                        }
                    },
                    onSearchTap: {
                        showSearch = true
                    }
                )
                .background(Color.shapeDefault)
                .zIndex(1)
                
                // 데이터 로딩 에러 시 메시지 (화면이 하얗게 비지 않도록)
                if let errorMsg = artworkStore.errorMessage {
                    HStack {
                        Text(errorMsg)
                            .font(Typography.Caption2.font)
                            .foregroundColor(.red)
                            .lineLimit(2)
                        Spacer()
                        Button("다시 시도") {
                            Task { await artworkStore.fetchArtworksFromServer() }
                        }
                        .font(Typography.Caption2.font)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                }
                
                // 메인 콘텐츠 (전환 시 레이아웃 깨짐 방지: 동일 컨테이너 + id로 뷰 식별)
                Group {
                    if artworkStore.artworks.isEmpty {
                        HomeUserEmptyView(isLoggedIn: true)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        let allArtworks = artworkStore.artworks
                        let filteredByRegistered: [PostedArtwork] = registeredArtists.isEmpty
                            ? allArtworks
                            : allArtworks.filter { registeredArtists.contains($0.artistName) }
                        // 서버 작가 목록이 아직 로드되지 않았거나 매칭이 안 되는 경우, 홈 피드가 비지 않도록 전체 작품으로 폴백
                        let filtered: [PostedArtwork] = filteredByRegistered.isEmpty ? allArtworks : filteredByRegistered
                        let lastId = filtered.last?.id
                        
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filtered) { (postedArtwork: PostedArtwork) in
                                    HomeArtworkFeedCard(
                                        artwork: postedArtwork,
                                        hasShadow: false,
                                        onImageTap: {
                                            selectedPostedArtwork = postedArtwork
                                        },
                                        onArtistTap: {
                                            selectedArtist = postedArtwork.artistName
                                        }
                                    )
                                    .id(postedArtwork.id)
                                    if let lastId, postedArtwork.id != lastId {
                                        Rectangle()
                                            .fill(Color.borderPrimary)
                                            .frame(height: 1)
                                    }
                                }
                            }
                            .padding(.top, 12)
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.shapeDepth1)
                    }
                }
                .id(artworkStore.artworks.isEmpty ? "empty" : "list")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.none, value: artworkStore.artworks.isEmpty)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: selectedArtist) { _, newValue in
            if newValue != nil {
                isArtistDetailPresented = true
            }
        }
        .onChange(of: isArtistDetailPresented) { _, presented in
            if !presented {
                selectedArtist = nil
            }
        }
        .fullScreenCover(isPresented: $isArtistDetailPresented) {
            if let artistName = selectedArtist {
            // 작가 상세 페이지로 이동
            // "current_artist"는 현재 로그인한 작가를 의미 (프로필이 비어있을 때)
            if artistName == "current_artist" {
                // 현재 작가: 항상 artistName "current_artist"로 전달해 DetailUserView에서 본인으로 인식되게 함
                let currentNickname = profileStore.profile.nickname.isEmpty ? userProfileStore.profile.nickname : profileStore.profile.nickname
                let artworks = artworkStore.getArtworksByArtist(currentNickname)
                let profileImageUrl = profileStore.profile.profileImageUrl ?? userProfileStore.profile.profileImageUrl ?? ""
                
                if let firstArtwork = artworks.first {
                    let data = firstArtwork.toArtworkData()
                    DetailUserView(artwork: ArtworkData(
                        imageUrl: data.imageUrl,
                        title: data.title,
                        description: data.description,
                        year: data.year,
                        medium: data.medium,
                        size: data.size,
                        artistName: "current_artist",
                        artistImageUrl: data.artistImageUrl.isEmpty ? profileImageUrl : data.artistImageUrl
                    ))
                } else {
                    DetailUserView(artwork: ArtworkData(
                        imageUrl: "",
                        title: "",
                        description: "",
                        year: "",
                        medium: "",
                        size: "",
                        artistName: "current_artist",
                        artistImageUrl: profileImageUrl
                    ))
                }
            } else {
                // 일반 작가 상세 페이지
                let artworks = artworkStore.getArtworksByArtist(artistName)
                if let firstArtwork = artworks.first {
                    DetailUserView(artwork: firstArtwork.toArtworkData())
                } else {
                    // 작품이 없는 경우 빈 작품 데이터로 표시
                    DetailUserView(artwork: ArtworkData(
                        imageUrl: "",
                        title: "",
                        description: "",
                        year: "",
                        medium: "",
                        size: "",
                        artistName: artistName,
                        artistImageUrl: ""
                    ))
                }
            }
            }
        }
        .fullScreenCover(item: $selectedPostedArtwork) { artwork in
            ProductDetailView(artwork: artwork)
                .onDisappear {
                    selectedPostedArtwork = nil
                }
        }
        .fullScreenCover(isPresented: $showUserProfile) {
            UserProfileView()
        }
        .fullScreenCover(isPresented: $showSearch) {
            SearchView()
        }
        .onAppear {
            // 작품 목록이 비어 있으면 서버에서 다시 가져오기 (로그아웃 후 재진입 등)
            if artworkStore.artworks.isEmpty {
                Task { await artworkStore.fetchArtworksFromServer() }
            }
            
            // 서버에서 등록된 작가 목록 가져오기
            Task {
                let artists = await profileStore.fetchAllArtistsFromServer()
                await MainActor.run {
                    registeredArtists = artists
                }
            }
        }
        .onChange(of: artworkStore.artworks.count) { oldValue, newValue in
            // 작품 목록이 변경되면 서버에서 작가 목록 다시 가져오기
            Task {
                let artists = await profileStore.fetchAllArtistsFromServer()
                await MainActor.run {
                    registeredArtists = artists
                }
            }
        }
    }
    
    
}

#Preview {
    HomeLoginView()
}

