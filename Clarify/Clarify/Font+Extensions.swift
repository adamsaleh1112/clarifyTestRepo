import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Font {
    // MARK: - Debug Helper (remove in production)
    static func printAvailableFonts() {
        #if DEBUG
        print("=== Available Font Families ===")
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  - \(name)")
            }
        }
        print("================================")
        
        // Check specific fonts we're trying to use (based on actual file names)
        let fontsToCheck = [
            "InstrumentSerif-Regular",
            "InstrumentSerif-Italic",
            "InstrumentSerif-Bold", 
            "InstrumentSerif-SemiBold",
            "InstrumentSerif-Medium",
            "SourceSerif4-VariableFont_opsz,wght",
            "SourceSerif4-Italic-VariableFont_opsz,wght",
            "Source Serif 4",
            "SourceSerif4"
        ]
        
        print("=== Font Availability Check ===")
        for fontName in fontsToCheck {
            let isAvailable = UIFont(name: fontName, size: 16) != nil
            print("\(fontName): \(isAvailable ? "✅ Available" : "❌ Not Found")")
        }
        print("===============================")
        #endif
    }
    
    // MARK: - New Font Hierarchy
    
    // UI Headings: Light System Serif (iOS accessibility independent)
    static func uiHeading(size: CGFloat) -> Font {
        return .system(size: size, weight: .light, design: .serif)
    }
    
    // UI Headings: Medium System Serif (iOS accessibility independent)
    static func uiHeadingBold(size: CGFloat) -> Font {
        return .system(size: size, weight: .medium, design: .serif)
    }
    
    // Article Card Titles: Medium System Serif (iOS accessibility independent)
    static func articleCardTitle(size: CGFloat) -> Font {
        return .system(size: size, weight: .medium, design: .serif)
    }
    
    // UI Generic Text: Sans Serif for non-serif contexts
    static func uiGeneric(size: CGFloat, weight: Font.Weight = .medium) -> Font {
        return .system(size: size, weight: weight, design: .default)
    }
    
    // MARK: - Accessibility Independent Font Helper
    // Creates fonts that ignore iOS Bold Text accessibility setting
    private static func accessibilityIndependentFont(name: String, size: CGFloat) -> Font {
        // Use fixed size to prevent iOS accessibility scaling conflicts
        return .custom(name, fixedSize: size)
    }
    
    // Article Headings: Condensed Medium System Serif
    static func articleHeading(size: CGFloat) -> Font {
        return .system(size: size, weight: .medium, design: .serif).width(.condensed)
    }
    
    // Article Text: Light System Serif
    static func articleText(size: CGFloat, weight: Font.Weight = .light) -> Font {
        return .system(size: size, weight: .ultraLight, design: .serif)
    }
    
    // Article Text with custom weight mapping using System Serif
    static func articleTextWithWeight(size: CGFloat, weightValue: Double) -> Font {
        // Use clean system serif with proper weight mapping
        let systemWeight: Font.Weight
        switch weightValue {
        case 0.0...0.3: systemWeight = .ultraLight
        case 0.3...0.5: systemWeight = .light
        case 0.5...0.7: systemWeight = .regular
        case 0.7...0.9: systemWeight = .medium
        case 0.9...1.0: systemWeight = .bold
        default: systemWeight = .light
        }
        return .system(size: size, weight: systemWeight, design: .serif)
    }
    
    // Article Captions: Clean System Serif Italic
    static func articleCaption(size: CGFloat = 14) -> Font {
        return .system(size: size, weight: .regular, design: .serif).italic()
    }
    
    // MARK: - Convenience methods for common UI elements
    static func appTitle() -> Font {
        uiHeading(size: 32.3)  // Use same light weight as Settings
    }
    
    static func appHeading() -> Font {
        uiHeading(size: 22)    // Use same light weight as Settings
    }
    
    static func appSubheading() -> Font {
        uiGeneric(size: 18, weight: .semibold)
    }
    
    static func appBody() -> Font {
        uiGeneric(size: 16, weight: .medium)
    }
    
    static func appCaption() -> Font {
        uiGeneric(size: 14, weight: .medium)
    }
    
    static func appSmall() -> Font {
        uiGeneric(size: 12, weight: .medium)
    }
    
    // MARK: - Legacy compatibility removed
    // Typography-based font selection has been removed for design consistency
}
