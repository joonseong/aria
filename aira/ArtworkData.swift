//
//  ArtworkData.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import Foundation

// 아트워크 데이터 모델
struct ArtworkData: Identifiable {
    let id = UUID()
    let imageUrl: String
    let title: String
    let description: String
    let year: String
    let medium: String
    let size: String
    let artistName: String
    let artistImageUrl: String
}

