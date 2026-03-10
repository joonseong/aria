//
//  DetailSharedViews.swift
//  aria
//
//  DetailArtistView / DetailUserView 등에서 사용하는 공통 뷰 (스코프 인식 보장)
//

import SwiftUI

// Detail 화면 공통 Header — Sticky Nav는 상단 별도, 여기서는 커버 240pt + Description(24pt 패딩, 88pt 프로필 원형)
struct DetailHeaderView: View {
    let profileImageUrl: String
    let artistName: String
    let tags: [String]
    let description: String
    let buttonType: DetailButtonType
    var socialMediaLinks: [String: String] = [:]
    var isProfileEmpty: Bool = false
    var onRegisterTap: (() -> Void)? = nil
    var onGuestBookTap: (() -> Void)? = nil
    
    private let coverHeight: CGFloat = 240
    
    var body: some View {
        VStack(spacing: 0) {
            DetailHeaderProfileImageSection(profileImageUrl: profileImageUrl)
                .frame(height: coverHeight)
                .frame(maxWidth: .infinity)
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    DetailHeaderDescriptionSection(
                        artistName: artistName,
                        tags: tags,
                        description: description,
                        buttonType: buttonType,
                        socialMediaLinks: socialMediaLinks,
                        isProfileEmpty: isProfileEmpty,
                        profileImageUrl: profileImageUrl,
                        showProfileImageInRow: true,
                        onRegisterTap: onRegisterTap,
                        onGuestBookTap: onGuestBookTap
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
                .padding(.bottom, 24) // 버튼 아래 24pt
                .padding(.horizontal, 24)
                .background(Color.shapeDefault)
                
                // 버튼과 작품 목록 사이 Figma 회색 shape
                Rectangle()
                    .fill(Color.shapeDepth2)
                    .frame(height: 8) // 높이 8pt
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .clipped()
    }
}

// Detail Post Item Component
struct DetailPostItem: View {
    let imageUrl: String
    let title: String
    let year: String
    let medium: String
    let size: String
    let artistName: String
    let artistImageUrl: String
    var isArtist: Bool = false
    var artwork: PostedArtwork? = nil
    var onDelete: (() -> Void)? = nil
    var onImageTap: (() -> Void)? = nil
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                onImageTap?()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.shapeDepth2)
                        .frame(height: 354)
                    
                    SmartImageView(imageUrl: imageUrl, placeholder: Color.shapeDepth2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 354)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(height: 354)
            }
            .buttonStyle(PlainButtonStyle())
            
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Typography.Heading2.font)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text(year)
                            .font(Typography.Body4.font)
                            .foregroundColor(.foregroundTertiary)
                            .fixedSize()
                        
                        Circle()
                            .fill(Color.foregroundPlaceholder)
                            .frame(width: 3, height: 3)
                            .padding(.top, 6)
                        
                        Text(medium)
                            .font(Typography.Body4.font)
                            .foregroundColor(.foregroundTertiary)
                            .fixedSize()
                        
                        Circle()
                            .fill(Color.foregroundPlaceholder)
                            .frame(width: 3, height: 3)
                            .padding(.top, 6)
                        
                        Text(size)
                            .font(Typography.Body4.font)
                            .foregroundColor(.foregroundTertiary)
                            .fixedSize()
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if isArtist {
                    HStack {
                        Spacer()
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
            }
        }
        .alert("작품 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("이 작품을 삭제하시겠습니까?")
        }
    }
}
