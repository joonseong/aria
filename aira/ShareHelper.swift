//
//  ShareHelper.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import UIKit

struct ShareHelper {
    static func shareArtwork(title: String, description: String, imageUrl: String?) {
        var items: [Any] = []
        
        // 텍스트 공유
        let text = "\(title)\n\(description)"
        items.append(text)
        
        // 이미지 공유 (있는 경우)
        if let imageUrl = imageUrl {
            if imageUrl.hasPrefix("/") {
                // 로컬 파일 경로
                if let uiImage = UIImage(contentsOfFile: imageUrl) {
                    items.append(uiImage)
                }
            } else if let url = URL(string: imageUrl), imageUrl.hasPrefix("http") {
                // URL에서 이미지 로드
                if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                    items.append(uiImage)
                }
            }
        }
        
        // 공유 시트 표시
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            
            // iPad 지원
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    static func shareProfile(artistName: String, description: String, imageUrl: String?) {
        var items: [Any] = []
        
        // 텍스트 공유
        let text = "\(artistName) 작가\n\(description)"
        items.append(text)
        
        // 이미지 공유 (있는 경우)
        if let imageUrl = imageUrl {
            if imageUrl.hasPrefix("/") {
                if let uiImage = UIImage(contentsOfFile: imageUrl) {
                    items.append(uiImage)
                }
            } else if let url = URL(string: imageUrl), imageUrl.hasPrefix("http") {
                if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                    items.append(uiImage)
                }
            }
        }
        
        // 공유 시트 표시
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            
            // iPad 지원
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
        }
    }
}

