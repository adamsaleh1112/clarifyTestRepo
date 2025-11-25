import UIKit
import AVFoundation

class HapticsManager {
    static let shared = HapticsManager()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    private var soundsEnabled: Bool {
        UserDefaults.standard.bool(forKey: "HapticSoundsEnabled")
    }
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    func lightImpact() {
        impactLight.impactOccurred()
    }
    
    func mediumImpact() {
        impactMedium.impactOccurred()
    }
    
    func heavyImpact() {
        impactHeavy.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    func selectionChanged() {
        selection.selectionChanged()
    }
    
    // MARK: - Notification Feedback
    
    func success() {
        notification.notificationOccurred(.success)
        if soundsEnabled {
            playSuccessSound()
        }
    }
    
    func warning() {
        notification.notificationOccurred(.warning)
    }
    
    func error() {
        notification.notificationOccurred(.error)
    }
    
    // MARK: - App-Specific Haptics
    
    func favoriteToggled() {
        mediumImpact()
        if soundsEnabled {
            playFavoriteSound()
        }
    }
    
    func readingToolToggled() {
        lightImpact()
    }
    
    func summaryGenerated() {
        success()
    }
    
    func articleOpened() {
        lightImpact()
    }
    
    // MARK: - Sound Effects
    
    private func playSuccessSound() {
        AudioServicesPlaySystemSound(1519) // Peek sound
    }
    
    private func playFavoriteSound() {
        AudioServicesPlaySystemSound(1520) // Pop sound
    }
    
    // MARK: - Settings
    
    func setSoundsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "HapticSoundsEnabled")
    }
}
