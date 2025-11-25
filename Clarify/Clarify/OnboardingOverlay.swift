import SwiftUI

struct OnboardingOverlay: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissOnboarding()
                }
            
            VStack(spacing: 32) {
                Spacer()
                
                // Welcome content
                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: "book.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    // Title
                    Text("Welcome to Clarify")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Features list
                    VStack(alignment: .leading, spacing: 16) {
                        OnboardingFeature(
                            icon: "textformat.size",
                            title: "Customize Text",
                            description: "Tap 'Aa' to adjust fonts and reading preferences"
                        )
                        
                        OnboardingFeature(
                            icon: "book",
                            title: "Reading Tools",
                            description: "Use Center Stage and Tunnel Vision for focused reading"
                        )
                        
                        OnboardingFeature(
                            icon: "brain.head.profile",
                            title: "AI Summary",
                            description: "Get instant AI-powered summaries of any article"
                        )
                        
                        OnboardingFeature(
                            icon: "heart.fill",
                            title: "Save Favorites",
                            description: "Heart articles to save them to your favorites collection"
                        )
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Get Started button
                Button(action: dismissOnboarding) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private func dismissOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
        
        // Save that onboarding has been shown
        UserDefaults.standard.set(true, forKey: "HasShownReadingOnboarding")
        HapticsManager.shared.lightImpact()
    }
}

struct OnboardingFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingOverlay(isPresented: .constant(true))
}
