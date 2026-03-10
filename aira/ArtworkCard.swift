//
//  ArtworkCard.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import UIKit

// 아트워크 카드
struct ArtworkCard: View {
    let imageUrl: String
    let title: String
    let description: String
    let year: String
    let medium: String
    let size: String
    let artistName: String
    let artistImageUrl: String
    var artworkId: UUID? = nil  // 좋아요 기능을 위한 작품 ID
    var hasShadow: Bool = false
    var onExhibitionTap: (() -> Void)? = nil
    var onImageTap: (() -> Void)? = nil  // 이미지 영역 클릭 시 콜백
    
    @StateObject private var likeStore = LikeStore.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // 이미지 영역 (클릭 가능)
            Button(action: {
                onImageTap?()
            }) {
                SmartImageView(imageUrl: imageUrl, placeholder: Color.shapeDepth2)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.width)
                    .clipped()
                    .cornerRadius(16, corners: [.topLeft, .topRight])
            }
            .buttonStyle(PlainButtonStyle())
            
            // 텍스트 영역
            VStack(alignment: .leading, spacing: 16) {
                // 제목과 설명
                VStack(alignment: .leading, spacing: 4) {
                    // 제목과 아이콘
                    HStack(spacing: 8) {
                        Text(title)
                            .font(Typography.Heading2.font)
                            .foregroundColor(Typography.Heading2.color)
                        
                        Spacer()
                        
                        // 공유 아이콘과 하트 아이콘
                        HStack(spacing: 16) {
                            Button(action: {
                                ShareHelper.shareArtwork(
                                    title: title,
                                    description: description,
                                    imageUrl: imageUrl
                                )
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.foregroundPrimary)
                                    .frame(width: 24, height: 24)
                            }
                            
                            Button(action: {
                                if let artworkId = artworkId {
                                    likeStore.toggleLike(artworkId: artworkId)
                                }
                            }) {
                                Image(systemName: likeStore.isLiked(artworkId: artworkId ?? UUID()) ? "heart.fill" : "heart")
                                    .font(.system(size: 20))
                                    .foregroundColor(likeStore.isLiked(artworkId: artworkId ?? UUID()) ? Color.shapePrimary : Color.foregroundPrimary)
                                    .frame(width: 28, height: 28)
                            }
                        }
                    }
                    
                    Text(description)
                        .font(Typography.Body2.font)
                        .foregroundColor(Typography.Body2.color)
                        .lineSpacing(4)
                }
                
                // 메타데이터
                HStack(spacing: 4) {
                    Text(year)
                        .font(Typography.Body4.font)
                        .foregroundColor(Typography.Body4.color)
                    
                    Circle()
                        .fill(Color.foregroundPlaceholder)
                        .frame(width: 3, height: 3)
                    
                    Text(medium)
                        .font(Typography.Body4.font)
                        .foregroundColor(Typography.Body4.color)
                    
                    Circle()
                        .fill(Color.foregroundPlaceholder)
                        .frame(width: 3, height: 3)
                    
                    Text(size)
                        .font(Typography.Body4.font)
                        .foregroundColor(Typography.Body4.color)
                }
                
                // 구분선
                Rectangle()
                    .fill(Color.borderPrimary)
                    .frame(height: 1)
                
                // 아티스트 정보
                HStack {
                    // 프로필 이미지 표시 (SmartImageView 사용)
                    SmartImageView(imageUrl: artistImageUrl, placeholder: Color.gray)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    
                    Text(artistName)
                        .font(Typography.Body4.font.weight(Typography.fontWeightBold))
                        .foregroundColor(Color.foregroundSecondary)
                    
                    Spacer()
                    
                    // 온라인 전시 가기 버튼
                    Button(action: {
                        onExhibitionTap?()
                    }) {
                        Text("온라인 전시 가기")
                            .font(Typography.Caption2.font)
                            .foregroundColor(Typography.Caption2.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.foregroundSecondary)
                            .cornerRadius(100)
                    }
                }
            }
            .padding(20)
            .padding(.horizontal, 4)
            .background(Color.white.opacity(0.64))
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

// CornerRadius 확장
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

