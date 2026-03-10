//
//  AccountManager.swift
//  aria
//
//  Created by 김준성 on 12/21/25.
//

import Foundation
import UIKit

class AccountManager {
    static let shared = AccountManager()
    
    private init() {}
    
    /// 회원탈퇴 시 모든 사용자 데이터 삭제
    func deleteAccount() {
        // 1. 좋아요 데이터 삭제
        LikeStore.shared.likedArtworkIds = []
        UserDefaults.standard.removeObject(forKey: "LikedArtworks")
        
        // 2. 팔로우 데이터 삭제
        FollowStore.shared.followedArtists = []
        FollowStore.shared.artistFollowCounts = [:]
        UserDefaults.standard.removeObject(forKey: "FollowedArtists")
        UserDefaults.standard.removeObject(forKey: "ArtistFollowCounts")
        
        // 3. 방명록 데이터 삭제
        GuestBookStore.shared.clearAllEntries()
        
        // 4. 일반 유저 프로필 삭제
        UserProfileStore.shared.clearProfile()
        
        // 5. 작가 프로필 삭제 (작가인 경우)
        ArtistProfileStore.shared.clearProfile()
        
        // 6. 등록한 작품 삭제 (작가인 경우)
        ArtworkStore.shared.clearAllArtworks()
        
        // 7. 로컬 이미지 파일 삭제
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // 모든 이미지 디렉토리 삭제
        let imageDirectories = [
            "ArtworkImages",
            "ProfileImages",
            "UserProfileImages"
        ]
        
        for directory in imageDirectories {
            let directoryPath = documentsPath.appendingPathComponent(directory)
            try? fileManager.removeItem(at: directoryPath)
        }
        
        // 8. 서버에 회원탈퇴 요청
        Task {
            await AuthService.shared.deleteAccount()
        }
        
        // 9. 로그아웃 처리
        AuthenticationManager.shared.logout()
    }
}

