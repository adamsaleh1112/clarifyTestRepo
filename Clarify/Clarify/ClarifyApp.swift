import SwiftUI
// Firebase will be activated once SDK is properly added
// import FirebaseCore

@main
struct ClarifyApp: App {
    @AppStorage("appearance") private var appearance: Appearance = .system
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    // Will be activated once Firebase SDK is added:
    // @StateObject private var userManager = FirebaseUserManager.shared

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                ContentView()
                    .preferredColorScheme(getPreferredColorScheme())
                    .onOpenURL { url in
                        handleIncomingURL(url)
                    }
            } else {
                LoginView()
                    .preferredColorScheme(getPreferredColorScheme())
            }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        print("📱 App received URL: \(url.absoluteString)")
        
        // Post a notification that ContentView can listen to
        NotificationCenter.default.post(
            name: NSNotification.Name("IncomingURL"),
            object: url
        )
    }

    func getPreferredColorScheme() -> ColorScheme? {
        switch appearance {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}
