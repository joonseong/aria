import SwiftUI

struct SplashView: View {
    @State private var isContentVisible = false
    @State private var shouldNavigate = false
    @StateObject private var appState = AppState()
    
    var body: some View {
        GeometryReader { geometry in
            Color.system.Shape.background
                .ignoresSafeArea()
                .overlay {
                    VStack(spacing: 24) {
                        // Logo Icon
                        Image.systemIcon(.logo)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .foregroundColor(Color.system.Foreground.Invert.primary)
                        
                        // Multiline Korean Text
                        Text("신인 아티스트를 위한\n온라인 갤러리, 아리아")
                            .font(TextStyle.body2.swiftUIFont)
                            .foregroundColor(Color.system.Foreground.Invert.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .opacity(isContentVisible ? 1.0 : 0.0)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * 0.4
                    )
                }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Fade in animation
            withAnimation(.easeInOut(duration: 1.0)) {
                isContentVisible = true
            }
            
            // Navigate after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                shouldNavigate = true
            }
        }
        .fullScreenCover(isPresented: $shouldNavigate) {
            if appState.isLoggedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
    }
}

// MARK: - Supporting Views (Placeholder implementations)

struct HomeView: View {
    var body: some View {
        NavigationView {
            Text("Home View")
                .navigationTitle("Home")
        }
    }
}

struct LoginView: View {
    var body: some View {
        NavigationView {
            Text("Login View")
                .navigationTitle("Login")
        }
    }
}

// MARK: - App State Management

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    
    init() {
        // Check user login status from UserDefaults, Keychain, or other persistence
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    }
}

// MARK: - TextStyle Extension for SwiftUI Font

extension TextStyle {
    var swiftUIFont: Font {
        return Font.system(size: self.fontSize, weight: self.fontWeight)
    }
}

#Preview {
    SplashView()
}