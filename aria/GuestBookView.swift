//
//  GuestBookView.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import UIKit

struct GuestBookView: View {
    let artistName: String  // 방명록을 받는 작가 이름
    let isArtistViewing: Bool  // 작가가 본인의 방명록을 보는지 여부
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var guestBookStore = GuestBookStore.shared
    @StateObject private var userProfileStore = UserProfileStore.shared
    @StateObject private var artistProfileStore = ArtistProfileStore.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var messageText: String = ""
    
    @State private var entries: [GuestBookEntry] = []
    
    var currentUserName: String {
        if authManager.userRole == .artist {
            return artistProfileStore.profile.nickname.isEmpty ? "작가" : artistProfileStore.profile.nickname
        } else {
            return userProfileStore.profile.nickname.isEmpty ? "유저" : userProfileStore.profile.nickname
        }
    }
    
    var currentUserImageUrl: String? {
        if authManager.userRole == .artist {
            return artistProfileStore.profile.profileImageUrl
        } else {
            return userProfileStore.profile.profileImageUrl
        }
    }
    
    var body: some View {
        ZStack {
            Color.shapeDefault
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon.back")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .foregroundColor(.foregroundPrimary)
                    }
                    
                    Spacer()
                    
                    Text("방명록")
                        .font(Typography.Heading3.font)
                        .foregroundColor(.foregroundPrimary)
                    
                    Spacer()
                    
                    // Placeholder for alignment
                    Color.clear
                        .frame(width: 28, height: 28)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(height: 56)
                
                // Messages List
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(entries) { entry in
                            GuestBookEntryView(
                                entry: entry,
                                isCurrentUser: entry.authorName == currentUserName,
                                currentUserImageUrl: currentUserImageUrl
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 32)
                    .padding(.bottom, 16)
                }
                
                // Input Section (터치 영역 확대)
                HStack(spacing: 10) {
                    TextField(
                        isArtistViewing ? "응원한 내용에 답변을 남겨주세요" : "작가에게 응원의 한마디를 남겨주세요.",
                        text: $messageText,
                        axis: .vertical
                    )
                    .font(Typography.Body4.font)
                    .foregroundColor(.foregroundPrimary)
                    .lineLimit(1...10)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(Color.shapeDefault)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.borderPrimary, lineWidth: 1)
                    )
                    .contentShape(Rectangle()) // 터치 영역 확대
                    
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16))
                            .foregroundColor(ButtonStyleToken.primaryForeground)
                            .frame(width: 48, height: 48)
                            .background(messageText.isEmpty ? ButtonStyleToken.disabledBackground : ButtonStyleToken.primaryBackground)
                            .clipShape(Circle())
                    }
                    .disabled(messageText.isEmpty)
                    .contentShape(Circle()) // 터치 영역 확대
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .contentShape(Rectangle()) // 전체 영역 터치 가능
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 화면 진입 시 서버에서 방명록 가져오기
            Task {
                await guestBookStore.fetchEntriesForArtist(artistName)
                await MainActor.run {
                    entries = guestBookStore.getEntriesForArtist(artistName)
                }
            }
        }
        .onChange(of: guestBookStore.entries.count) { oldValue, newValue in
            // 방명록이 변경되면 업데이트
            entries = guestBookStore.getEntriesForArtist(artistName)
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let isArtist = authManager.userRole == .artist
        let entry = GuestBookEntry(
            artistName: artistName,
            authorName: currentUserName,
            authorImageUrl: currentUserImageUrl,
            content: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
            isArtist: isArtist
        )
        
        // 서버에 추가
        Task {
            await guestBookStore.addEntry(entry)
            await MainActor.run {
                entries = guestBookStore.getEntriesForArtist(artistName)
                messageText = ""
            }
        }
    }
}

struct GuestBookEntryView: View {
    let entry: GuestBookEntry
    let isCurrentUser: Bool
    let currentUserImageUrl: String?
    
    var body: some View {
        VStack(spacing: 8) {
            // Author Info
            HStack {
                if isCurrentUser {
                    Spacer()
                    Text(entry.authorName)
                        .font(Typography.Body4.font)
                        .foregroundColor(.foregroundPrimary)
                    
                    // Profile Image - SmartImageView 사용
                    SmartImageView(imageUrl: currentUserImageUrl ?? "", placeholder: Color.shapeDepth2)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    // Profile Image - SmartImageView 사용
                    SmartImageView(imageUrl: entry.authorImageUrl ?? "", placeholder: Color.shapeDepth2)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    
                    Text(entry.authorName)
                        .font(Typography.Body4.font)
                        .foregroundColor(.foregroundPrimary)
                    
                    Spacer()
                }
            }
            
            // Message Bubble
            HStack(alignment: .bottom, spacing: 8) {
                if isCurrentUser {
                    // 내가 쓴 글: 오른쪽 정렬
                    Text(entry.createdAt.timeAgoString())
                        .font(Typography.Caption2.font)
                        .foregroundColor(.foregroundTertiary)
                    
                    Text(entry.content)
                        .font(Typography.Body2.font)
                        .foregroundColor(.foregroundInvertPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.shapePrimary)
                        .cornerRadius(32, corners: isCurrentUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                } else {
                    // 다른 사람이 쓴 글: 왼쪽 정렬
                    Text(entry.content)
                        .font(Typography.Body2.font)
                        .foregroundColor(.foregroundPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(entry.isArtist ? Color.shapeDeco : Color.shapeDepth1)
                        .cornerRadius(32, corners: [.topLeft, .topRight, .bottomRight])
                    
                    Text(entry.createdAt.timeAgoString())
                        .font(Typography.Caption2.font)
                        .foregroundColor(.foregroundTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
        }
    }
}

