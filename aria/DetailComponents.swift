//
//  DetailComponents.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI

enum DetailButtonType {
    case guestBook        // "방명록 남기기" 버튼 1개 (detail - user)
    case editAndRegister  // "프로필 편집"과 "작품 등록" 버튼 2개 (detail - artist)
}

// 스크롤 시 헤더 배경 흰색 + 스티키용 오프셋
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Figma: h-[56px] px-[16px] py-[12px] gap-[8px] — 상세 화면 공통 헤더
struct DetailScreenHeader<Content: View>: View {
    let backgroundOpacity: Double
    @ViewBuilder let content: () -> Content
    
    private let barHeight: CGFloat = 56
    
    var body: some View {
        ZStack(alignment: .leading) {
            (backgroundOpacity > 0 ? Color.shapeDefault.opacity(backgroundOpacity) : Color.clear)
                .frame(maxWidth: .infinity)
                .frame(height: barHeight)
            HStack(spacing: 8) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: barHeight)
            .frame(maxWidth: .infinity)
        }
        .frame(height: barHeight)
    }
}

// 스티키 네비 바 — 작품상세(ProductDetailView)와 동일 구조: 56pt 헤더만 사용, 시스템 safe area 적용. Figma h-[56] px-[16] py-[12] gap-[8].
struct DetailStickyNavBar: View {
    let artistName: String
    let description: String
    let profileImageUrl: String
    let buttonType: DetailButtonType
    let onDismiss: () -> Void
    
    private let barHeight: CGFloat = 56
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.shapeDefault
                .frame(height: barHeight)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .top)
            
            DetailScreenHeader(backgroundOpacity: 1) {
                Button(action: onDismiss) {
                    Image("icon.back")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .foregroundColor(.foregroundPrimary)
                }
                Spacer(minLength: 0)
                HStack(spacing: 8) {
                    if buttonType == .editAndRegister {
                        ProfileEditButton()
                    }
                    Button(action: {
                        ShareHelper.shareProfile(
                            artistName: artistName,
                            description: description,
                            imageUrl: profileImageUrl
                        )
                    }) {
                        Image("icon.share")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.foregroundPrimary)
                    }
                    MoreButtonMenu(isMyProfile: buttonType == .editAndRegister)
                }
            }
            .frame(height: barHeight)
            .frame(maxWidth: .infinity)
        }
        .frame(height: barHeight)
        .frame(maxWidth: .infinity)
    }
}

// 프로필 이미지 전용 서브뷰 (ViewBuilder/Table 추론 충돌 방지)
struct DetailHeaderProfileImageSection: View {
        let profileImageUrl: String
        
        private var placeholderView: some View {
            ZStack {
                Color.shapeDepth2
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color.foregroundPlaceholder)
            }
        }
        
        var body: some View {
            profileImageContent
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .clipped()
                .ignoresSafeArea(edges: .top)
        }
        
        @ViewBuilder
        private var profileImageContent: some View {
            if profileImageUrl.isEmpty {
                placeholderView
            } else if profileImageUrl.hasPrefix("/") {
                if let uiImage = ImageHelper.loadLocalImage(profileImageUrl) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    placeholderView
                }
            } else if ImageHelper.isRemoteUrl(profileImageUrl), let url = URL(string: ImageHelper.urlWithCacheBusting(profileImageUrl)) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty, .failure:
                        placeholderView
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    @unknown default:
                        placeholderView
                    }
                }
                .onAppear { ImageHelper.logImageUrlIfNeeded(profileImageUrl, context: "DetailHeader 프로필") }
            } else {
                placeholderView
            }
        }
    }
    
    // Description 영역 서브뷰 (ViewBuilder/Table 추론 충돌 방지)
    // showProfileImageInRow: false면 프로필 이미지는 상위에서 별도 레이어로 그림
    struct DetailHeaderDescriptionSection: View {
        let artistName: String
        let tags: [String]
        let description: String
        let buttonType: DetailButtonType
        let socialMediaLinks: [String: String]
        let isProfileEmpty: Bool
        let profileImageUrl: String
        var showProfileImageInRow: Bool = true
        var onRegisterTap: (() -> Void)? = nil
        var onGuestBookTap: (() -> Void)? = nil
        
        @StateObject private var followStore = FollowStore.shared
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                authorRow
                if !description.isEmpty {
                    Text(description)
                        .font(Typography.Body2.font)
                        .foregroundColor(.foregroundSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                socialMediaRow
                bottomButtons
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        private var authorRow: some View {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        if isProfileEmpty && artistName.isEmpty {
                            Text("닉네임을 설정해주세요 작가")
                                .font(Typography.Heading2.font)
                                .foregroundColor(.foregroundPlaceholder)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else {
                            Text("\(artistName) 작가")
                                .font(Typography.Heading2.font)
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        if !tags.isEmpty {
                            DetailHeaderTagsView(tags: tags)
                        }
                    }
                    HStack(spacing: 8) {
                        Button(action: {
                            followStore.toggleFollow(artistName: artistName, artistImageUrl: profileImageUrl)
                        }) {
                            HStack(spacing: 4) {
                                Text("\(followStore.getFollowCount(for: artistName))")
                                    .font(Typography.Caption2.font.weight(Typography.fontWeightBold))
                                Text("Follow")
                                    .font(Typography.Caption2.font)
                            }
                            .foregroundColor(followStore.isFollowing(artistName: artistName) ? .foregroundSecondary : .foregroundInvertPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(followStore.isFollowing(artistName: artistName) ? Color.shapeDefault : Color.foregroundSecondary)
                            .cornerRadius(100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(followStore.isFollowing(artistName: artistName) ? Color.borderPrimary : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.top, 0)
                if showProfileImageInRow {
                    Spacer(minLength: 8)
                    SmartImageView(imageUrl: profileImageUrl, placeholder: Color.shapeDepth2)
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: showProfileImageInRow ? 88 : 0)
        }
        
        @ViewBuilder
        private var socialMediaRow: some View {
            if !socialMediaLinks.isEmpty {
                HStack(spacing: 8) {
                    if let link = socialMediaLinks["instagram"] {
                        SocialMediaButton(iconName: "icon.sns.instagram", link: link)
                    }
                    if let link = socialMediaLinks["youtube"] {
                        SocialMediaButton(iconName: "icon.sns.youtube", link: link)
                    }
                    if let link = socialMediaLinks["kakao"] {
                        SocialMediaButton(iconName: "icon.sns.kakaotalk", link: link)
                    }
                    if let link = socialMediaLinks["email"] {
                        SocialMediaButton(iconName: "icon.sns.email", link: "mailto:\(link)")
                    }
                }
            }
        }
        
        @ViewBuilder
        private var bottomButtons: some View {
            switch buttonType {
            case .guestBook:
                AriaButton("방명록 남기기", style: .primary) {
                    onGuestBookTap?()
                }
                .frame(maxWidth: .infinity)
            case .editAndRegister:
                HStack(spacing: 8) {
                    AriaButton("작품 등록", style: .secondary) {
                        onRegisterTap?()
                    }
                    .frame(maxWidth: .infinity)
                    
                    AriaButton("방명록 보기", style: .primary) {
                        onGuestBookTap?()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    
    // Tags 한 줄 표시 (ForEach 타입 명확화)
    struct DetailHeaderTagsView: View {
        let tags: [String]
        
        var body: some View {
            HStack(spacing: 4) {
                ForEach(Array(zip(tags.indices, tags)), id: \.0) { index, tag in
                    if index > 0 {
                        Circle()
                            .fill(Color.foregroundPlaceholder)
                            .frame(width: 3, height: 3)
                    }
                    Text(tag)
                        .font(Typography.Body4.font)
                        .foregroundColor(.foregroundTertiary)
                }
            }
        }
    }
    
    // 프로필 편집 버튼 (Follow 버튼 옆에 배치)
    struct ProfileEditButton: View {
        @State private var showProfileEdit = false
        
        var body: some View {
            Button(action: {
                showProfileEdit = true
            }) {
                Text("프로필 편집")
                    .font(Typography.Caption2.font)
                    .foregroundColor(.foregroundSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.shapeDefault)
                    .cornerRadius(100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 100)
                            .stroke(Color.borderPrimary, lineWidth: 1)
                    )
            }
            .fullScreenCover(isPresented: $showProfileEdit) {
                ProfileEditView()
            }
        }
    }
    
    // 작품 등록 버튼 (Primary) — Artist만 표시 (canUpload)
    struct ProductRegisterButton: View {
        @State private var showProductEnter = false
        @StateObject private var authManager = AuthenticationManager.shared
        
        var body: some View {
            Group {
                if authManager.canUpload() {
                    AriaButton("작품 등록", style: .secondary) {
                        showProductEnter = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showProductEnter) {
                ProductEnterView()
            }
        }
    }
    
    // 방명록 보기 버튼 (Secondary)
    struct GuestBookViewButton: View {
        @State private var showGuestBook = false
        
        var body: some View {
            AriaButton("방명록 보기", style: .primary) {
                showGuestBook = true
            }
            .fullScreenCover(isPresented: $showGuestBook) {
                GuestBookView(
                    artistName: ArtistProfileStore.shared.profile.nickname,
                    isArtistViewing: true
                )
            }
        }
    }
    
    // More Button Menu Component
    struct MoreButtonMenu: View {
        /// true: 내 프로필(작가) → 로그아웃/회원탈퇴, false: 다른 사람 프로필 → 신고하기
        var isMyProfile: Bool = false
        
        @Environment(\.dismiss) private var dismiss
        @State private var showActionSheet = false
        @State private var showWithdrawalAlert = false
        @StateObject private var authManager = AuthenticationManager.shared
        
        var body: some View {
            Button(action: {
                showActionSheet = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(.foregroundPrimary)
                    .frame(width: 28, height: 28)
            }
            .confirmationDialog("더보기", isPresented: $showActionSheet, titleVisibility: .visible) {
                if isMyProfile {
                    Button("로그아웃", role: .none) {
                        showActionSheet = false
                        dismiss()
                        authManager.logout()
                    }
                    Button("회원탈퇴", role: .destructive) {
                        showActionSheet = false
                        showWithdrawalAlert = true
                    }
                } else {
                    Button("신고하기", role: .destructive) {
                        // TODO: 신고하기 기능 구현
                    }
                }
                Button("취소", role: .cancel) { }
            }
            .alert("회원탈퇴", isPresented: $showWithdrawalAlert) {
                Button("취소", role: .cancel) { }
                Button("탈퇴", role: .destructive) {
                    dismiss()
                    AccountManager.shared.deleteAccount()
                }
            } message: {
                Text("정말 탈퇴하시겠습니까? 모든 데이터가 삭제되며 복구할 수 없습니다.")
            }
        }
    }
    
    // Social Media Button Component
    struct SocialMediaButton: View {
        let iconName: String
        var link: String? = nil
        
        var body: some View {
            Button(action: {
                if let link = link, let url = URL(string: link) {
                    UIApplication.shared.open(url)
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.shapeDefault)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.borderPrimary, lineWidth: 1)
                        )
                    
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
            }
        }
    }

