//
//  UserProfileView.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import UIKit

struct UserProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userProfileStore = UserProfileStore.shared
    @StateObject private var followStore = FollowStore.shared
    @StateObject private var artworkStore = ArtworkStore.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showProfileEdit = false
    @State private var selectedArtist: String?
    @State private var showArtistDetail = false
    @State private var showWithdrawalAlert = false
    
    var body: some View {
        ZStack {
            Color.shapeDefault
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Header
                HStack(spacing: 8) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon.back")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .foregroundColor(.foregroundPrimary)
                    }
                    
                    Text("프로필")
                        .font(Typography.Heading3.font)
                        .foregroundColor(.foregroundPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(height: 56)
                .background(Color.shapeDefault)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Header
                    VStack(spacing: 16) {
                        // Profile Image
                        Group {
                            if let profileImageUrl = userProfileStore.profile.profileImageUrl, !profileImageUrl.isEmpty {
                                // local:// 접두사 제거
                                let cleanUrl = profileImageUrl.hasPrefix("local://") ? String(profileImageUrl.dropFirst(8)) : profileImageUrl
                                
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
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        
                        // Nickname
                        Text(userProfileStore.profile.nickname.isEmpty ? "{Nickname}" : userProfileStore.profile.nickname)
                            .font(Typography.Heading3.font)
                            .foregroundColor(.foregroundPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 32)
                    .padding(.bottom, 16)
                    
                    // Buttons (Primary 1개: 프로필 수정하기, Secondary: 작가 신청하기)
                    HStack(spacing: 8) {
                        AriaButton("작가 신청하기", style: .secondary) {
                            // TODO: 외부 링크로 연결
                        }
                        
                        AriaButton("프로필 수정하기", style: .primary) {
                            showProfileEdit = true
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.shapeDepth1)
                        .frame(height: 8)
                    
                    // 팔로우한 작가 리스트 (탭 제거)
                    VStack(spacing: 16) {
                        // 실제로 팔로우한 작가만 필터링 (isFollowing으로 확인)
                        let validFollowedArtists = followStore.followedArtists.filter { artist in
                            followStore.isFollowing(artistName: artist.artistName)
                        }
                        
                        if validFollowedArtists.isEmpty {
                            Text("팔로우한 작가가 없습니다.")
                                .font(Typography.Body2.font)
                                .foregroundColor(.foregroundTertiary)
                                .padding(.vertical, 40)
                        } else {
                            // 3단 그리드로 표시
                            let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)
                            
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(validFollowedArtists) { artist in
                                    Button(action: {
                                        selectedArtist = artist.artistName
                                        showArtistDetail = true
                                    }) {
                                        VStack(spacing: 8) {
                                            // 작가 프로필 이미지
                                            ZStack(alignment: .topTrailing) {
                                                // 프로필 이미지 - SmartImageView 사용
                                                SmartImageView(imageUrl: artist.artistImageUrl ?? "", placeholder: Color.shapeDepth2)
                                                .frame(width: 106, height: 106)
                                                .clipShape(Circle())
                                                
                                                // 새 작품 개수 뱃지
                                                let newArtworkCount = artworkStore.getArtworksByArtist(artist.artistName).count
                                                if newArtworkCount > 0 {
                                                    Text("\(newArtworkCount > 99 ? "99+" : "\(newArtworkCount)")")
                                                        .font(Typography.Caption2.font)
                                                        .foregroundColor(.foregroundInvertPrimary)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 4)
                                                        .background(Color.shapePrimary)
                                                        .cornerRadius(100)
                                                        .offset(x: 8, y: -8)
                                                }
                                            }
                                            
                                            // 작가 닉네임
                                            Text(artist.artistName)
                                                .font(Typography.Body4.font)
                                                .foregroundColor(.foregroundPrimary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 32)
                    .padding(.bottom, 16)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.shapeDepth1)
                        .frame(height: 8)
                        .padding(.top, 16)
                    
                    // 회원탈퇴, 로그아웃
                    VStack(spacing: 0) {
                        Button(action: {
                            showWithdrawalAlert = true
                        }) {
                            Text("회원탈퇴")
                                .font(Typography.Body2.font)
                                .foregroundColor(.foregroundSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                        }
                        .alert("회원탈퇴", isPresented: $showWithdrawalAlert) {
                            Button("취소", role: .cancel) { }
                            Button("탈퇴", role: .destructive) {
                                AccountManager.shared.deleteAccount()
                            }
                        } message: {
                            Text("정말 탈퇴하시겠습니까? 모든 데이터가 삭제되며 복구할 수 없습니다.")
                        }
                        
                        Button(action: {
                            authManager.logout()
                        }) {
                            Text("로그아웃")
                                .font(Typography.Body2.font)
                                .foregroundColor(.foregroundSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                        }
                    }
                    .padding(.top, 16)
                }
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showProfileEdit) {
            UserProfileEditView()
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
        .onAppear {
            followStore.cleanupUnfollowedArtists()
            Task { await userProfileStore.fetchProfileFromServer() }
        }
    }
}

