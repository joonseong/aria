//
//  ImagePickerComponents.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

// 단일 이미지 피커 (공통 컴포넌트)
struct SingleImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: SingleImagePicker
        
        init(_ parent: SingleImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            loadImage(from: result.itemProvider)
        }
        
        private func loadImage(from provider: NSItemProvider) {
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        self.parent.selectedImage = image
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
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                    }
                }
            }
        }
    }
}

