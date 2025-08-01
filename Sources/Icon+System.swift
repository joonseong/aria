import SwiftUI

/// Icon name definitions for the iOS app
/// This enum contains reusable icon asset names
/// Usage: Image.systemIcon(.heart)
enum IconName: String {
    case back = "icon.back"
    case balloon = "icon.balloon"
    case calendar = "icon.calendar"
    case close = "icon.close"
    case down = "icon.down"
    case heart = "icon.heart"
    case logo = "icon.logo"
    case multiple = "icon.multiple"
    case picture = "icon.picture"
    case plus = "icon.plus"
    case profile = "icon.profile"
    case search = "icon.search"
    case share = "icon.share"
    case up = "icon.up"
}

/// Extension for easy Image creation with system icons
extension Image {
    
    /// Creates an Image with an icon name from the IconName enum
    /// - Parameter name: The IconName enum case
    /// - Returns: An Image view with the specified icon asset
    static func systemIcon(_ name: IconName) -> Image {
        return Image(name.rawValue)
    }
}

// MARK: - Usage Examples
/*
 
 // Basic usage
 Image.systemIcon(.heart)
     .resizable()
     .frame(width: 24, height: 24)
     .foregroundColor(.red)
 
 // In a button
 Button(action: {}) {
     Image.systemIcon(.plus)
 }
 
 // With modifiers
 Image.systemIcon(.search)
     .font(.title2)
     .foregroundColor(.blue)
 
 */