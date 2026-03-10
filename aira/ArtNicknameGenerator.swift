//
//  ArtNicknameGenerator.swift
//  aira
//
//  미술 관련 형용사+명사 조합으로 랜덤 닉네임 생성
//

import Foundation

enum ArtNicknameGenerator {
    /// 미술 관련 형용사
    private static let adjectives: [String] = [
        "모던", "클래식", "미니멀", "추상", "인상주의", "표현주의", "팝아트", "바로크",
        "로맨틱", "네오클래식", "큐비즘", "파스텔", "모노크롬", "컬러풀", "미디어아트",
        "유화", "펜화", "목판화", "석판화", "에칭", "프레스코", "템페라",
        "아크릴", "그래피티", "스타일리시", "포비즘", "다다이즘", "수퍼리얼", "포스트모던"
    ]
    
    /// 미술 관련 명사
    private static let nouns: [String] = [
        "팔레트", "캔버스", "붓", "스케치", "조각", "수채화", "유화", "드로잉",
        "프레임", "갤러리", "뮤즈", "화가", "작가", "색채", "명암", "원근",
        "구도", "비례", "톤", "선", "형태", "질감", "입체", "평면",
        "전시회", "화랑", "미술관", "아뜰리에", "스튜디오", "크로키", "밑그림",
        "파스텔", "콜라주", "몽타주", "실루엣", "피사체", "모델"
    ]
    
    /// 형용사+명사 조합의 랜덤 닉네임 생성
    static func generate() -> String {
        let adj = adjectives.randomElement() ?? "모던"
        let noun = nouns.randomElement() ?? "캔버스"
        return "\(adj)\(noun)"
    }
}
