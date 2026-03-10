//
//  ProductEnterView.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ProductEnterView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var artworkStore = ArtworkStore.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var profileStore = ArtistProfileStore.shared
    @StateObject private var userProfileStore = UserProfileStore.shared
    
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var year: String = ""
    @State private var medium: String = ""
    @State private var width: String = ""
    @State private var height: String = ""
    @State private var representativeImageIndex: Int = 0  // 대표 이미지 인덱스
    
    private let maxImages = 10
    
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
                    
                    Text("작품 등록")
                        .font(Typography.Body3.font.weight(Typography.fontWeightBold))
                        .foregroundColor(.foregroundPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(height: 56)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Image Upload Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 0) {
                                Text("작품 이미지 ")
                                    .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                    .foregroundColor(.foregroundPrimary)
                                Text("*")
                                    .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                    .foregroundColor(.shapePrimary)
                            }
                            .padding(.top, 30)
                            
                            // Image Container (Horizontal Scroll)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    // Add Image Container
                                    if selectedImages.count < maxImages {
                                        Button(action: {
                                            showingImagePicker = true
                                        }) {
                                            VStack(spacing: 4) {
                                                Image("icon.plus")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 24, height: 24)
                                                    .foregroundColor(.foregroundPlaceholder)
                                                
                                                Text("작품 추가")
                                                    .font(Typography.Badge1.font)
                                                    .foregroundColor(.foregroundPlaceholder)
                                            }
                                            .frame(width: 80, height: 80)
                                            .background(Color.shapeDefault)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.borderPrimary, lineWidth: 1)
                                            )
                                            .cornerRadius(8)
                                        }
                                    }
                                    
                                    // Image Container N (등록된 이미지들)
                                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                        ZStack(alignment: .topLeading) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            // 대표 배지 (첫 번째 이미지)
                                            if index == representativeImageIndex {
                                                HStack(spacing: 4) {
                                                    Text("대표")
                                                        .font(Typography.Badge2.font)
                                                        .foregroundColor(.foregroundSecondary)
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 2)
                                                        .background(Color.shapeDepth1)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 100)
                                                                .stroke(Color.borderPrimary, lineWidth: 1)
                                                        )
                                                        .cornerRadius(100)
                                                }
                                                .padding(4)
                                            }
                                            
                                            // Close Button (이미지 위에 오버레이로 배치)
                                            VStack {
                                                HStack {
                                                    Spacer()
                                                    Button(action: {
                                                        selectedImages.remove(at: index)
                                                        if representativeImageIndex >= selectedImages.count - 1 && representativeImageIndex > 0 {
                                                            representativeImageIndex = selectedImages.count - 2
                                                        }
                                                    }) {
                                                        ZStack {
                                                            Circle()
                                                                .fill(Color.foregroundPlaceholder)
                                                                .frame(width: 24, height: 24)
                                                            
                                                            Image("icon.close")
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fit)
                                                                .font(.system(size: 12))
                                                                .foregroundColor(.white)
                                                                .frame(width: 16, height: 16)
                                                        }
                                                    }
                                                    .padding(4)
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Form Fields
                        VStack(spacing: 16) {
                            // 작품 이름 *
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 0) {
                                    Text("작품 이름 ")
                                        .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                        .foregroundColor(.foregroundPrimary)
                                    Text("*")
                                        .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                        .foregroundColor(.shapePrimary)
                                }
                                
                                TextField("작품의 이름을 입력해주세요.", text: $title)
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
                            
                            // 제작 기법 *
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 0) {
                                    Text("제작 기법 ")
                                        .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                        .foregroundColor(.foregroundPrimary)
                                    Text("*")
                                        .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                        .foregroundColor(.shapePrimary)
                                }
                                
                                TextField("어떤 기법으로 제작했는지 입력해주세요.", text: $medium)
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
                            
                            // 제작 년도 *
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 0) {
                                    Text("제작 년도 ")
                                        .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                        .foregroundColor(.foregroundPrimary)
                                    Text("*")
                                        .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                        .foregroundColor(.shapePrimary)
                                }
                                
                                TextField("예)2021", text: $year)
                                    .font(Typography.Body4.font)
                                    .foregroundColor(.foregroundPrimary)
                                    .keyboardType(.numberPad)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 14)
                                    .background(Color.shapeDefault)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.borderPrimary, lineWidth: 1)
                                    )
                                    .cornerRadius(8)
                            }
                            
                            // 작품 크기 (선택)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("작품 크기")
                                    .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                    .foregroundColor(.foregroundPrimary)
                                
                                HStack(spacing: 4) {
                                    // 가로 사이즈
                                    TextField("가로 사이즈(cm)", text: $width)
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundPrimary)
                                        .keyboardType(.decimalPad)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 14)
                                        .background(Color.shapeDefault)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.borderPrimary, lineWidth: 1)
                                        )
                                        .cornerRadius(8)
                                    
                                    // X 아이콘 (TextField와 중앙 정렬)
                                    VStack {
                                        Spacer()
                                        Image("icon.close")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .font(.system(size: 16))
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.foregroundPrimary)
                                        Spacer()
                                    }
                                    .frame(height: 48)  // TextField 높이와 동일하게
                                    
                                    // 세로 사이즈
                                    TextField("세로 사이즈(cm)", text: $height)
                                        .font(Typography.Body4.font)
                                        .foregroundColor(.foregroundPrimary)
                                        .keyboardType(.decimalPad)
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
                            
                            // 작품 설명 (선택값)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("작품 설명")
                                    .font(Typography.Body3.font.weight(Typography.fontWeightSemibold))
                                    .foregroundColor(.foregroundPrimary)
                                
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.borderPrimary, lineWidth: 1)
                                        .frame(height: 200)
                                        .background(Color.shapeDefault)
                                    
                                    if description.isEmpty {
                                        Text("작품의 이름을 입력해주세요.")
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
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                // Submit Button (Primary 1개)
                AiraButton("작품 등록", style: .primary, isEnabled: canSave) {
                    saveArtwork()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImages: $selectedImages, maxImages: maxImages)
        }
        .onChange(of: selectedImages.count) { oldValue, newValue in
            if newValue > 0 && representativeImageIndex >= newValue {
                representativeImageIndex = newValue - 1
            }
        }
        .onAppear {
            // 권한: Artist만 작품 업로드 가능 (User 업로드 불가)
            if !authManager.canUpload() {
                dismiss()
            }
        }
    }
    
    private var canSave: Bool {
        !selectedImages.isEmpty &&
        !title.isEmpty &&
        !medium.isEmpty &&
        !year.isEmpty
        // description, size는 선택값
    }
    
    private func saveArtwork() {
        // 이미지를 로컬에 저장하고 경로를 가져옴
        let imageUrls = saveImagesLocally()
        
        // 크기 문자열 생성 (선택값 - 비어있으면 빈 문자열)
        let sizeString: String = {
            if width.isEmpty && height.isEmpty { return "" }
            if width.isEmpty { return "\(height) cm" }
            if height.isEmpty { return "\(width) cm" }
            return "\(width) cm X \(height) cm"
        }()
        
        // 프로필 닉네임 (artist_profiles 비어 있으면 user_profiles 폴백 → 홈/작가 상세 목록에 노출되도록)
        let artistName = profileStore.profile.nickname.isEmpty ? userProfileStore.profile.nickname : profileStore.profile.nickname
        let artistImageUrl = profileStore.profile.profileImageUrl ?? userProfileStore.profile.profileImageUrl ?? ""
        
        let artwork = PostedArtwork(
            imageUrls: imageUrls,
            title: title,
            description: description,
            year: year,
            medium: medium,
            size: sizeString,
            artistName: artistName,
            artistImageUrl: artistImageUrl
        )
        
        artworkStore.addArtwork(artwork)
        dismiss()
    }
    
    // 이미지를 로컬에 저장하고 파일 경로 반환
    private func saveImagesLocally() -> [String] {
        var imageUrls: [String] = []
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesDirectory = documentsPath.appendingPathComponent("ArtworkImages")
        
        // 디렉토리 생성
        do {
            try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            AppLogger.debug("Failed to create images directory: \(error)")
            return imageUrls
        }
        
        for (index, image) in selectedImages.enumerated() {
            let fileName = "\(UUID().uuidString)_\(index).jpg"
            let fileURL = imagesDirectory.appendingPathComponent(fileName)
            
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                do {
                    try imageData.write(to: fileURL)
                    // 파일 URL을 문자열로 저장
                    imageUrls.append(fileURL.path)
                    AppLogger.debug("Saved image to: \(fileURL.path)")
                } catch {
                    AppLogger.debug("Failed to save image \(index): \(error)")
                }
            }
        }
        
        return imageUrls
    }
}

// 이미지 피커
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let maxImages: Int
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = maxImages - selectedImages.count
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            for result in results {
                loadImage(from: result.itemProvider)
            }
        }
        
        private func loadImage(from provider: NSItemProvider) {
            // loadObject가 iCloud/FileProvider 사진에서 실패할 수 있어 loadDataRepresentation 폴백 사용
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        self.appendImage(image)
                    } else {
                        self.loadImageViaData(from: provider)
                    }
                }
            } else {
                loadImageViaData(from: provider)
            }
        }
        
        private func loadImageViaData(from provider: NSItemProvider) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                if let data = data, let image = UIImage(data: data) {
                    self.appendImage(image)
                }
            }
        }
        
        private func appendImage(_ image: UIImage) {
            DispatchQueue.main.async {
                if self.parent.selectedImages.count < self.parent.maxImages {
                    self.parent.selectedImages.append(image)
                }
            }
        }
    }
}

#Preview {
    ProductEnterView()
}
