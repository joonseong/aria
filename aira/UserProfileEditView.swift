//
//  UserProfileEditView.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import PhotosUI
import UIKit

struct UserProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userProfileStore = UserProfileStore.shared
    
    @State private var selectedImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var nickname: String = ""
    @State private var isSaving = false
    
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
                    
                    Text("프로필 수정")
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
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Image Upload Section
                        VStack(spacing: 16) {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 354, height: 240)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else if let profileImageUrl = userProfileStore.profile.profileImageUrl, !profileImageUrl.isEmpty {
                                Group {
                                    if profileImageUrl.hasPrefix("/") {
                                        if let uiImage = UIImage(contentsOfFile: profileImageUrl) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle()
                                                .fill(Color.shapeDepth2)
                                        }
                                    } else {
                                        AsyncImage(url: URL(string: ImageHelper.urlWithCacheBusting(profileImageUrl))) { phase in
                                            switch phase {
                                            case .empty, .failure:
                                                Rectangle()
                                                    .fill(Color.shapeDepth2)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            @unknown default:
                                                Rectangle()
                                                    .fill(Color.shapeDepth2)
                                            }
                                        }
                                    }
                                }
                                .frame(width: 354, height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.foregroundTertiary)
                                        
                                        Text("이미지 업로드")
                                            .font(Typography.Body4.font)
                                            .foregroundColor(.foregroundTertiary)
                                        
                                        Text("이미지 선택")
                                            .font(Typography.Body3.font)
                                            .foregroundColor(.foregroundInvertPrimary)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 12)
                                            .background(Color.shapePrimary)
                                            .cornerRadius(100)
                                    }
                                    .frame(width: 354, height: 240)
                                    .background(Color.shapeDepth1)
                                    .cornerRadius(16)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 52)
                        .padding(.horizontal, 24)
                        
                        // Nickname Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("닉네임")
                                .font(Typography.Body3.font)
                                .foregroundColor(.foregroundPrimary)
                            
                            TextField("닉네임을 입력해주세요", text: $nickname)
                                .font(Typography.Body2.font)
                                .foregroundColor(.foregroundPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.shapeDefault)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.borderPrimary, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 32)
                    }
                }
                
                // Submit Button (Primary 1개)
                AiraButton("저장하기", style: .primary, isEnabled: canSave && !isSaving) {
                    Task { await saveProfile() }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            SingleImagePicker(selectedImage: $selectedImage)
        }
        .onAppear {
            nickname = userProfileStore.profile.nickname
        }
    }
    
    private var canSave: Bool {
        !nickname.isEmpty
    }
    
    private func saveProfile() async {
        isSaving = true
        defer { isSaving = false }
        
        var profileImageUrl: String? = userProfileStore.profile.profileImageUrl
        
        if let image = selectedImage {
            do {
                let url = try await APIClient.shared.uploadImageToSupabaseStorage(
                    image,
                    bucket: SupabaseStorageBucket.profileImages,
                    fileName: UUID().uuidString + ".jpg"
                )
                profileImageUrl = url
            } catch {
                AppLogger.debug("⚠️ 프로필 이미지 업로드 실패, 기존 이미지 유지")
                AppLogger.debug("   localizedDescription: \(error.localizedDescription)")
                AppLogger.debug("   String(describing:): \(String(describing: error))")
            }
        }
        
        userProfileStore.updateProfile(
            profileImageUrl: profileImageUrl,
            nickname: nickname
        )
        
        await MainActor.run {
            dismiss()
        }
    }
}


