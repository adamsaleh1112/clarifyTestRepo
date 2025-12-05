import SwiftUI

extension Font {
    // Typography-aware system fonts
    static func appFont(size: CGFloat, weight: Font.Weight = .regular, typography: Typography = .modern) -> Font {
        switch typography {
        case .modern:
            return .system(size: size, weight: weight, design: .default)
        case .serif:
            return .system(size: size, weight: weight, design: .serif)
        case .condensedSerif:
            return .system(size: size, weight: weight, design: .serif).width(.condensed)
        }
    }
    
    // Convenience methods for common UI elements
    static func appTitle(typography: Typography = .modern) -> Font {
        appFont(size: 32.3, weight: .bold, typography: typography)
    }
    
    static func appHeading(typography: Typography = .modern) -> Font {
        appFont(size: 22, weight: .bold, typography: typography)
    }
    
    static func appSubheading(typography: Typography = .modern) -> Font {
        appFont(size: 18, weight: .semibold, typography: typography)
    }
    
    static func appBody(typography: Typography = .modern) -> Font {
        appFont(size: 16, weight: .medium, typography: typography)
    }
    
    static func appCaption(typography: Typography = .modern) -> Font {
        appFont(size: 14, weight: .medium, typography: typography)
    }
    
    static func appSmall(typography: Typography = .modern) -> Font {
        appFont(size: 12, weight: .medium, typography: typography)
    }
}
