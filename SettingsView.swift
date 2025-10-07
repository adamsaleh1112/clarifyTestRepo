import SwiftUI

struct SettingsView: View {
    @AppStorage("appearance") private var appearance: Appearance = .system
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            // Back Button
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                        .frame(width: 44, height: 44)
                        .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke, lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                }
                Spacer()
            }
            .padding(.horizontal, 26)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Custom Header
            HStack {
                Text("Settings")
                    .font(.system(size: 32.3, weight: .bold, design: .default))
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                Spacer()
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 30)
            
            // Settings Content
            VStack(spacing: 20) {
                // Appearance Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Appearance")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                        Spacer()
                    }
                    
                    // Custom Segmented Control
                    HStack(spacing: 0) {
                        ForEach(Appearance.allCases, id: \.self) { option in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    appearance = option
                                }
                            }) {
                                Text(option.rawValue.capitalized)
                                    .font(.system(size: 14, weight: .medium, design: .default))
                                    .foregroundColor(appearance == option ? 
                                        (colorScheme == .dark ? Color.themeBlack : Color.themeWhiteDark) : 
                                        (colorScheme == .dark ? Color.themeWhiteDark.opacity(0.7) : Color.themeBlack.opacity(0.7)))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(appearance == option ? 
                                                (colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack) : 
                                                Color.clear)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke, lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 26)
                
                Spacer()
            }
        }
        .background((colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground).ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
