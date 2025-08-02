import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
}
