import SwiftUI

extension Color {
    
    struct System {
        
        // MARK: - Shape Colors
        
        struct Shape {
            static let background = Color.gs50
            static let `default` = Color.gs0
            static let depth1 = Color.gs50
            static let depth2 = Color.gs100
            static let primary = Color.royalblue500
            static let secondary = Color.royalblue700
            static let tertiary = Color.royalblue500
            static let quaternary = Color.royalblue500
            static let error = Color.red600
            static let disabled = Color.gs100
            static let reddepth = Color.gs100
            static let blurdepth = Color.gs100
            static let yellowdepth = Color.gs100
            static let greendepth = Color.gs100
            static let deco = Color.gs100
        }
        
        // MARK: - Border Colors
        
        struct Border {
            static let block = Color.gs300
            static let primary = Color.gs200
            static let secondary = Color.gs100
            static let point = Color.royalblue600
            static let error = Color.red600
            static let invert = Color.gs900
        }
        
        // MARK: - Foreground Colors
        
        struct Foreground {
            static let primary = Color.gs1000
            static let secondary = Color.gs900
            static let tertiary = Color.gs700
            static let placeholder = Color.gs500
            static let disabled = Color.gs400
            static let point = Color.royalblue600
            static let pointactive = Color.royalblue600
            static let error = Color.red600
            static let careful = Color.red600
            static let correct = Color.red600
            static let link = Color.blue600
            
            // MARK: - Invert Foreground Colors
            
            struct Invert {
                static let primary = Color.gs0
                static let secondary = Color.gs200
            }
        }
    }
    
    // MARK: - System Color Access
    
    static let system = System.self
}