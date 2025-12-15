import SwiftUI
import FirebaseCore

// Firebase App Delegate
class FirebaseAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct ClarifyApp: App {
    @UIApplicationDelegateAdaptor(FirebaseAppDelegate.self) var delegate
    @AppStorage("appearance") private var appearance: Appearance = .system
    @StateObject private var userManager = FirebaseUserManager.shared

    var body: some Scene {
        WindowGroup {
            if userManager.isLoggedIn {
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