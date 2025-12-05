import Foundation
import AVFoundation
import SwiftUI

class ReadAloudManager: NSObject, ObservableObject {
    static let shared = ReadAloudManager()
    
    @Published var isReading = false
    @Published var currentWordRange: NSRange?
    @Published var speechRate: Float = 0.5 // Default 1x speed
    @Published var isVisible = false
    
    var synthesizer = AVSpeechSynthesizer()
    private var currentText = ""
    private var currentUtterance: AVSpeechUtterance?
    private var wordRanges: [NSRange] = []
    private var currentWordIndex = 0
    private var isChangingSpeed = false
    
    // Speed multipliers
    let speedOptions: [Float] = [0.4, 0.5, 0.6, 0.8] // 1x, 1.25x, 1.5x, 2x
    let speedLabels = ["1x", "1.25x", "1.5x", "2x"]
    @Published var selectedSpeedIndex = 0
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        #endif
    }
    
    func startReading(text: String) {
        guard !text.isEmpty else { return }
        
        self.currentText = text
        self.wordRanges = extractWordRanges(from: text)
        self.currentWordIndex = 0
        self.currentWordRange = wordRanges.first
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speedOptions[selectedSpeedIndex]
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Store the utterance for word tracking
        currentUtterance = utterance
        
        synthesizer.speak(utterance)
        isReading = true
        isVisible = true
    }
    
    func pauseReading() {
        synthesizer.pauseSpeaking(at: .immediate)
        isReading = false
    }
    
    func resumeReading() {
        synthesizer.continueSpeaking()
        isReading = true
    }
    
    func stopReading() {
        synthesizer.stopSpeaking(at: .immediate)
        isReading = false
        isVisible = false
        currentWordRange = nil
        currentWordIndex = 0
    }
    
    func changeSpeed(to index: Int) {
        selectedSpeedIndex = index
        
        // If currently reading, restart with new speed
        if isReading {
            let wasReading = !synthesizer.isPaused
            isChangingSpeed = true
            synthesizer.stopSpeaking(at: .immediate)
            
            // Create new utterance with updated speed
            let remainingText = getRemainingText()
            if !remainingText.isEmpty {
                let utterance = AVSpeechUtterance(string: remainingText)
                utterance.rate = speedOptions[selectedSpeedIndex]
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                
                currentUtterance = utterance
                if wasReading {
                    synthesizer.speak(utterance)
                }
            }
            isChangingSpeed = false
        }
    }
    
    private func getRemainingText() -> String {
        guard currentWordIndex < wordRanges.count else { return "" }
        let startRange = wordRanges[currentWordIndex]
        let startIndex = currentText.index(currentText.startIndex, offsetBy: startRange.location)
        return String(currentText[startIndex...])
    }
    
    private func extractWordRanges(from text: String) -> [NSRange] {
        var ranges: [NSRange] = []
        let nsString = text as NSString
        
        nsString.enumerateSubstrings(in: NSRange(location: 0, length: nsString.length),
                                   options: [.byWords, .localized]) { (substring, range, _, _) in
            if substring != nil {
                ranges.append(range)
            }
        }
        
        return ranges
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension ReadAloudManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // Find the word that contains this character range
            for (index, wordRange) in self.wordRanges.enumerated() {
                if NSLocationInRange(characterRange.location, wordRange) {
                    self.currentWordRange = wordRange
                    self.currentWordIndex = index
                    break
                }
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // Don't hide the pill if we're just changing speed
            if !self.isChangingSpeed {
                self.isReading = false
                self.isVisible = false
                self.currentWordRange = nil
                self.currentWordIndex = 0
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isReading = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isReading = true
        }
    }
}
