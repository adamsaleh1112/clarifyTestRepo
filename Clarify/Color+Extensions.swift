import SwiftUI

// This extension allows us to define custom colors for light and dark modes.
// It's a cleaner approach than putting UI-specific colors inside views.

extension Color {
    // Theme Colors - Light and Dark Mode Adaptive
    static let customBackgroundColor = Color(hex: "FEFCFB") // Light mode background
    static let customSecondaryBackgroundColor = Color(hex: "F0ECEA") // Light mode raised elements
    static let customButtonBackgroundColor = Color(hex: "F0ECEA") // Light mode raised elements
    static let customTextPrimary = Color(hex: "312D2B") // Light mode high contrast text
    static let customTextSecondary = Color(hex: "69605B") // Light mode low contrast text
    
    // Direct theme colors for manual use
    static let themeBackground = Color(hex: "FEFCFB") // Light mode background
    static let themeBackgroundDark = Color(hex: "201D1D") // Dark mode background
    static let themeWhite = Color(hex: "312D2B") // Light mode high contrast text (renamed for clarity)
    static let themeWhiteDark = Color(hex: "ECE3DF") // Dark mode high contrast text
    static let themeGrey = Color(hex: "69605B") // Light mode low contrast text
    static let themeGreyDark = Color(hex: "8A827E") // Dark mode low contrast text
    static let themeBlack = Color(hex: "312D2B") // Light mode high contrast text
    static let themeBlackDark = Color(hex: "8A827E") // Dark mode low contrast text (for subtle elements)
    
    // Raised element colors (cards, buttons, covers)
    static let themeRaised = Color(hex: "F0ECEA") // Light mode raised elements
    static let themeRaisedDark = Color(hex: "2C2928") // Dark mode raised elements
    
    // Stroke colors for raised elements
    static let themeStroke = Color(hex: "B8B4B0") // Light mode subtle strokes
    static let themeStrokeDark = Color(hex: "494544") // Dark mode subtle strokes
}

// This helper extension allows creating Colors from a hex string like #101010.
// It's not strictly necessary if using an Asset Catalog, but makes the code more readable.
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
