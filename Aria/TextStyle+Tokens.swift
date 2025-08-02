import SwiftUI

struct AriaTextStyle {
    let fontSize: CGFloat
    let lineHeight: CGFloat
    let letterSpacing: Double
    let fontWeight: Font.Weight
    
    init(fontSize: CGFloat, lineHeight: CGFloat, letterSpacing: Double, fontWeight: Font.Weight) {
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.fontWeight = fontWeight
    }
}

extension AriaTextStyle {
    
    // MARK: - Display Styles
    
    static let display1 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize56,
        lineHeight: TypographyTokens.LineHeight.lineHeight64,
        letterSpacing: TypographyTokens.LetterSpacing.large,
        fontWeight: TypographyTokens.FontWeight.extrabold
    )
    
    static let display2 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize48,
        lineHeight: TypographyTokens.LineHeight.lineHeight56,
        letterSpacing: TypographyTokens.LetterSpacing.large,
        fontWeight: TypographyTokens.FontWeight.extrabold
    )
    
    static let display3 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize32,
        lineHeight: TypographyTokens.LineHeight.lineHeight44,
        letterSpacing: TypographyTokens.LetterSpacing.large,
        fontWeight: TypographyTokens.FontWeight.extrabold
    )
    
    static let display4 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize28,
        lineHeight: TypographyTokens.LineHeight.lineHeight40,
        letterSpacing: TypographyTokens.LetterSpacing.large,
        fontWeight: TypographyTokens.FontWeight.extrabold
    )
    
    // MARK: - Heading Styles
    
    static let heading1 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize24,
        lineHeight: TypographyTokens.LineHeight.lineHeight32,
        letterSpacing: TypographyTokens.LetterSpacing.medium,
        fontWeight: TypographyTokens.FontWeight.bold
    )
    
    static let heading2 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize20,
        lineHeight: TypographyTokens.LineHeight.lineHeight28,
        letterSpacing: TypographyTokens.LetterSpacing.medium,
        fontWeight: TypographyTokens.FontWeight.bold
    )
    
    static let heading3 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize16,
        lineHeight: TypographyTokens.LineHeight.lineHeight24,
        letterSpacing: TypographyTokens.LetterSpacing.medium,
        fontWeight: TypographyTokens.FontWeight.bold
    )
    
    static let heading4 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize14,
        lineHeight: TypographyTokens.LineHeight.lineHeight20,
        letterSpacing: TypographyTokens.LetterSpacing.medium,
        fontWeight: TypographyTokens.FontWeight.bold
    )
    
    // MARK: - Body Styles
    
    static let body1 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize16,
        lineHeight: TypographyTokens.LineHeight.lineHeight24,
        letterSpacing: TypographyTokens.LetterSpacing.medium,
        fontWeight: TypographyTokens.FontWeight.medium
    )
    
    static let body2 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize16,
        lineHeight: TypographyTokens.LineHeight.lineHeight24,
        letterSpacing: TypographyTokens.LetterSpacing.medium,
        fontWeight: TypographyTokens.FontWeight.regular
    )
    
    static let body3 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize14,
        lineHeight: TypographyTokens.LineHeight.lineHeight20,
        letterSpacing: TypographyTokens.LetterSpacing.medium,
        fontWeight: TypographyTokens.FontWeight.medium
    )
    
    static let body4 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize14,
        lineHeight: TypographyTokens.LineHeight.lineHeight20,
        letterSpacing: TypographyTokens.LetterSpacing.medium,
        fontWeight: TypographyTokens.FontWeight.regular
    )
    
    // MARK: - Caption Styles
    
    static let caption1 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize13,
        lineHeight: TypographyTokens.LineHeight.lineHeight20,
        letterSpacing: TypographyTokens.LetterSpacing.medium,
        fontWeight: TypographyTokens.FontWeight.bold
    )
    
    static let caption2 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize13,
        lineHeight: TypographyTokens.LineHeight.lineHeight20,
        letterSpacing: TypographyTokens.LetterSpacing.medium,
        fontWeight: TypographyTokens.FontWeight.regular
    )
    
    // MARK: - Badge Styles
    
    static let badge1 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize12,
        lineHeight: TypographyTokens.LineHeight.lineHeight18,
        letterSpacing: TypographyTokens.LetterSpacing.medium,
        fontWeight: TypographyTokens.FontWeight.regular
    )
    
    static let badge2 = AriaTextStyle(
        fontSize: TypographyTokens.FontSize.fontSize10,
        lineHeight: TypographyTokens.LineHeight.lineHeight14,
        letterSpacing: TypographyTokens.LetterSpacing.medium,
        fontWeight: TypographyTokens.FontWeight.regular
    )
}

// MARK: - SwiftUI Text Extension for Easy Usage

extension Text {
    
    func textStyle(_ style: AriaTextStyle) -> some View {
        self
            .font(.system(size: style.fontSize, weight: style.fontWeight))
            .kerning(style.letterSpacing)
            .lineSpacing(style.lineHeight - style.fontSize)
    }
}

// MARK: - Font Extension for Creating Fonts from TextStyle

extension Font {
    
    static func textStyle(_ style: AriaTextStyle) -> Font {
        return .system(size: style.fontSize, weight: style.fontWeight)
    }
}
