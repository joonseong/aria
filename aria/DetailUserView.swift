//
//  DetailUserView.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI

struct DetailUserView: View {
    let artwork: ArtworkData
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var artworkStore = ArtworkStore.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var profileStore = ArtistProfileStore.shared
    @StateObject private var userProfileStore = UserProfileStore.shared
    @State private var selectedPostedArtwork: PostedArtwork?  // ProductDetailView로 이동하기 위한 PostedArtwork
    @State private var showGuestBook = false
    @State private var selectedRandomArtist: String?  // 랜덤 작가 상세로 이동하기 위한 작가 이름
    @State private var showRandomArtistDetail = false
    @State private var showProductEnter = false
    @State private var displayedArtwork: ArtworkData  // 표시할 작품 데이터 (프로필 변경 시 업데이트)
    @State private var viewedArtistProfile: ArtistProfile?  // 현재 보고 있는 작가의 프로필 (다른 작가 조회용)
    
    init(artwork: ArtworkData) {
        self.artwork = artwork
        _displayedArtwork = State(initialValue: artwork)
    }
    
    var body: some View {
        // 현재 로그인한 작가의 프로필인지 확인
        // 닉네임: artist_profiles 우선, 비어 있으면 user_profiles 폴백 (서버에 user_profiles만 있는 경우 대비)
        let currentArtistName = profileStore.profile.nickname.isEmpty
            ? userProfileStore.profile.nickname
            : profileStore.profile.nickname
        // "current_artist" 플레이스홀더를 사용한 경우 또는 artistName이 현재 작가의 닉네임과 일치하면 현재 작가로 인식
        let isCurrentArtist = authManager.userRole == .artist && (
            displayedArtwork.artistName == "current_artist" ||
            (!currentArtistName.isEmpty && displayedArtwork.artistName == currentArtistName) ||
            (currentArtistName.isEmpty && displayedArtwork.artistName.isEmpty)
        )
        let isProfileEmpty = profileStore.profile.nickname.isEmpty && profileStore.profile.features.isEmpty
        
        // 표시할 작가 프로필 정보 (현재 작가면 profileStore + user_profiles 폴백, 아니면 viewedArtistProfile)
        let displayProfile = isCurrentArtist ? profileStore.profile : (viewedArtistProfile ?? ArtistProfile())
        
        // 닉네임: artist_profiles 우선, 비어 있으면 user_profiles 값 사용
        let displayNickname = isCurrentArtist && displayProfile.nickname.isEmpty
            ? userProfileStore.profile.nickname
            : displayProfile.nickname
        
        // 프로필 이미지 URL
        // 1) artist_profiles.profileImageUrl
        // 2) (현재 작가일 때) user_profiles.profileImageUrl
        // 3) 작품에 저장된 artistImageUrl
        let resolvedProfileImageUrl: String = {
            if let url = displayProfile.profileImageUrl, !url.isEmpty {
                return url
            }
            if isCurrentArtist, let url = userProfileStore.profile.profileImageUrl, !url.isEmpty {
                return url
            }
            if !displayedArtwork.artistImageUrl.isEmpty {
                return displayedArtwork.artistImageUrl
            }
            return ""
        }()
        
        // 작가 설명 가져오기
        let artistDescription = displayProfile.description.isEmpty ? "" : displayProfile.description
        
        return ZStack {
            Color.shapeDefault
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                let w = geometry.size.width
                return VStack(spacing: 0) {
                    DetailStickyNavBar(
                        artistName: displayNickname.isEmpty ? displayedArtwork.artistName : displayNickname,
                        description: artistDescription,
                        profileImageUrl: resolvedProfileImageUrl,
                        buttonType: isCurrentArtist ? .editAndRegister : .guestBook,
                        onDismiss: { dismiss() }
                    )
                    
                    ZStack(alignment: .bottomTrailing) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                DetailHeaderView(
                                    profileImageUrl: resolvedProfileImageUrl,
                                    artistName: displayNickname.isEmpty ? displayedArtwork.artistName : displayNickname,
                                    tags: displayProfile.features.isEmpty ? [] : displayProfile.features,
                                    description: artistDescription,
                                    buttonType: isCurrentArtist ? .editAndRegister : .guestBook,
                                    socialMediaLinks: isCurrentArtist ? getSocialMediaLinks() : getSocialMediaLinks(from: displayProfile),
                                    isProfileEmpty: isCurrentArtist && isProfileEmpty,
                                    onRegisterTap: isCurrentArtist ? {
                                        selectedPostedArtwork = nil
                                        showProductEnter = true
                                    } : nil,
                                    onGuestBookTap: {
                                        selectedPostedArtwork = nil
                                        showGuestBook = true
                                    }
                                )
                                .frame(width: w)
                        
                            VStack(spacing: 32) {
                            Group {
                                let searchArtistName = isCurrentArtist ? currentArtistName : (displayedArtwork.artistName == "current_artist" ? currentArtistName : displayedArtwork.artistName)
                                let postedArtworks = artworkStore.getArtworksByArtist(searchArtistName)
                                
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
                                                imageUrl: postedArtwork.imageUrls.first ?? displayedArtwork.imageUrl,
                                                title: postedArtwork.title,
                                                year: postedArtwork.year,
                                                medium: postedArtwork.medium,
                                                size: postedArtwork.size,
                                                artistName: postedArtwork.artistName,
                                                artistImageUrl: postedArtwork.artistImageUrl,
                                                isArtist: isCurrentArtist,
                                                artwork: isCurrentArtist ? postedArtwork : nil,
                                                onDelete: isCurrentArtist ? {
                                                    artworkStore.deleteArtwork(postedArtwork)
                                                } : nil,
                                                onImageTap: {
                                                    selectedPostedArtwork = postedArtwork
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 24) // 회색바(8pt) 이후 24pt 간격
                        
                            Spacer()
                                .frame(height: 34)
                        }
                        .frame(width: w)
                    }
                    .frame(width: w)
                    .clipped()
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            if isCurrentArtist {
                        // 작가인 경우: 랜덤 작가 이동 버튼 (동그란 플로팅 버튼)
                        Button(action: {
                            navigateToRandomArtist()
                        }) {
                            Circle()
                                .fill(Color.shapePrimary)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image("icon.balloon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 32)
                                        .foregroundColor(.white)
                                )
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    } else {
                        // 일반 유저인 경우: 방명록 남기기 버튼
                        Button(action: {
                            showGuestBook = true
                        }) {
                            Circle()
                                .fill(Color.shapePrimary)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image("icon.balloon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 32)
                                        .foregroundColor(.white)
                                )
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                            }
                        }
                    }
                    .allowsHitTesting(true)
                }
            }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedPostedArtwork) { postedArtwork in
            ProductDetailView(artwork: postedArtwork)
                .onDisappear {
                    selectedPostedArtwork = nil
                }
        }
        .fullScreenCover(isPresented: $showGuestBook) {
            GuestBookView(
                artistName: displayedArtwork.artistName,
                isArtistViewing: isCurrentArtist
            )
        }
        .fullScreenCover(isPresented: $showProductEnter) {
            ProductEnterView()
        }
        .onChange(of: profileStore.profile.nickname) { oldValue, newNickname in
            // 프로필 닉네임이 변경되면 현재 작가의 첫 번째 작품으로 업데이트
            if authManager.userRole == .artist && !newNickname.isEmpty {
                let artworks = artworkStore.getArtworksByArtist(newNickname)
                if let firstArtwork = artworks.first {
                    displayedArtwork = firstArtwork.toArtworkData()
                } else {
                    // 작품이 없으면 빈 작품 데이터로 업데이트
                    displayedArtwork = ArtworkData(
                        imageUrl: "",
                        title: "",
                        description: "",
                        year: "",
                        medium: "",
                        size: "",
                        artistName: newNickname,
                        artistImageUrl: profileStore.profile.profileImageUrl ?? ""
                    )
                }
            }
        }
        .onAppear {
            // 다른 작가의 프로필을 볼 때 서버에서 프로필 정보 가져오기
            let currentArtistName = profileStore.profile.nickname.isEmpty ? "" : profileStore.profile.nickname
            let isCurrent = authManager.userRole == .artist && !currentArtistName.isEmpty && displayedArtwork.artistName == currentArtistName
            
            if !isCurrent && !displayedArtwork.artistName.isEmpty {
                Task {
                    if let profile = await profileStore.fetchProfileByNickname(displayedArtwork.artistName) {
                        await MainActor.run {
                            viewedArtistProfile = profile
                        }
                    }
                }
            }
        }
        .onChange(of: displayedArtwork.artistName) { oldValue, newArtistName in
            // 작가가 변경되면 해당 작가의 프로필 정보 가져오기
            let currentArtistName = profileStore.profile.nickname
            let isCurrent = authManager.userRole == .artist && !currentArtistName.isEmpty && newArtistName == currentArtistName
            
            if !isCurrent && !newArtistName.isEmpty {
                Task {
                    if let profile = await profileStore.fetchProfileByNickname(newArtistName) {
                        await MainActor.run {
                            viewedArtistProfile = profile
                        }
                    } else {
                        // 프로필이 없으면 빈 프로필로 설정
                        await MainActor.run {
                            viewedArtistProfile = ArtistProfile()
                        }
                    }
                }
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
    }
    
    // 소셜 미디어 링크 가져오기 (입력한 것만) - 현재 작가용
    private func getSocialMediaLinks() -> [String: String] {
        return getSocialMediaLinks(from: profileStore.profile)
    }
    
    // 소셜 미디어 링크 가져오기 (입력한 것만) - 일반 함수
    private func getSocialMediaLinks(from profile: ArtistProfile) -> [String: String] {
        var links: [String: String] = [:]
        
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
        // 프로필이 비어있으면 이동하지 않음
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
    DetailUserView(artwork: ArtworkData(
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
