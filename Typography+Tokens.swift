import SwiftUI

struct TypographyTokens {
    
    // MARK: - Font Size
    
    struct FontSize {
        static let fontSize10: CGFloat = 10
        static let fontSize12: CGFloat = 12
        static let fontSize13: CGFloat = 13
        static let fontSize14: CGFloat = 14
        static let fontSize16: CGFloat = 16
        static let fontSize20: CGFloat = 20
        static let fontSize24: CGFloat = 24
        static let fontSize28: CGFloat = 28
        static let fontSize32: CGFloat = 32
        static let fontSize48: CGFloat = 48
        static let fontSize52: CGFloat = 52
        static let fontSize56: CGFloat = 56
    }
    
    // MARK: - Line Height
    
    struct LineHeight {
        static let lineHeight14: CGFloat = 14
        static let lineHeight18: CGFloat = 18
        static let lineHeight20: CGFloat = 20
        static let lineHeight24: CGFloat = 24
        static let lineHeight28: CGFloat = 28
        static let lineHeight32: CGFloat = 32
        static let lineHeight40: CGFloat = 40
        static let lineHeight44: CGFloat = 44
        static let lineHeight48: CGFloat = 48
        static let lineHeight52: CGFloat = 52
        static let lineHeight56: CGFloat = 56
        static let lineHeight64: CGFloat = 64
    }
    
    // MARK: - Letter Spacing
    
    struct LetterSpacing {
        static let medium: CGFloat = -0.5
        static let large: CGFloat = -1.0
    }
    
    // MARK: - Font Weight
    
    struct FontWeight {
        static let extrabold: Font.Weight = .black
        static let bold: Font.Weight = .bold
        static let medium: Font.Weight = .medium
        static let regular: Font.Weight = .regular
    }
}

// MARK: - Convenient Access Extension

extension Font {
    
    // MARK: - Typography Token Access
    
    static let typography = TypographyTokens.self
}