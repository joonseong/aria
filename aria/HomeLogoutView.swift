//
//  HomeLogoutView.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI

struct HomeLogoutView: View {
    @State private var showLogin = false
    @State private var selectedArtist: String?  // 작가 상세로 이동하기 위한 작가 이름
    @State private var showArtistDetail = false
    @State private var showSearch = false  // 검색 화면 표시
    @State private var registeredArtists: [String] = []  // 서버에 등록된 작가 목록
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var artworkStore = ArtworkStore.shared
    @StateObject private var profileStore = ArtistProfileStore.shared
    
    var body: some View {
        ZStack {
            // 배경색
            Color.shapeDepth1
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 네비게이션 바 (상단 고정)
                TopNavigationBar(
                    isLoggedIn: false,
                    onLoginTap: {
                        showLogin = true
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
                
                // 메인 콘텐츠 (전환 시 레이아웃 깨짐 방지)
                Group {
                    if artworkStore.artworks.isEmpty {
                        HomeUserEmptyView(isLoggedIn: false, onLoginTap: {
                            showLogin = true
                        })
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        let allArtists = artworkStore.getAllArtists()
                        let validArtists: [String] = registeredArtists.isEmpty ? allArtists : allArtists.filter { registeredArtists.contains($0) }
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(validArtists, id: \.self) { (artistName: String) in
                                    if let representativeArtwork = artworkStore.getRepresentativeArtwork(for: artistName),
                                       let artistImageUrl = representativeArtwork.artistImageUrl.isEmpty ? nil : representativeArtwork.artistImageUrl {
                                        ArtistCard(
                                            artistName: artistName,
                                            artistImageUrl: artistImageUrl,
                                            representativeArtwork: representativeArtwork,
                                            artistDescription: "",
                                            hasShadow: validArtists.firstIndex(of: artistName) == 1,
                                            onArtistTap: {
                                                selectedArtist = artistName
                                                showArtistDetail = true
                                            }
                                        )
                                        .id("artist-\(artistName)")
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
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
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
        }
        .fullScreenCover(isPresented: $showArtistDetail) {
            if let artistName = selectedArtist {
                let artworks = artworkStore.getArtworksByArtist(artistName)
                if let firstArtwork = artworks.first {
                    DetailUserView(artwork: firstArtwork.toArtworkData())
                } else {
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
        .fullScreenCover(isPresented: $showSearch) {
            SearchView()
        }
        .onAppear {
            // 작품 목록이 비어 있으면 서버에서 다시 가져오기 (앱 첫 실행/로그아웃 후 등)
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
    HomeLogoutView()
}

