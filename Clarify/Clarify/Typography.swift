import Foundation

enum Typography: String, CaseIterable, Identifiable {
    case modern = "modern"
    case serif = "serif"
    case condensedSerif = "condensedSerif"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .modern:
            return "Modern"
        case .serif:
            return "Serif"
        case .condensedSerif:
            return "Condensed"
        }
    }
}
