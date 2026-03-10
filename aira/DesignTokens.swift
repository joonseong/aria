//
//  DesignTokens.swift
//  aira
//
//  Created by 김준성 on 12/21/25.
//  Figma Variables에서 자동 생성됨
//

import SwiftUI

// MARK: - Color Tokens
extension Color {
    // Labels
    static let labelPrimary = Color(hex: "000000")
    
    // Foreground Colors
    static let foregroundPrimary = Color(hex: "212224")
    static let foregroundSecondary = Color(hex: "333436")
    static let foregroundTertiary = Color(hex: "7D7E82")
    static let foregroundPlaceholder = Color(hex: "B4B6BA")
    static let foregroundPoint = Color(hex: "F53356")
    static let foregroundInvertPrimary = Color(hex: "FFFFFF")
    
    // Shape Colors
    static let shapePrimary = Color(hex: "F53356")
    static let shapeDefault = Color(hex: "FFFFFF")
    static let shapeDepth1 = Color(hex: "F7F7F9")
    static let shapeDepth2 = Color(hex: "F1F1F3")
    static let shapeDeco = Color(hex: "FDCCD5")  // 작가가 쓴 글 배경색
    
    // Border Colors
    static let borderPrimary = Color(hex: "E7E7EB")
    
    // Grayscale
    static let gray600 = Color(hex: "393737")
}

// MARK: - Typography Tokens
// Figma Text Styles에서 자동 생성됨
struct Typography {
    // MARK: - Base Tokens
    
    // Font Family
    static let fontFamily = "Pretendard"
    
    // Font Sizes (from Figma Variables)
    static let fontSize20: CGFloat = 20  // text/fontsize/20
    static let fontSize16: CGFloat = 16  // text/fontsize/16
    static let fontSize14: CGFloat = 14  // text/fontsize/14
    static let fontSize13: CGFloat = 13  // text/fontsize/13
    
    // Line Heights (from Figma Variables)
    static let lineHeight28: CGFloat = 28  // text/lineheight/28
    static let lineHeight24: CGFloat = 24  // text/lineheight/24
    static let lineHeight20: CGFloat = 20  // text/lineheight/20
    
    // Font Weights (from Figma Variables)
    static let fontWeightBold: Font.Weight = .bold      // text/fontweight/bold (700)
    static let fontWeightSemibold: Font.Weight = .semibold
    static let fontWeightRegular: Font.Weight = .regular  // text/fontweight/regular (400)
    static let fontWeightMedium: Font.Weight = .medium    // text/fontweight/medium (600)
    
    // Letter Spacing (from Figma Variables)
    static let letterSpacingMedium: CGFloat = -0.5  // text/letterspacing/medium
    
    // MARK: - Helper Function
    /// Pretendard 폰트를 생성하는 헬퍼 함수
    /// 폰트가 로드되지 않을 경우 시스템 폰트로 fallback
    static func pretendardFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.custom(fontFamily, size: size)
            .weight(weight)
    }
    
    // MARK: - Text Styles (from Figma Text Styles)
    
    /// Heading/Heading2
    /// Font: Pretendard Bold, Size: 20, Line Height: 28, Letter Spacing: -0.5
    /// Color: Grayscale/Gray_600 (#393737)
    struct Heading2 {
        static let font = pretendardFont(size: fontSize20, weight: fontWeightBold)
        static let lineHeight = lineHeight28
        static let letterSpacing = letterSpacingMedium
        static let color = Color.gray600
    }
    
    /// Body/Body2
    /// Font: Pretendard Regular, Size: 16, Line Height: 24, Letter Spacing: -0.5
    /// Color: color/foreground/secondary (#333436)
    struct Body2 {
        static let font = pretendardFont(size: fontSize16, weight: fontWeightRegular)
        static let lineHeight = lineHeight24
        static let letterSpacing = letterSpacingMedium
        static let color = Color.foregroundSecondary
    }
    
    /// Body/Body4
    /// Font: Pretendard Regular, Size: 14, Line Height: 20, Letter Spacing: -0.5
    /// Color: color/foreground/tertiary (#7d7e82)
    struct Body4 {
        static let font = pretendardFont(size: fontSize14, weight: fontWeightRegular)
        static let lineHeight = lineHeight20
        static let letterSpacing = letterSpacingMedium
        static let color = Color.foregroundTertiary
    }
    
    /// Body/Body1
    /// Font: Pretendard SemiBold, Size: 16, Line Height: 24, Letter Spacing: -0.5
    /// Color: color/foreground/invert/primary (white)
    struct Body1 {
        static let font = pretendardFont(size: fontSize16, weight: fontWeightMedium)
        static let lineHeight = lineHeight24
        static let letterSpacing = letterSpacingMedium
        static let color = Color.foregroundInvertPrimary
    }
    
    /// Caption/Caption2
    /// Font: Pretendard Regular, Size: 13, Line Height: 20, Letter Spacing: -0.5
    /// Color: color/foreground/invert/primary (white)
    struct Caption2 {
        static let font = pretendardFont(size: fontSize13, weight: fontWeightRegular)
        static let lineHeight = lineHeight20
        static let letterSpacing = letterSpacingMedium
        static let color = Color.foregroundInvertPrimary
    }
    
    /// Heading/Heading3
    /// Font: Pretendard Bold, Size: 16, Line Height: 24, Letter Spacing: -0.5
    struct Heading3 {
        static let font = pretendardFont(size: fontSize16, weight: fontWeightBold)
        static let lineHeight = lineHeight24
        static let letterSpacing = letterSpacingMedium
    }
    
    /// Body/Body3
    /// Font: Pretendard SemiBold, Size: 14, Line Height: 20, Letter Spacing: -0.5
    struct Body3 {
        static let font = pretendardFont(size: fontSize14, weight: fontWeightSemibold)
        static let lineHeight = lineHeight20
        static let letterSpacing = letterSpacingMedium
    }
    
    /// Badge/Badge1
    /// Font: Pretendard SemiBold, Size: 12, Line Height: 18, Letter Spacing: -0.5
    struct Badge1 {
        static let font = pretendardFont(size: 12, weight: fontWeightSemibold)
        static let lineHeight: CGFloat = 18
        static let letterSpacing = letterSpacingMedium
    }
    
    /// Badge/Badge2
    /// Font: Pretendard Regular, Size: 10, Line Height: 14, Letter Spacing: -0.5
    struct Badge2 {
        static let font = pretendardFont(size: 10, weight: fontWeightRegular)
        static let lineHeight: CGFloat = 14
        static let letterSpacing = letterSpacingMedium
    }
    
    /// Heading/Heading1
    /// Font: Pretendard Bold, Size: 24, Line Height: 32, Letter Spacing: -0.5
    struct Heading1 {
        static let font = pretendardFont(size: 24, weight: fontWeightBold)
        static let lineHeight: CGFloat = 32
        static let letterSpacing = letterSpacingMedium
    }
}

// MARK: - Button Style Tokens
/// 화면당 Primary 버튼은 1개만, 나머지는 Secondary/Tertiary로 배치
enum ButtonStyleToken {
    /// Primary: 메인 CTA (shapePrimary 배경, 흰색 텍스트)
    static let primaryBackground = Color.shapePrimary
    static let primaryForeground = Color.foregroundInvertPrimary
    
    /// Secondary: 보조 CTA (아웃라인, 테두리)
    static let secondaryBackground = Color.shapeDefault
    static let secondaryForeground = Color.foregroundSecondary
    static let secondaryBorder = Color.borderPrimary
    
    /// Tertiary: 보조/고스트 (배경 연한 회색 또는 투명)
    static let tertiaryBackground = Color.shapeDepth1
    static let tertiaryForeground = Color.foregroundSecondary
    
    /// Disabled
    static let disabledBackground = Color.foregroundPlaceholder
    static let disabledForeground = Color.foregroundInvertPrimary
}

// MARK: - Shadow Tokens
struct Shadow {
    // 아트: DROP_SHADOW
    // color: #00000029, offset: (0, 24), radius: 48, spread: 0
    static let art = ShadowStyle(
        color: Color.black.opacity(0.16),
        radius: 48,
        x: 0,
        y: 24
    )
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - AiraButton (Primary / Secondary / Tertiary)
enum AiraButtonStyle {
    case primary
    case secondary
    case tertiary
}

struct AiraButton: View {
    let title: String
    let style: AiraButtonStyle
    let isEnabled: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        style: AiraButtonStyle = .primary,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.Body1.font)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(backgroundColor)
                .cornerRadius(100)
                .overlay(overlayContent)
        }
        .disabled(!isEnabled)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return isEnabled ? ButtonStyleToken.primaryForeground : ButtonStyleToken.disabledForeground
        case .secondary, .tertiary:
            return ButtonStyleToken.secondaryForeground
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isEnabled ? ButtonStyleToken.primaryBackground : ButtonStyleToken.disabledBackground
        case .secondary:
            return ButtonStyleToken.secondaryBackground
        case .tertiary:
            return ButtonStyleToken.tertiaryBackground
        }
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        switch style {
        case .primary:
            EmptyView()
        case .secondary:
            RoundedRectangle(cornerRadius: 100)
                .stroke(ButtonStyleToken.secondaryBorder, lineWidth: 1)
        case .tertiary:
            EmptyView()
        }
    }
}

// MARK: - Shadow View Modifier
extension View {
    func shadow(_ style: Shadow.ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

