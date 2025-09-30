import SwiftUI

@main
struct ClarifyApp: App {
    @AppStorage("appearance") private var appearance: Appearance = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(getPreferredColorScheme())
        }
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
