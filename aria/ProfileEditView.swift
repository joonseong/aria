//
//  ProfileEditView.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import PhotosUI
import UIKit

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileStore = ArtistProfileStore.shared
    @StateObject private var userProfileStore = UserProfileStore.shared
    
    @State private var selectedImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var showingImageDeleteAlert = false
    @State private var nickname: String = ""
    @State private var features: [String] = ["", "", ""]  // 최대 3개
    @State private var description: String = ""
    @State private var instagramLink: String = ""
    @State private var youtubeLink: String = ""
    @State private var kakaoLink: String = ""
    @State private var emailLink: String = ""
    @State private var isSaving = false
    
    var body: some View {
        ZStack {
            Color.shapeDefault
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 8) {
                    // Back Button
                    Button(action: {
                        dismiss()
                    }) {
                        Image("icon.back")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .foregroundColor(.foregroundPrimary)
                    }
                    
                    Text("프로필 수정")
                        .font(Typography.Heading3.font)
                        .foregroundColor(.foregroundPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(height: 56)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // 프로필 이미지 업로드
                        VStack(spacing: 16) {
                            ZStack {
                                // 프로필 이미지 표시
                                if let profileImage = selectedImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else if let profileImageUrl = profileStore.profile.profileImageUrl {
                                    // 저장된 프로필 이미지
                                    Group {
                                        if profileImageUrl.hasPrefix("/") {
                                            if let uiImage = UIImage(contentsOfFile: profileImageUrl) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } else {
                                                Circle()
                                                    .fill(Color.shapeDepth2)
                                            }
                                        } else {
                                            AsyncImage(url: URL(string: ImageHelper.urlWithCacheBusting(profileImageUrl))) { phase in
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
                                        }
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                } else {
                                    // 기본 프로필 이미지
                                    Circle()
                                        .fill(Color.shapeDepth2)
                                        .frame(width: 120, height: 120)
                                }
                                
                                // 이미지 업로드 버튼
                                Button(action: {
                                    if selectedImage != nil || profileStore.profile.profileImageUrl != nil {
                                        // 이미지가 있으면 수정/삭제 옵션 표시
                                        showingImageDeleteAlert = true
                                    } else {
                                        showingImagePicker = true
                                    }
                                }) {
                                    Circle()
                                        .fill(Color.foregroundPrimary.opacity(0.8))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: selectedImage != nil || profileStore.profile.profileImageUrl != nil ? "pencil" : "camera.fill")
                                                .foregroundColor(.white)
                                                .font(.system(size: 18))
                                        )
                                }
                                .offset(x: 40, y: 40)
                            }
                            .frame(width: 120, height: 120)
                            
                            // 이미지 수정/삭제 옵션
                            if selectedImage != nil || profileStore.profile.profileImageUrl != nil {
                                HStack(spacing: 16) {
                                    Button(action: {
                                        showingImagePicker = true
                                    }) {
                                        Text("수정")
                                            .font(Typography.Body4.font)
                                            .foregroundColor(.foregroundPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.shapeDepth1)
                                            .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        selectedImage = nil
                                        profileStore.deleteProfileImage()
                                    }) {
                                        Text("삭제")
                                            .font(Typography.Body4.font)
                                            .foregroundColor(.foregroundPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.shapeDepth1)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.top, 24)
                        
                        // 닉네임 (필수)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("닉네임 *")
                                .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                .foregroundColor(.foregroundPrimary)
                            
                            TextField("닉네임을 입력해주세요.", text: $nickname)
                                .font(Typography.Body4.font)
                                .foregroundColor(.foregroundPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .background(Color.shapeDefault)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.borderPrimary, lineWidth: 1)
                                )
                                .cornerRadius(8)
                        }
                        
                        // 특징 (최대 3개, 필수 최소 1개)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("특징 * (최대 3개)")
                                .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                .foregroundColor(.foregroundPrimary)
                            
                            VStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { index in
                                    TextField("기법\(index + 1)", text: Binding(
                                        get: { features[index] },
                                        set: { features[index] = $0 }
                                    ))
                                    .font(Typography.Body4.font)
                                    .foregroundColor(.foregroundPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 14)
                                    .background(Color.shapeDefault)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.borderPrimary, lineWidth: 1)
                                    )
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        // 소개 문구
                        VStack(alignment: .leading, spacing: 4) {
                            Text("소개 문구")
                                .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                .foregroundColor(.foregroundPrimary)
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.borderPrimary, lineWidth: 1)
                                    .frame(height: 200)
                                    .background(Color.shapeDefault)
                                
                                if description.isEmpty {
                                    Text("소개 문구를 입력해주세요.")
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundPlaceholder)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 14)
                                        .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $description)
                                    .font(Typography.Body4.font)
                                    .foregroundColor(.foregroundPrimary)
                                    .frame(height: 160)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 6)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                            }
                        }
                        
                        // 소셜 미디어 링크
                        VStack(alignment: .leading, spacing: 16) {
                            Text("소셜 미디어 링크")
                                .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                .foregroundColor(.foregroundPrimary)
                            
                            VStack(spacing: 12) {
                                // 인스타그램
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("인스타그램")
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundTertiary)
                                    
                                    TextField("인스타그램 링크를 입력해주세요.", text: $instagramLink)
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 14)
                                        .background(Color.shapeDefault)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.borderPrimary, lineWidth: 1)
                                        )
                                        .cornerRadius(8)
                                }
                                
                                // 유튜브
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("유튜브")
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundTertiary)
                                    
                                    TextField("유튜브 링크를 입력해주세요.", text: $youtubeLink)
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 14)
                                        .background(Color.shapeDefault)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.borderPrimary, lineWidth: 1)
                                        )
                                        .cornerRadius(8)
                                }
                                
                                // 카카오톡
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("카카오톡 오픈프로필")
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundTertiary)
                                    
                                    TextField("카카오톡 오픈프로필 링크를 입력해주세요.", text: $kakaoLink)
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 14)
                                        .background(Color.shapeDefault)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.borderPrimary, lineWidth: 1)
                                        )
                                        .cornerRadius(8)
                                }
                                
                                // 이메일
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("이메일")
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundTertiary)
                                    
                                    TextField("이메일 주소를 입력해주세요.", text: $emailLink)
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundPrimary)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 14)
                                        .background(Color.shapeDefault)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.borderPrimary, lineWidth: 1)
                                        )
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // 프로필 수정 버튼 (Primary 1개)
                AriaButton(isSaving ? "저장 중..." : "프로필 수정", style: .primary, isEnabled: canSave && !isSaving) {
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
            Task {
                // 수정 화면 진입 시 서버에서 최신 프로필을 가져와서 폼에 채움 (닉네임만 유지되는 문제 방지)
                await profileStore.fetchProfileFromServer()
                await MainActor.run {
                    loadProfile()
                }
            }
        }
    }
    
    private var canSave: Bool {
        // 닉네임과 특징(최소 1개)이 필수
        !nickname.isEmpty && !features.filter { !$0.isEmpty }.isEmpty
    }
    
    private func loadProfile() {
        let profile = profileStore.profile
        // artist_profiles에 행이 없을 때 user_profiles 값으로 폴백 (편집 후 저장 시 artist_profiles 행 생성 가능하도록)
        let nicknameSource = profile.nickname.isEmpty ? userProfileStore.profile.nickname : profile.nickname
        nickname = nicknameSource
        features = profile.features.count <= 3 ? profile.features + Array(repeating: "", count: max(0, 3 - profile.features.count)) : Array(profile.features.prefix(3))
        description = profile.description
        instagramLink = profile.instagramLink ?? ""
        youtubeLink = profile.youtubeLink ?? ""
        kakaoLink = profile.kakaoLink ?? ""
        emailLink = profile.emailLink ?? ""
        
        // 저장된 프로필 이미지 로드 (로컬 경로 또는 URL)
        if let profileImageUrl = profile.profileImageUrl, profileImageUrl.hasPrefix("/") {
            selectedImage = UIImage(contentsOfFile: profileImageUrl)
        }
    }
    
    private func saveProfile() async {
        isSaving = true
        defer { isSaving = false }
        
        // 프로필 이미지: 새로 선택한 이미지만 업로드 후 URL 전달. 사진을 안 넣었으면 nil로 보내서 기존/랜덤 이미지가 들어가지 않게 함
        var profileImageUrl: String?
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
                profileImageUrl = profileStore.profile.profileImageUrl
                if let url = profileImageUrl, url.hasPrefix("/") { profileImageUrl = nil }
            }
        }
        // 로컬 경로만 있는 경우는 서버에 보내지 않음
        if let url = profileImageUrl, url.hasPrefix("/") { profileImageUrl = nil }
        
        // 특징 필터링 (빈 문자열 제거)
        let filteredFeatures = features.filter { !$0.isEmpty }
        
        await MainActor.run {
            profileStore.updateProfile(
                profileImageUrl: profileImageUrl,
                nickname: nickname,
                features: filteredFeatures,
                description: description,
                instagramLink: instagramLink,
                youtubeLink: youtubeLink,
                kakaoLink: kakaoLink,
                emailLink: emailLink
            )
            dismiss()
        }
    }
}


#Preview {
    ProfileEditView()
}

