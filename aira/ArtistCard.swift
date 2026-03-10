//
//  ArtistCard.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import UIKit

// 홈 작품 피드 카드 (Figma: 인스타그램 스타일, 이미지 좌우 풀 너비)
struct HomeArtworkFeedCard: View {
    let artwork: PostedArtwork
    var hasShadow: Bool = false
    var onImageTap: (() -> Void)? = nil
    var onArtistTap: (() -> Void)? = nil
    
    @StateObject private var likeStore = LikeStore.shared
    
    // 홈 피드용 프로필 이미지 URL
    // 1) artwork.artistImageUrl
    // 2) (현재 작가가 자신의 작품을 볼 때) ArtistProfileStore.profile.profileImageUrl
    private var artistImageUrl: String {
        if !artwork.artistImageUrl.isEmpty {
            return artwork.artistImageUrl
        }
        let auth = AuthenticationManager.shared
        let artistProfile = ArtistProfileStore.shared.profile
        let currentArtistName = artistProfile.nickname
        if auth.userRole == .artist,
           !currentArtistName.isEmpty,
           artwork.artistName == currentArtistName,
           let url = artistProfile.profileImageUrl,
           !url.isEmpty {
            return url
        }
        return ""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 이미지: 좌우 마진 없이 풀 너비 (인스타그램 스타일) - 고정 정사각형 영역
            Button(action: { onImageTap?() }) {
                SmartImageView(imageUrl: artwork.imageUrls.first ?? "", placeholder: Color.shapeDepth2)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.width)
                    .clipped()
            }
            .buttonStyle(PlainButtonStyle())
            
            // 프로필+작가명+공유+하트 / 작품 설명 (Figma: 이 구간만 좌우 패딩)
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button(action: { onArtistTap?() }) {
                        SmartImageView(imageUrl: artistImageUrl, placeholder: Color.gray)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
                    Button(action: { onArtistTap?() }) {
                        Text(artwork.artistName)
                            .font(Typography.Body4.font.weight(Typography.fontWeightBold))
                            .foregroundColor(Color.foregroundSecondary)
                    }
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
                            .frame(width: 24, height: 24)
                            .foregroundColor(.foregroundPrimary)
                    }
                    Button(action: { likeStore.toggleLike(artworkId: artwork.id) }) {
                        Image(systemName: likeStore.isLiked(artworkId: artwork.id) ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(likeStore.isLiked(artworkId: artwork.id) ? Color.shapePrimary : Color.foregroundPrimary)
                            .frame(width: 28, height: 28)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                if !artwork.description.isEmpty {
                    Text(artwork.description)
                        .font(Typography.Body2.font)
                        .foregroundColor(Typography.Body2.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                        .padding(.top, 0)
                        .padding(.bottom, 20)
                } else {
                    Spacer().frame(height: 20)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.64))
        }
    }
}

// 작가 카드 (홈 화면용 - 이전 레이아웃, 필요 시 유지)
struct ArtistCard: View {
    let artistName: String
    let artistImageUrl: String
    let representativeArtwork: PostedArtwork  // 대표 작품
    let artistDescription: String  // 작가 소개
    var hasShadow: Bool = false
    var onArtistTap: (() -> Void)? = nil  // 작가 카드 클릭 시 콜백
    var onFollowTap: (() -> Void)? = nil  // 팔로우 버튼 클릭 시 콜백
    
    @StateObject private var followStore = FollowStore.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // 이미지 영역 (클릭 가능 - 작가 상세로 이동)
            Button(action: {
                onArtistTap?()
            }) {
                SmartImageView(imageUrl: representativeArtwork.imageUrls.first ?? "", placeholder: Color.shapeDepth2)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .clipped()
                .cornerRadius(16, corners: [.topLeft, .topRight])
            }
            .buttonStyle(PlainButtonStyle())
            
            // 이미지 바로 아래: 썸네일+닉네임, 공유, 하트 버튼
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    // 프로필 이미지 (썸네일) - SmartImageView 사용
                    SmartImageView(imageUrl: artistImageUrl, placeholder: Color.gray)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    
                    // 닉네임
                    Text(artistName)
                        .font(Typography.Body4.font.weight(Typography.fontWeightBold))
                        .foregroundColor(Color.foregroundSecondary)
                    
                    Spacer()
                    
                    // 공유 버튼
                    Button(action: {
                        ShareHelper.shareProfile(
                            artistName: artistName,
                            description: artistDescription,
                            imageUrl: artistImageUrl
                        )
                    }) {
                        Image("icon.share")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.foregroundPrimary)
                    }
                    
                    // 팔로우 버튼 (하트 아이콘)
                    Button(action: {
                        followStore.toggleFollow(artistName: artistName, artistImageUrl: artistImageUrl)
                        onFollowTap?()
                    }) {
                        Image(systemName: followStore.isFollowing(artistName: artistName) ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(followStore.isFollowing(artistName: artistName) ? Color.shapePrimary : Color.foregroundPrimary)
                            .frame(width: 28, height: 28)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.64))
                
                // 구분선 (16px 아래, border/primary 컬러, 1px)
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 16)
                    
                    Rectangle()
                        .fill(Color.borderPrimary)
                        .frame(height: 1)
                }
                .background(Color.white.opacity(0.64))
                
                // 작가 소개 (description) - 구분선에서 16px 아래, 왼쪽 정렬, Fill
                if !artistDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                            .frame(height: 16)
                        
                        Text(artistDescription)
                            .font(Typography.Body2.font)
                            .foregroundColor(Typography.Body2.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                    .background(Color.white.opacity(0.64))
                } else {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 16)
                        Spacer()
                            .frame(height: 20)
                    }
                    .background(Color.white.opacity(0.64))
                }
            }
        }
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.borderPrimary, lineWidth: 1)
        )
        .shadow(
            color: hasShadow ? Shadow.art.color : .clear,
            radius: hasShadow ? Shadow.art.radius : 0,
            x: hasShadow ? Shadow.art.x : 0,
            y: hasShadow ? Shadow.art.y : 0
        )
    }
}

