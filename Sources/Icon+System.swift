import SwiftUI

/// System icon definitions for the iOS app
/// This file contains reusable system icon constants using SF Symbols
/// Usage: Image(systemName: SystemIcon.home)
struct SystemIcon {
    
    // MARK: - Navigation Icons
    
    static let home = "house"
    static let search = "magnifyingglass"
    static let profile = "person.circle"
    static let settings = "gearshape"
    
    // MARK: - Action Icons
    
    static let add = "plus"
    static let edit = "pencil"
    static let delete = "trash"
    static let share = "square.and.arrow.up"
    
    // MARK: - Status Icons
    
    static let checkmark = "checkmark.circle"
    static let warning = "exclamationmark.triangle"
    static let error = "xmark.circle"
    static let info = "info.circle"
    
    // MARK: - Arrow Icons
    
    static let chevronRight = "chevron.right"
    static let chevronLeft = "chevron.left"
    static let chevronUp = "chevron.up"
    static let chevronDown = "chevron.down"
}

/// Extension for easy Image creation with system icons
extension Image {
    
    /// Creates an Image with a system icon name
    /// - Parameter systemIcon: The system icon name constant
    /// - Returns: An Image view with the specified system icon
    static func systemIcon(_ name: String) -> Image {
        Image(systemName: name)
    }
}