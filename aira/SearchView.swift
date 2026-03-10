//
//  SearchView.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//

import SwiftUI
import UIKit

struct SearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var artworkStore = ArtworkStore.shared
    @State private var searchText: String = ""
    @State private var selectedPostedArtwork: PostedArtwork?
    @State private var selectedArtist: String?
    @State private var isArtistDetailPresented: Bool = false
    
    var filteredArtworks: [PostedArtwork] {
        if searchText.isEmpty {
            return []
        }
        return artworkStore.artworks.filter { artwork in
            artwork.title.localizedCaseInsensitiveContains(searchText) ||
            artwork.description.localizedCaseInsensitiveContains(searchText) ||
            artwork.artistName.localizedCaseInsensitiveContains(searchText) ||
            artwork.medium.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var uniqueArtists: [String] {
        let artists = Set(filteredArtworks.map { $0.artistName })
        return Array(artists).sorted()
    }
    
    var body: some View {
        ZStack {
            Color.shapeDefault
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
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
                    
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.foregroundTertiary)
                        
                        TextField("작품, 작가 검색", text: $searchText)
                            .font(Typography.Body2.font)
                            .foregroundColor(.foregroundPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.shapeDepth1)
                    .cornerRadius(8)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.foregroundTertiary)
                                .frame(width: 28, height: 28)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(height: 56)
                
                // Search Results
                if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.foregroundTertiary)
                        Text("작품이나 작가를 검색해보세요")
                            .font(Typography.Body2.font)
                            .foregroundColor(.foregroundTertiary)
                        Spacer()
                    }
                } else if filteredArtworks.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.foregroundTertiary)
                        Text("검색 결과가 없습니다")
                            .font(Typography.Body2.font)
                            .foregroundColor(.foregroundTertiary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // 작가 섹션
                            if !uniqueArtists.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("작가")
                                        .font(Typography.Heading3.font)
                                        .foregroundColor(.foregroundPrimary)
                                        .padding(.horizontal, 16)
                                    
                                    ForEach(uniqueArtists, id: \.self) { (artistName: String) in
                                        Button(action: {
                                            selectedArtist = artistName
                                            isArtistDetailPresented = true
                                        }) {
                                            HStack(spacing: 12) {
                                                // 작가 프로필 이미지
                                                Circle()
                                                    .fill(Color.shapeDepth2)
                                                    .frame(width: 48, height: 48)
                                                
                                                Text(artistName)
                                                    .font(Typography.Body2.font)
                                                    .foregroundColor(.foregroundPrimary)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.foregroundTertiary)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color.shapeDefault)
                                        }
                                    }
                                }
                                .padding(.top, 16)
                            }
                            
                            // 작품 섹션
                            VStack(alignment: .leading, spacing: 12) {
                                Text("작품")
                                    .font(Typography.Heading3.font)
                                    .foregroundColor(.foregroundPrimary)
                                    .padding(.horizontal, 16)
                                
                                ForEach(filteredArtworks) { (artwork: PostedArtwork) in
                                    Button(action: {
                                        selectedPostedArtwork = artwork
                                    }) {
                                        HStack(spacing: 12) {
                                            // 작품 이미지 - SmartImageView 사용
                                            SmartImageView(imageUrl: artwork.imageUrls.first ?? "", placeholder: Color.shapeDepth2)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(artwork.title)
                                                    .font(Typography.Body3.font)
                                                    .foregroundColor(.foregroundPrimary)
                                                    .lineLimit(1)
                                                
                                                Text(artwork.artistName)
                                                    .font(Typography.Body4.font)
                                                    .foregroundColor(.foregroundTertiary)
                                                    .lineLimit(1)
                                                
                                                Text("\(artwork.year) • \(artwork.medium)")
                                                    .font(Typography.Caption2.font)
                                                    .foregroundColor(.foregroundTertiary)
                                                    .lineLimit(1)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(.foregroundTertiary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.shapeDefault)
                                    }
                                }
                            }
                            .padding(.top, 16)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedPostedArtwork) { artwork in
            ProductDetailView(artwork: artwork)
                .onDisappear {
                    selectedPostedArtwork = nil
                }
        }
        .fullScreenCover(isPresented: $isArtistDetailPresented) {
            if let artistName = selectedArtist {
                // 작가 상세 페이지로 이동
                let artworks = artworkStore.getArtworksByArtist(artistName)
                if let firstArtwork = artworks.first {
                    DetailUserView(artwork: firstArtwork.toArtworkData())
                } else {
                    // 작품이 없는 경우 빈 작품 데이터로 표시
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
    }
}
