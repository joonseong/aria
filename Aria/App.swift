import SwiftUI

/// Main application entry point for the iOS SwiftUI app
/// This file contains the App protocol implementation and defines the main scene
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Main content view for the application
/// Replace this with your app's main interface
struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, SwiftUI!")
                .font(.largeTitle)
                .padding()
            
            Text("Welcome to your new iOS app")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}