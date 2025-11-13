import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    @State private var scrollOffset: CGFloat = 0
    @State private var screenHeight: CGFloat = 0
    @State private var centeredBlockIndex: Int? = nil
    @State private var blockPositions: [Int: CGRect] = [:]
    @State private var showFontCustomization = false
    @State private var selectedFont = "Source Serif Pro"
    @State private var fontSize: Double = 17.0
    @State private var lineSpacing: Double = 6.0
    @State private var showReadingTools = false
    @State private var centerStageEnabled = true
    @State private var tunnelVisionEnabled = false
    @State private var bionicReadingEnabled = false
    @State private var isReadingAloud = false
    @State private var currentReadingWordIndex = -1
    @State private var showAIChat = false
    
    // Annotation Mode States
    @State private var annotationMode = false
    
    // Store original reading tool states for restoration
    @State private var originalCenterStageEnabled = true
    @State private var originalTunnelVisionEnabled = false
    @State private var originalBionicReadingEnabled = false

    var body: some View {
        ZStack {
            // Background with blurred cover image
            backgroundView
            
            // Article Content
            GeometryReader { outerGeometry in
                ScrollView {
                    GeometryReader { geometry in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        headerView
                        contentView
                    }
                    .frame(maxWidth: 680)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 16)
                    .padding(.top, 60) // Add top padding to account for floating button
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    updateCenteredBlock()
                }
                .onAppear {
                    screenHeight = outerGeometry.size.height
                }
            }
            
            // Top gradient overlay for back button separation
            VStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: (colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground).opacity(0.95), location: 0.0),
                        .init(color: (colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground).opacity(0.85), location: 0.3),
                        .init(color: (colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground).opacity(0.6), location: 0.6),
                        .init(color: (colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground).opacity(0.2), location: 0.8),
                        .init(color: Color.clear, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 125)
                .scaleEffect(1.2)
                .blur(radius: 8)
                .ignoresSafeArea(.all)
                
                Spacer()
            }
            
            // Floating Navigation Buttons
            VStack {
                HStack {
                    // Back Button (Left)
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
                    
                    // Top Right Buttons
                    HStack(spacing: 12) {
                        // Text Customization Button
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showFontCustomization = true
                            }
                        } label: {
                            Text("Aa")
                                .font(.system(size: 16, weight: .semibold))
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
                        
                        // Reading Customization Button
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showReadingTools = true
                            }
                        } label: {
                            Image(systemName: "book")
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
                        
                        // Annotation Button
                        Button {
                            toggleAnnotationMode()
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(annotationMode ? 
                                               (colorScheme == .dark ? Color.themeBlack : Color.themeWhiteDark) :
                                               (colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack))
                                .frame(width: 44, height: 44)
                                .background(annotationMode ? 
                                          (colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack) :
                                          (colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke, lineWidth: 0.5)
                                )
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                
                Spacer()
                
                // Bottom buttons layout
                HStack {
                    // Annotation Tools Pill (Left)
                    if annotationMode {
                        annotationToolsPill
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // AI Companion Button (Bottom Right)
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showAIChat = true
                        }
                    } label: {
                        Image("clarify-logo")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(colorScheme == .dark ? Color.themeBlack : Color.themeWhiteDark)
                            .frame(width: 70, height: 70)
                            .background(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                            .clipShape(Circle())
                            .shadow(color: Color.themeBlack.opacity(0.12), radius: 10, x: 0, y: 6)
                    }
                }
                .padding(.bottom, 35)
            }
            .padding(.horizontal, 26)
            .padding(.top, 20)
            
            // Font Customization Overlay
            fontCustomizationOverlay
            
            // Reading Tools Overlay
            readingToolsOverlay
        }
        .sheet(isPresented: $showAIChat) {
            AIChatView(
                articleTitle: article.title,
                articleContent: article.content.map { content in
                    switch content {
                    case .paragraph(let text), .heading(let text, _):
                        return text
                    case .richParagraph(let segments):
                        return segments.map { segment in
                            switch segment {
                            case .text(let text), .boldText(let text), .italicText(let text), .link(let text, _):
                                return text
                            }
                        }.joined(separator: " ")
                    case .quote(let text, _):
                        return text
                    case .list(let items, _):
                        return items.joined(separator: "\n")
                    default:
                        return ""
                    }
                }.joined(separator: "\n\n")
            )
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Font Customization
    private var customFont: Font {
        switch selectedFont {
        case "Source Serif Pro":
            return .system(size: fontSize, weight: .medium, design: .serif)
        case "Times New Roman":
            return .custom("Times New Roman", size: fontSize)
        case "Georgia":
            return .custom("Georgia", size: fontSize)
        case "System Sans Serif":
            return .system(size: fontSize, weight: .medium, design: .default)
        default:
            return .system(size: fontSize, weight: .medium, design: .serif)
        }
    }
    
    private func fontForButton(_ fontName: String) -> Font {
        switch fontName {
        case "Source Serif Pro":
            return .system(size: 14, weight: .medium, design: .serif)
        case "Times New Roman":
            return .custom("Times New Roman", size: 14)
        case "Georgia":
            return .custom("Georgia", size: 14)
        case "System Sans Serif":
            return .system(size: 14, weight: .medium, design: .default)
        default:
            return .system(size: 14, weight: .medium)
        }
    }
    
    private var fontCustomizationOverlay: some View {
        ZStack {
            // Background overlay (separate animation)
            if showFontCustomization {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showFontCustomization = false
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: showFontCustomization)
            }
            
            // Customization panel (separate animation)
            if showFontCustomization {
                VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Text Customization")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showFontCustomization = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                            .frame(width: 32, height: 32)
                            .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                            .clipShape(Circle())
                    }
                }
                
                // Font Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Font Family")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    
                    let fonts = ["Source Serif Pro", "Times New Roman", "Georgia", "System Sans Serif"]
                    
                    VStack(spacing: 8) {
                        ForEach(fonts, id: \.self) { font in
                            Button {
                                selectedFont = font
                            } label: {
                                HStack {
                                    Text(font)
                                        .font(fontForButton(font))
                                        .foregroundColor(selectedFont == font ? 
                                                       (colorScheme == .dark ? Color.themeBlack : Color.themeWhiteDark) :
                                                       (colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack))
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(selectedFont == font ? 
                                          (colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack) :
                                          (colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Font Size Slider
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Text Size")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                        
                        Spacer()
                        
                        Text("\(Int(fontSize))pt")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color.themeGreyDark : Color.themeGrey)
                    }
                    
                    Slider(value: $fontSize, in: 12...24, step: 1)
                        .accentColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                }
                
                // Line Spacing Slider
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Line Spacing")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                        
                        Spacer()
                        
                        Text("\(Int(lineSpacing))pt")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color.themeGreyDark : Color.themeGrey)
                    }
                    
                    Slider(value: $lineSpacing, in: 2...16, step: 1)
                        .accentColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                }
                }
                .padding(24)
                .background(colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 32)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showFontCustomization)
            }
        }
    }
    
    private var readingToolsOverlay: some View {
        ZStack {
            // Background overlay (separate animation)
            if showReadingTools {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showReadingTools = false
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: showReadingTools)
            }
            
            // Reading Tools panel (separate animation)
            if showReadingTools {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Reading Tools")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showReadingTools = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                                .frame(width: 32, height: 32)
                                .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                                .clipShape(Circle())
                        }
                    }
                    
                    // Reading Features Toggles
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reading Features")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                        
                        // Center Stage Reading Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Center Stage Reading")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                                
                                Text("Scales text in focus for better readability")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(colorScheme == .dark ? Color.themeGreyDark : Color.themeGrey)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $centerStageEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                        .cornerRadius(8)
                        
                        // Tunnel Vision Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tunnel Vision Reading")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                                
                                Text("Blurs text that isn't in focus")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(colorScheme == .dark ? Color.themeGreyDark : Color.themeGrey)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $tunnelVisionEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                        .cornerRadius(8)
                        
                        // Bionic Reading Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bionic Reading")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                                
                                Text("Bolds the first half of each word")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(colorScheme == .dark ? Color.themeGreyDark : Color.themeGrey)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $bionicReadingEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                        .cornerRadius(8)
                    }
                    
                    // Read Aloud Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Audio")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                        
                        Button {
                            toggleReadAloud()
                        } label: {
                            HStack {
                                Image(systemName: isReadingAloud ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(colorScheme == .dark ? Color.themeBlack : Color.themeWhiteDark)
                                
                                Text(isReadingAloud ? "Pause Reading" : "Read Aloud")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? Color.themeBlack : Color.themeWhiteDark)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(24)
                .background(colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 32)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showReadingTools)
            }
        }
    }
    
    private func toggleReadAloud() {
        isReadingAloud.toggle()
        if isReadingAloud {
            startReadingAloud()
        } else {
            stopReadingAloud()
        }
    }
    
    private func startReadingAloud() {
        // TODO: Implement text-to-speech functionality
        print("Starting read aloud...")
    }
    
    private func stopReadingAloud() {
        // TODO: Stop text-to-speech
        print("Stopping read aloud...")
    }
    
    private var headerView: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer().frame(height: 40)
            
            // Source information (logo + name)
            if let sourceName = article.sourceName {
                HStack(alignment: .center, spacing: 8) {
                    // Source logo (if available)
                    if let logoURL = article.sourceLogoURL {
                        AsyncImage(url: logoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            // Fallback to colored circle with first letter
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    Text(String(sourceName.prefix(1)))
                                        .font(.system(size: 10, weight: .semibold, design: .default))
                                        .foregroundColor(.blue)
                                )
                        }
                        .frame(width: 20, height: 20)
                    }
                    
                    // Source name
                    Text(sourceName.uppercased())
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(colorScheme == .dark ? Color.themeGreyDark : Color.themeGrey)
                        .tracking(0.5)
                }
                .padding(.bottom, 8)
            }
            
            // Article title (centered, serif font)
            Text(article.title)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .lineSpacing(6)
                .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            
            // Horizontal line separator
            Rectangle()
                .fill(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke)
                .frame(height: 1)
                .frame(maxWidth: 120)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var backgroundView: some View {
        GeometryReader { geometry in
            ZStack {
                // Base background color
                (colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground)
                    .ignoresSafeArea()
                
                // Blurred cover image overlay - positioned absolutely (top 1/3 only)
                if let coverImageURL = article.coverImageURL {
                    VStack {
                        AsyncImage(url: coverImageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height / 3)
                                .blur(radius: 16.5) // 50% of 33
                                .opacity(imageOpacity)
                                .clipped()
                                .mask(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .white.opacity(0.5), location: 0.0),   // 50% at top
                                            .init(color: .white.opacity(0.4), location: 0.2),   // Transition zone
                                            .init(color: .white.opacity(0.15), location: 0.5),  // 15% in middle
                                            .init(color: .white.opacity(0.08), location: 0.7),  // Fade out
                                            .init(color: .white.opacity(0.02), location: 0.9),  // Almost gone
                                            .init(color: .clear, location: 1.0)                 // 0% at bottom
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .animation(.easeInOut(duration: 0.4), value: imageOpacity)
                        } placeholder: {
                            // Fallback to solid background if no image
                            Color.clear
                                .frame(height: geometry.size.height / 3)
                        }
                        Spacer()
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // Calculate image opacity based on whether user is at top of text content
    private var imageOpacity: Double {
        // Check if the first content block (index 0) is the centered/visible block
        // OR if user has scrolled above the content (elastic bounce at top)
        if centeredBlockIndex == 0 || centeredBlockIndex == nil || scrollOffset > 0 {
            return 1.0 // Show image when at top of text content or scrolled above top
        } else {
            return 0.0 // Hide image only when scrolled down past first text block
        }
    }
    
    private var contentView: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ForEach(Array(article.content.enumerated()), id: \.offset) { index, contentItem in
                contentItemView(contentItem, index: index)
                    .scaleEffect(!annotationMode && centerStageEnabled && centeredBlockIndex == index ? 1.05 : 1.0)
                    .blur(radius: !annotationMode && tunnelVisionEnabled ? (centeredBlockIndex == index ? 0 : 4) : 0)
                    .animation(.easeInOut(duration: 0.3), value: centeredBlockIndex)
                    .animation(.easeInOut(duration: 0.4), value: tunnelVisionEnabled)
                    .animation(.easeInOut(duration: 0.3), value: centerStageEnabled)
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: BlockFramePreferenceKey.self, 
                                          value: [index: geometry.frame(in: .named("scroll"))])
                        }
                    )
            }
        }
        .onPreferenceChange(BlockFramePreferenceKey.self) { frames in
            blockPositions.merge(frames) { _, new in new }
            updateCenteredBlock()
        }
    }
    
    @ViewBuilder
    private func contentItemView(_ contentItem: ArticleContent, index: Int) -> some View {
        switch contentItem {
        case .heading(let text, let level):
            headingView(text: text, level: level)
        case .paragraph(let text):
            paragraphView(text: text)
        case .richParagraph(let segments):
            richParagraphView(segments: segments)
        case .image(let url, let caption, let alt):
            imageView(url: url, caption: caption, alt: alt)
        case .quote(let text, let author):
            quoteView(text: text, author: author)
        case .list(let items, let ordered):
            listView(items: items, ordered: ordered)
        case .twitterEmbed(let tweetId, let url):
            twitterEmbedView(tweetId: tweetId, url: url)
        case .linkEmbed(let url, let title, let description):
            linkEmbedView(url: url, title: title, description: description)
        case .videoEmbed(let url, let platform):
            videoEmbedView(url: url, platform: platform)
        case .divider:
            Divider().padding(.vertical, 20)
        }
    }
    
    // MARK: - Content View Functions
    private func headingView(text: String, level: Int) -> some View {
        Group {
            if annotationMode {
                Text(text)
                    .font(.system(size: headingSize(for: level), weight: .bold, design: .serif))
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .padding(.top, level == 1 ? 32 : 24)
                    .padding(.bottom, 12)
            } else {
                Text(text)
                    .font(.system(size: headingSize(for: level), weight: .bold, design: .serif))
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .padding(.top, level == 1 ? 32 : 24)
                    .padding(.bottom, 12)
            }
        }
    }
    
    private func paragraphView(text: String) -> some View {
        Group {
            if annotationMode {
                Text(text)
                    .font(customFont)
                    .lineSpacing(lineSpacing)
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
            } else if bionicReadingEnabled {
                bionicText(text)
                    .lineSpacing(lineSpacing)
            } else {
                Text(text)
                    .font(customFont)
                    .lineSpacing(lineSpacing)
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
            }
        }
        .padding(.bottom, 12)
    }
    
    private func bionicText(_ text: String) -> some View {
        let words = text.components(separatedBy: " ")
        
        return words.enumerated().reduce(Text("")) { result, wordData in
            let (index, word) = wordData
            
            // Add space before each word except the first
            var currentResult = result
            if index > 0 {
                currentResult = currentResult + Text(" ")
            }
            
            // Skip empty words
            if word.isEmpty {
                return currentResult
            }
            
            let wordLength = word.count
            let halfLength = max(1, wordLength / 2)
            
            // Split the word into bold and normal parts
            let boldPart = String(word.prefix(halfLength))
            let normalPart = String(word.dropFirst(halfLength))
            
            // Add the bold part
            currentResult = currentResult + Text(boldPart)
                .fontWeight(.bold)
                .font(customFont)
                .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
            
            // Add the normal part (if it exists)
            if !normalPart.isEmpty {
                currentResult = currentResult + Text(normalPart)
                    .fontWeight(.regular)
                    .font(customFont)
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
            }
            
            return currentResult
        }
    }
    
    private func richParagraphView(segments: [TextSegment]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(segments) { segment in
                    switch segment {
                    case .text(let text):
                        Text(text)
                            .font(.system(size: 17, weight: .medium, design: .serif))
                            .lineSpacing(10)
                            .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    case .boldText(let text):
                        Text(text)
                            .font(.system(size: 17, weight: .bold, design: .serif))
                            .lineSpacing(10)
                            .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    case .italicText(let text):
                        Text(text)
                            .font(.system(size: 17, weight: .medium, design: .serif))
                            .italic()
                            .lineSpacing(10)
                            .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    case .link(let text, let url):
                        Link(text, destination: url)
                            .font(.system(size: 17, weight: .regular, design: .serif))
                            .underline()
                            .foregroundColor(.accentColor)
                    }
                }
                Spacer()
            }
        }
        .padding(.bottom, 16)
    }
    
    private func imageView(url: URL?, caption: String?, alt: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .shadow(color: Color.themeBlack.opacity(0.1), radius: 8, x: 0, y: 4)
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
                    .frame(height: 250)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    )
                    .shadow(color: Color.themeBlack.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            
            if let caption = caption, !caption.isEmpty {
                Text(caption)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 16)
    }
    
    private func quoteView(text: String, author: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if annotationMode {
                Text(text)
                    .font(.system(size: 19, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .padding(.leading, 16)
                    .overlay(
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 4)
                            .padding(.leading, 0),
                        alignment: .leading
                    )
            } else {
                Text(text)
                    .font(.system(size: 19, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .padding(.leading, 16)
                    .overlay(
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 4)
                            .padding(.leading, 0),
                        alignment: .leading
                    )
            }
            
            if let author = author, !author.isEmpty {
                Text("— \(author)")
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
            }
        }
        .padding(.vertical, 16)
    }
    
    private func listView(items: [String], ordered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    Text(ordered ? "\(index + 1)." : "•")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                        .padding(.top, 2)
                        .frame(minWidth: ordered ? 20 : 8, alignment: .leading)
                    Text(item)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .lineSpacing(6)
                        .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    Spacer()
                }
            }
        }
        .padding(.bottom, 16)
    }
    
    private func twitterEmbedView(tweetId: String, url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "logo.twitter")
                    .foregroundColor(.blue)
                Text("Twitter")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Link("View Tweet", destination: url)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(.accentColor)
        }
        .padding(16)
        .background(.thinMaterial)
        .cornerRadius(16)
        .padding(.vertical, 8)
    }
    
    private func linkEmbedView(url: URL, title: String?, description: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .lineLimit(2)
            }
            
            if let description = description {
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            Link(url.host ?? url.absoluteString, destination: url)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(.accentColor)
        }
        .padding(16)
        .background(.thinMaterial)
        .cornerRadius(16)
        .padding(.vertical, 8)
    }
    
    private func videoEmbedView(url: URL, platform: VideoPlatform) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundColor(.red)
                Text(platformName(for: platform))
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Link("Watch Video", destination: url)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(.accentColor)
        }
        .padding(16)
        .background(.thinMaterial)
        .cornerRadius(16)
        .padding(.vertical, 8)
    }
    
    private func platformName(for platform: VideoPlatform) -> String {
        switch platform {
        case .youtube: return "YouTube"
        case .vimeo: return "Vimeo"
        case .twitter: return "Twitter"
        case .instagram: return "Instagram"
        case .other(let name): return name.capitalized
        }
    }
    
    // MARK: - Annotation Functions
    private func toggleAnnotationMode() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if annotationMode {
                // Exiting annotation mode - restore original reading tools
                centerStageEnabled = originalCenterStageEnabled
                tunnelVisionEnabled = originalTunnelVisionEnabled
                bionicReadingEnabled = originalBionicReadingEnabled
                annotationMode = false
            } else {
                // Entering annotation mode - store current states and disable reading tools
                originalCenterStageEnabled = centerStageEnabled
                originalTunnelVisionEnabled = tunnelVisionEnabled
                originalBionicReadingEnabled = bionicReadingEnabled
                
                centerStageEnabled = false
                tunnelVisionEnabled = false
                bionicReadingEnabled = false
                annotationMode = true
            }
        }
    }
    
    // MARK: - Annotation Tools Pill
    private var annotationToolsPill: some View {
        HStack(spacing: 20) {
            // Bold Button
            Button {
                // TODO: Implement bold formatting
                print("Bold button tapped")
            } label: {
                Text("B")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .frame(width: 44, height: 44)
                    .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                    .clipShape(Circle())
            }
            
            // Italic Button
            Button {
                // TODO: Implement italic formatting
                print("Italic button tapped")
            } label: {
                Text("I")
                    .font(.system(size: 20, weight: .medium))
                    .italic()
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .frame(width: 44, height: 44)
                    .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                    .clipShape(Circle())
            }
            
            // Highlight Button
            Button {
                // TODO: Implement highlight formatting
                print("Highlight button tapped")
            } label: {
                Image(systemName: "highlighter")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .frame(width: 44, height: 44)
                    .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke, lineWidth: 0.5)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Functions
    private func headingSize(for level: Int) -> CGFloat {
        switch level {
        case 1: return 30  // H1: 28-32px
        case 2: return 23  // H2: 22-24px  
        case 3: return 19  // H3: 18-20px
        case 4: return 18
        case 5: return 17
        case 6: return 16
        default: return 19
        }
    }
    
    // MARK: - Center Block Detection
    private func updateCenteredBlock() {
        guard screenHeight > 0, !blockPositions.isEmpty else { return }
        
        let screenCenter = (screenHeight / 2) - 85
        
        var closestBlock: Int? = nil
        var closestDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        
        for (index, frame) in blockPositions {
            // Check if block is visible on screen
            let blockTop = frame.minY + scrollOffset
            let blockBottom = frame.maxY + scrollOffset
            
            // Only consider blocks that are at least partially visible
            if blockBottom > 0 && blockTop < screenHeight {
                let blockCenter = frame.midY + scrollOffset
                let distance = abs(blockCenter - screenCenter)
                
                if distance < closestDistance {
                    closestDistance = distance
                    closestBlock = index
                }
            }
        }
        
        DispatchQueue.main.async {
            if self.centeredBlockIndex != closestBlock {
                self.centeredBlockIndex = closestBlock
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Block Position Tracking
struct BlockPosition: Equatable {
    let index: Int
    let frame: CGRect
    
    static func == (lhs: BlockPosition, rhs: BlockPosition) -> Bool {
        return lhs.index == rhs.index && lhs.frame == rhs.frame
    }
}

struct BlockFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}
