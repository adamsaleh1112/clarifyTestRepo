import SwiftUI

struct ReadAloudControlPill: View {
    @ObservedObject var readAloudManager = ReadAloudManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            playPauseButton
            speedControlButton
            closeButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(pillBackground)
        .scaleEffect(isVisible ? 1.0 : 0.3)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: isVisible)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
    }
    
    private var playPauseButton: some View {
        Button(action: {
            if readAloudManager.isReading {
                readAloudManager.pauseReading()
            } else if readAloudManager.synthesizer.isPaused {
                readAloudManager.resumeReading()
            } else {
                readAloudManager.stopReading()
            }
        }) {
            let iconName = readAloudManager.isReading ? "pause.fill" : "play.fill"
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(prominentButtonIconColor)
                .frame(width: 44, height: 44)
                .background(prominentButtonBackground)
                .overlay(prominentButtonStroke)
        }
        .accessibilityLabel(readAloudManager.isReading ? "Pause" : "Play")
    }
    
    private var speedControlButton: some View {
        Menu {
            ForEach(0..<readAloudManager.speedLabels.count, id: \.self) { index in
                Button(action: {
                    readAloudManager.changeSpeed(to: index)
                }) {
                    HStack {
                        Text(readAloudManager.speedLabels[index])
                            .font(.system(size: 15, weight: .medium))
                        if readAloudManager.selectedSpeedIndex == index {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                    }
                }
            }
        } label: {
            let currentSpeed = readAloudManager.speedLabels[readAloudManager.selectedSpeedIndex]
            Text(currentSpeed)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("Reading speed")
    }
    
    private var closeButton: some View {
        Button(action: {
            readAloudManager.stopReading()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("Stop reading")
    }
    
    private var pillBackground: some View {
        Capsule()
            .fill(pillFillColor)
            .overlay(
                Capsule()
                    .stroke(pillStrokeColor, lineWidth: 0.5)
            )
            .shadow(color: primaryShadowColor, radius: 12, x: 0, y: 4)
            .shadow(color: secondaryShadowColor, radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Design System Colors
    private var buttonBackground: some View {
        Circle()
            .fill(buttonFillColor)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var buttonStroke: some View {
        Circle()
            .stroke(buttonStrokeColor, lineWidth: 0.5)
    }
    
    private var buttonFillColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.white
    }
    
    private var buttonStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1)
    }
    
    private var buttonIconColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var accentColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    // MARK: - Prominent Button (Play/Pause)
    private var prominentButtonBackground: some View {
        Circle()
            .fill(prominentButtonFillColor)
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
    
    private var prominentButtonStroke: some View {
        Circle()
            .stroke(prominentButtonStrokeColor, lineWidth: 0.5)
    }
    
    private var prominentButtonFillColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.95) : Color.black.opacity(0.9)
    }
    
    private var prominentButtonStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2)
    }
    
    private var prominentButtonIconColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.85) : Color.white.opacity(0.95)
    }
    
    private var iconColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.7)
    }
    
    private var pillFillColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.85) : Color.white.opacity(0.98)
    }
    
    private var pillStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
    
    private var primaryShadowColor: Color {
        Color.black.opacity(colorScheme == .dark ? 0.5 : 0.15)
    }
    
    private var secondaryShadowColor: Color {
        Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05)
    }
}
