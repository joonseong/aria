//
//  DetailArtistView.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI

struct DetailArtistView: View {
    let artwork: ArtworkData
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var artworkStore = ArtworkStore.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var profileStore = ArtistProfileStore.shared
    @State private var selectedPostedArtwork: PostedArtwork?  // ProductDetailView로 이동하기 위한 PostedArtwork
    @State private var selectedRandomArtist: String?  // 랜덤 작가 상세로 이동하기 위한 작가 이름
    @State private var showRandomArtistDetail = false
    @State private var showProductEnter = false
    @State private var showGuestBook = false
    
    var body: some View {
        ZStack {
            Color.shapeDefault
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                DetailStickyNavBar(
                    artistName: profileStore.profile.nickname.isEmpty ? "" : profileStore.profile.nickname,
                    description: profileStore.profile.description,
                    profileImageUrl: profileStore.profile.profileImageUrl ?? artwork.artistImageUrl,
                    buttonType: .editAndRegister,
                    onDismiss: { dismiss() }
                )
                
                // 프로필 + 버튼 헤더 (Figma 구조 + 내부 회색 shape 포함)
                let isProfileEmpty = profileStore.profile.nickname.isEmpty && profileStore.profile.features.isEmpty
                DetailHeaderView(
                    profileImageUrl: profileStore.profile.profileImageUrl ?? artwork.artistImageUrl,
                    artistName: profileStore.profile.nickname.isEmpty ? "" : profileStore.profile.nickname,
                    tags: profileStore.profile.features,
                    description: profileStore.profile.description,
                    buttonType: .editAndRegister,
                    socialMediaLinks: getSocialMediaLinks(),
                    isProfileEmpty: isProfileEmpty,
                    onRegisterTap: {
                        selectedPostedArtwork = nil
                        showProductEnter = true
                    },
                    onGuestBookTap: {
                        selectedPostedArtwork = nil
                        showGuestBook = true
                    }
                )
                                
                // 작품 목록
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        let currentNickname = profileStore.profile.nickname
                        let postedArtworks = artworkStore.getArtworksByArtist(currentNickname)
                        
                        if postedArtworks.isEmpty {
                            Text("등록된 작품이 없습니다.")
                                .font(Typography.Body2.font)
                                .foregroundColor(.foregroundTertiary)
                                .padding(.vertical, 40)
                        } else {
                            ForEach(postedArtworks) { (postedArtwork: PostedArtwork) in
                                VStack(spacing: 0) {
                                    if let firstId = postedArtworks.first?.id, postedArtwork.id != firstId {
                                        Rectangle()
                                            .fill(Color.borderPrimary)
                                            .frame(height: 1)
                                    }
                                    DetailPostItem(
                                        imageUrl: postedArtwork.imageUrls.first ?? artwork.imageUrl,
                                        title: postedArtwork.title,
                                        year: postedArtwork.year,
                                        medium: postedArtwork.medium,
                                        size: postedArtwork.size,
                                        artistName: postedArtwork.artistName,
                                        artistImageUrl: postedArtwork.artistImageUrl,
                                        isArtist: true,
                                        artwork: postedArtwork,
                                        onDelete: {
                                            artworkStore.deleteArtwork(postedArtwork)
                                        },
                                        onImageTap: {
                                            selectedPostedArtwork = postedArtwork
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)   // 회색바(8pt) 이후 24pt 간격
                    
                    Spacer()
                        .frame(height: 34)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            navigateToRandomArtist()
                        }) {
                            ZStack {
                                Image("icon.multiple")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 56, height: 56)
                                
                                Image("icon.balloon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
                .allowsHitTesting(true)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedPostedArtwork) { postedArtwork in
            ProductDetailView(artwork: postedArtwork)
                .onDisappear {
                    selectedPostedArtwork = nil
                }
        }
        .fullScreenCover(isPresented: $showRandomArtistDetail) {
            if let artistName = selectedRandomArtist {
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
        .fullScreenCover(isPresented: $showGuestBook) {
            GuestBookView(
                artistName: profileStore.profile.nickname.isEmpty ? artwork.artistName : profileStore.profile.nickname,
                isArtistViewing: true
            )
        }
        .fullScreenCover(isPresented: $showProductEnter) {
            ProductEnterView()
        }
    }
    
    // 소셜 미디어 링크 가져오기 (입력한 것만)
    private func getSocialMediaLinks() -> [String: String] {
        var links: [String: String] = [:]
        let profile = profileStore.profile
        
        if let instagram = profile.instagramLink, !instagram.isEmpty {
            links["instagram"] = instagram
        }
        if let youtube = profile.youtubeLink, !youtube.isEmpty {
            links["youtube"] = youtube
        }
        if let kakao = profile.kakaoLink, !kakao.isEmpty {
            links["kakao"] = kakao
        }
        if let email = profile.emailLink, !email.isEmpty {
            links["email"] = email
        }
        
        return links
    }
    
    // 랜덤 작가로 이동
    private func navigateToRandomArtist() {
        guard !profileStore.profile.nickname.isEmpty else {
            return
        }
        
        let currentArtistName = profileStore.profile.nickname
        let allArtists = artworkStore.getAllArtists()
        
        // 현재 작가를 제외한 다른 작가 목록
        let otherArtists = allArtists.filter { $0 != currentArtistName && !$0.isEmpty }
        
        // 다른 작가가 있는 경우에만 랜덤 선택
        if !otherArtists.isEmpty {
            let randomArtist = otherArtists.randomElement()!
            selectedRandomArtist = randomArtist
            showRandomArtistDetail = true
        }
    }
}

#Preview {
    DetailArtistView(artwork: ArtworkData(
        imageUrl: "http://localhost:3845/assets/22e93cd86b1c87caed791020ed9df8aa4ee4f0e4.png",
        title: "오전 햇살",
        description: "혼란한 공간의 구원자라는 존재를 기존의 상식과는 다르게 비틀어 반영웅적인 이미지를 만들다.",
        year: "2023",
        medium: "아크릴 캔버스",
        size: "35.8 cm X 42.6 cm",
        artistName: "아리아",
        artistImageUrl: "http://localhost:3845/assets/169b8964c25d75d580e2c8f4c68f9d2c8ecc09e0.png"
    ))
}
