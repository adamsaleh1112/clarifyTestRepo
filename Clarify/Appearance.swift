import Foundation

enum Appearance: String, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { self.rawValue }
}
