import SwiftUI

struct SplashView: View {
    @State private var isContentVisible = false
    @State private var shouldNavigate = false
    @EnvironmentObject var appState: AppState
    // @StateObject private var appState = AppState()
    
    var body: some View {
        GeometryReader { geometry in
            Color.system.Shape.primary
                .ignoresSafeArea()
                .overlay {
                    VStack(spacing: 24) {
                        // Logo Icon
                        Image("icon.logoWhite")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 64)
                        
                        // Multiline Korean Text
                        Text("신인 아티스트를 위한\n온라인 갤러리, 아리아")
                            .font(AriaTextStyle.body2.swiftUIFont)
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

// MARK: - TextStyle Extension for SwiftUI Font

extension AriaTextStyle {
    var swiftUIFont: Font {
        return Font.system(size: self.fontSize, weight: self.fontWeight)
    }
}

// MARK: - Preview

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
            .environmentObject(AppState()) // ✅ 환경 객체 주입
    }
}
