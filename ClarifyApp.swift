import SwiftUI

@main
struct ClarifyApp: App {
    @AppStorage("appearance") private var appearance: Appearance = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(getPreferredColorScheme())
                .onOpenURL { url in
                    handleIncomingURL(url)
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
