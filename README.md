# SwiftUI iOS Project

A modern SwiftUI iOS application with a comprehensive design system built using design tokens for colors, typography, and icons.

## 🏗️ Project Structure

```
📁 Sources/
┣ 📄 App.swift                    # Main SwiftUI App entry point
┣ 📄 Color+Tokens.swift          # Core color token definitions
┣ 📄 Color+System.swift          # System-level color constants
┣ 📄 Typography+Tokens.swift     # Typography token definitions
┣ 📄 TextStyle+Tokens.swift      # Reusable text style definitions
┗ 📄 Icon+System.swift           # System icon constants using SF Symbols

📁 Assets/
┗ 📁 xcassets/                   # Xcode Asset Catalog (managed by Xcode)
  ┗ 📄 .gitkeep                  # Preserves directory in Git

📄 main.swift                     # Swift project initialization
```

## 📂 Directory Overview

### **Sources/**
Contains all Swift source files for the application:

- **`App.swift`**: The main application entry point using SwiftUI's `@main` App protocol
- **Design Token Files**: A complete design system implementation
  - **`Color+Tokens.swift`**: Core color palette with semantic tokens (grayscale, transparency, brand colors)
  - **`Color+System.swift`**: System-level color assignments (shape, border, foreground)
  - **`Typography+Tokens.swift`**: Typography foundations (font sizes, line heights, letter spacing, weights)
  - **`TextStyle+Tokens.swift`**: Predefined text styles (display, heading, body, caption, badge)
  - **`Icon+System.swift`**: System icon constants using SF Symbols

### **Assets/**
Contains application assets managed by Xcode:

- **`xcassets/`**: Xcode Asset Catalog folder for app icons, images, and color assets
- **`.gitkeep`**: Ensures the directory structure is preserved in version control

## 🎨 Design System

This project implements a comprehensive design system using design tokens:

### **Colors**
- **Core Tokens**: Base color palette with semantic naming
- **System Tokens**: Contextual color assignments for UI components
- **Groups**: Grayscale, transparency, and brand colors (red, orange, yellow, lime, olive, blue, royal blue, purple, pink)

### **Typography**
- **Font Sizes**: 12 different sizes from 10pt to 56pt
- **Line Heights**: Corresponding line heights for proper vertical rhythm
- **Letter Spacing**: Optimized tracking values
- **Text Styles**: 16 predefined styles for consistent typography hierarchy

### **Icons**
- **SF Symbols**: Leverages Apple's system icon library
- **Organized Categories**: Navigation, actions, status, and directional icons
- **Consistent Naming**: Semantic constants for easy maintenance

## 🚀 Getting Started

### **Setup**
1. Run the setup script to initialize the project structure:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

2. Open the project in Xcode to configure the Asset Catalog

### **Usage Examples**

```swift
// Using design tokens
Text("Welcome")
    .textStyle(.display1)
    .foregroundColor(.system.Foreground.primary)

Button(action: {}) {
    HStack {
        Image(systemName: SystemIcon.add)
        Text("Add Item")
            .textStyle(.heading3)
    }
}
.foregroundColor(.system.Foreground.invert.primary)
.background(.system.Shape.primary)
```

## 🛠️ Development

### **Code Style**
- Uses 4 spaces for indentation (configured in `.editorconfig`)
- UTF-8 encoding with LF line endings
- Trailing whitespace trimmed automatically

### **Version Control**
- Comprehensive `.gitignore` for Xcode/Swift projects
- Asset Catalog directory preserved with `.gitkeep`
- Ready for collaborative development

## 🎯 Features

- ✅ SwiftUI-based architecture
- ✅ Comprehensive design token system
- ✅ Type-safe color and typography constants
- ✅ SF Symbols integration
- ✅ Git-ready project structure
- ✅ Xcode Asset Catalog support
- ✅ Collaborative development setup

## 📱 Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.3+

---

**Built with ❤️ using SwiftUI and Design Tokens**