import SwiftUI

struct AIChatView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var userInput = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var canCancel = false
    @State private var currentTask: Task<Void, Never>?
    @State private var isCancelled = false
    @State private var showNewConversationAlert = false
    @State private var showRegenerateAlert = false
    @State private var messageToRegenerate: ChatMessage?
    @StateObject private var openAIService = OpenAIService()
    
    let articleTitle: String?
    let articleContent: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                (colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Chat Content
                    if messages.isEmpty {
                        // Initial state with AI icon and prompts
                        initialChatView
                    } else {
                        // Chat messages
                        chatMessagesView
                    }
                    
                    Spacer()
                    
                    // Input field
                    inputSection
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // View appeared
        }
        .onDisappear {
            // View disappeared
        }
        .alert("New Conversation", isPresented: $showNewConversationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Start New", role: .destructive) {
                startNewConversation()
            }
        } message: {
            Text("Are you sure you want to start a new conversation? Your current conversation will be saved.")
        }
        .alert("Regenerate Response", isPresented: $showRegenerateAlert) {
            Button("Cancel", role: .cancel) { 
                messageToRegenerate = nil
            }
            Button("Regenerate", role: .destructive) {
                if let message = messageToRegenerate {
                    performRegeneration(for: message)
                }
                messageToRegenerate = nil
            }
        } message: {
            Text("Are you sure you want to regenerate this response? The current response will be replaced.")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Draggable handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            // If dragged down significantly, dismiss the sheet
                            if value.translation.height > 100 {
                                dismiss()
                            }
                        }
                )
            
            // Header with title and New Conversation button (only show if there are messages)
            if !messages.isEmpty {
                HStack {
                    Text("Clarify AI")
                        .font(.uiHeadingBold(size: 18))
                        .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    
                    Spacer()
                    
                    Button(action: {
                        showNewConversationAlert = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    }
                    .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground)
    }
    
    private var initialChatView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            
            // Greeting
            Text("How can I help you today?")
                .font(.uiHeadingBold(size: 24))
                .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                .multilineTextAlignment(.center)
            
            // Conversation starters
            VStack(spacing: 12) {
                promptButton(icon: "doc.text", title: "Summarize article") {
                    handlePromptTap("Summarize this article for me")
                }
                
                promptButton(icon: "list.bullet", title: "Key points") {
                    handlePromptTap("What are the key points of this article?")
                }
                
                promptButton(icon: "face.smiling", title: "Explain like I'm 5") {
                    handlePromptTap("Explain this article like I'm 5 years old")
                }
                
                promptButton(icon: "chart.bar.doc.horizontal", title: "Extract data") {
                    handlePromptTap("Extract all the important data, numbers, names, and statistics from this article")
                }
                
                promptButton(icon: "book.pages", title: "Give background") {
                    handlePromptTap("Give me background context and information to better understand this article")
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private func promptButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .frame(width: 20)
                
                Text(title)
                    .font(.uiHeading(size: 16))
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke, lineWidth: 0.5)
            )
        }
    }
    
    private var chatMessagesView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(messages) { message in
                    ChatMessageRow(
                        message: message,
                        onCopy: { text in
                            copyToClipboard(text)
                        },
                        onRegenerate: { message in
                            messageToRegenerate = message
                            showRegenerateAlert = true
                        }
                    )
                }
                
                // Loading indicator
                if isLoading {
                    HStack {
                        ThinkingIndicator()
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 12) {
            // Context indicator
            if let title = articleTitle {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? Color.themeGreyDark : Color.themeGrey)
                    
                    Text("Clarify - \(title)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? Color.themeGreyDark : Color.themeGrey)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke, lineWidth: 0.5)
                )
            }
            
            // Floating Input field
            HStack(spacing: 12) {
                // Text field
                TextField("Ask anything about this text...", text: $userInput)
                    .font(.uiHeading(size: 16))
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .textFieldStyle(PlainTextFieldStyle())
                    .tint(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .accentColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .disabled(isLoading)
                
                // Send/Stop button
                Button(action: isLoading ? stopGeneration : sendMessage) {
                    Image(systemName: isLoading ? "stop.fill" : "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground)
                        .frame(width: 28, height: 28)
                        .background(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                        .clipShape(Circle())
                }
                .disabled(!isLoading && userInput.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    private func handlePromptTap(_ prompt: String) {
        userInput = prompt
        sendMessage()
    }
    
    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let messageText = userInput
        userInput = ""
        
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            content: messageText,
            isUser: true,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        isLoading = true
        isCancelled = false
        
        // Cancel any existing task
        currentTask?.cancel()
        
        currentTask = Task {
            do {
                let aiResponse = try await openAIService.sendMessage(messageText, articleContext: articleContent)
                
                // Check if cancelled before updating UI
                guard !Task.isCancelled && !isCancelled else {
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                }
                
                await MainActor.run {
                    // Double-check cancellation state on main thread
                    guard !isCancelled else {
                        isLoading = false
                        return
                    }
                    
                    let aiMessage = ChatMessage(
                        id: UUID().uuidString,
                        content: aiResponse,
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(aiMessage)
                    isLoading = false
                    currentTask = nil
                }
            } catch {
                // Check if cancelled before showing error
                guard !Task.isCancelled && !isCancelled else {
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                }
                
                await MainActor.run {
                    guard !isCancelled else {
                        isLoading = false
                        return
                    }
                    
                    let errorMessage = ChatMessage(
                        id: UUID().uuidString,
                        content: "I'm sorry, I encountered an error: \(error.localizedDescription)",
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(errorMessage)
                    isLoading = false
                    currentTask = nil
                }
            }
        }
    }
    
    private func stopGeneration() {
        // Set cancellation flag immediately
        isCancelled = true
        isLoading = false
        canCancel = false
        
        // Cancel the current task
        currentTask?.cancel()
        currentTask = nil
        
        // Add a message indicating the generation was stopped
        let stopMessage = ChatMessage(
            id: UUID().uuidString,
            content: "Generation stopped by user.",
            isUser: false,
            timestamp: Date()
        )
        messages.append(stopMessage)
    }
    
    private func startNewConversation() {
        // Clear current conversation
        messages = []
        userInput = ""
        isLoading = false
        isCancelled = false
        currentTask?.cancel()
        currentTask = nil
    }
    
    // MARK: - AI Response Action Functions
    
    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        print("📋 Copied to clipboard: \(text.prefix(50))...")
    }
    
    
    private func performRegeneration(for message: ChatMessage) {
        guard !message.isUser else { return }
        
        // Find the user message that prompted this AI response
        guard let messageIndex = messages.firstIndex(where: { $0.id == message.id }),
              messageIndex > 0,
              messages[messageIndex - 1].isUser else {
            print("⚠️ Could not find user message for regeneration")
            return
        }
        
        let userMessage = messages[messageIndex - 1]
        
        // Remove the AI response
        messages.remove(at: messageIndex)
        
        // Set loading state and regenerate
        isLoading = true
        isCancelled = false
        
        // Cancel any existing task
        currentTask?.cancel()
        
        currentTask = Task {
            do {
                let aiResponse = try await openAIService.sendMessage(userMessage.content, articleContext: articleContent)
                
                // Check if cancelled before updating UI
                guard !Task.isCancelled && !isCancelled else {
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                }
                
                await MainActor.run {
                    // Double-check cancellation state on main thread
                    guard !isCancelled else {
                        isLoading = false
                        return
                    }
                    
                    let newAIMessage = ChatMessage(
                        id: UUID().uuidString,
                        content: aiResponse,
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(newAIMessage)
                    isLoading = false
                    currentTask = nil
                }
            } catch {
                // Check if cancelled before showing error
                guard !Task.isCancelled && !isCancelled else {
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                }
                
                await MainActor.run {
                    guard !isCancelled else {
                        isLoading = false
                        return
                    }
                    
                    let errorMessage = ChatMessage(
                        id: UUID().uuidString,
                        content: "I'm sorry, I encountered an error regenerating the response: \(error.localizedDescription)",
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(errorMessage)
                    isLoading = false
                    currentTask = nil
                }
            }
        }
    }
    
    private func generateAIResponse(for input: String) -> String {
        let lowercased = input.lowercased()
        
        if lowercased.contains("summarize") {
            return "I'd be happy to summarize the article for you. Here are the main points:\n\n• Key insight from the article\n• Important findings\n• Main conclusions\n\nWould you like me to elaborate on any of these points?"
        } else if lowercased.contains("key points") {
            return "Here are the key points from the article:\n\n1. First main point\n2. Second main point\n3. Third main point\n\nThese seem to be the most important takeaways. Is there anything specific you'd like me to explain further?"
        } else if lowercased.contains("fact check") {
            return "I can help fact-check this article. Based on my analysis:\n\n✅ Verified claims look accurate\n✅ Sources appear credible\n⚠️ Some claims may need additional verification\n\nWould you like me to provide sources for any of these points?"
        } else {
            return "I understand you're asking about the article. I can help you summarize it, identify key points, or fact-check specific claims. What would you like to know more about?"
        }
    }
}

struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
}

struct ThinkingIndicator: View {
    @State private var shimmerPhase: CGFloat = -1.0
    @State private var rotationAngle: Double = 0
    @State private var dotCount: Int = 0
    
    private var thinkingText: String {
        let dots = String(repeating: ".", count: dotCount)
        return "Thinking\(dots)"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Loading circle
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.secondary.opacity(0.6), lineWidth: 2)
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(rotationAngle))
                .animation(
                    Animation.linear(duration: 1.0)
                        .repeatForever(autoreverses: false),
                    value: rotationAngle
                )
            
            // Thinking text with shimmer and cycling dots
            Text(thinkingText)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.secondary.opacity(0.4),
                            Color.secondary,
                            Color.secondary.opacity(0.4)
                        ]),
                        startPoint: UnitPoint(x: shimmerPhase - 0.5, y: 0.5),
                        endPoint: UnitPoint(x: shimmerPhase + 0.5, y: 0.5)
                    )
                )
                .animation(
                    Animation.linear(duration: 2.0)
                        .repeatForever(autoreverses: false),
                    value: shimmerPhase
                )
        }
        .padding(.horizontal, 12)
        .onAppear {
            // Start shimmer from left
            shimmerPhase = 1.5
            rotationAngle = 360
            
            // Start dot cycling
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                dotCount = (dotCount + 1) % 4 // 0, 1, 2, 3, then back to 0
            }
        }
    }
}

struct AIMessageView: View {
    let content: String
    @Environment(\.colorScheme) var colorScheme
    @State private var visibleLines: [FormattedLine] = []
    @State private var allLines: [FormattedLine] = []
    @State private var animationTask: Task<Void, Never>?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(visibleLines.enumerated()), id: \.offset) { index, line in
                FormattedLineView(line: line, colorScheme: colorScheme)
                    .opacity(line.isVisible ? 1.0 : 0.0)
                    .animation(
                        .easeIn(duration: 0.4).delay(line.delay),
                        value: line.isVisible
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            setupAnimation()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }
    
    private func setupAnimation() {
        // Parse content into formatted lines
        let lines = parseMarkdownContent(content)
        
        // Create animated lines with delays
        allLines = lines.enumerated().map { index, line in
            FormattedLine(
                content: line.content,
                type: line.type,
                isVisible: false,
                delay: Double(index) * 0.15, // Slower for line-by-line
                number: line.number
            )
        }
        
        // Start animation
        animationTask = Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            guard !Task.isCancelled else { return }
            await animateLines()
        }
    }
    
    private func animateLines() async {
        for (index, _) in allLines.enumerated() {
            guard !Task.isCancelled else { return }
            
            try? await Task.sleep(nanoseconds: UInt64(Double(index) * 0.15 * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                var updatedLine = allLines[index]
                updatedLine.isVisible = true
                
                if index < visibleLines.count {
                    visibleLines[index] = updatedLine
                } else {
                    visibleLines.append(updatedLine)
                }
            }
        }
    }
    
    private func parseMarkdownContent(_ text: String) -> [FormattedLine] {
        let lines = text.components(separatedBy: .newlines)
        var formattedLines: [FormattedLine] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty {
                // Add spacing for empty lines
                formattedLines.append(FormattedLine(content: "", type: .spacing, isVisible: false, delay: 0, number: nil))
            } else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("• ") {
                // Bullet point
                let bulletText = String(trimmedLine.dropFirst(2))
                formattedLines.append(FormattedLine(content: bulletText, type: .bullet, isVisible: false, delay: 0, number: nil))
            } else if let match = trimmedLine.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                // Numbered list - extract the number
                let numberPart = String(trimmedLine[..<match.upperBound])
                let number = numberPart.replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .whitespaces)
                let numberText = String(trimmedLine[match.upperBound...])
                formattedLines.append(FormattedLine(content: numberText, type: .numbered, isVisible: false, delay: 0, number: number))
            } else {
                // Regular paragraph
                formattedLines.append(FormattedLine(content: trimmedLine, type: .paragraph, isVisible: false, delay: 0, number: nil))
            }
        }
        
        return formattedLines
    }
}

struct FormattedLine: Identifiable {
    let id = UUID()
    let content: String
    let type: LineType
    var isVisible: Bool
    let delay: Double
    let number: String?
}

enum LineType {
    case paragraph
    case bullet
    case numbered
    case spacing
}

struct FormattedLineView: View {
    let line: FormattedLine
    let colorScheme: ColorScheme
    
    var body: some View {
        switch line.type {
        case .paragraph:
            Text(line.content)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                .fixedSize(horizontal: false, vertical: true)
                
        case .bullet:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .padding(.top, 1)
                
                Text(line.content)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
        case .numbered:
            HStack(alignment: .top, spacing: 8) {
                Text("\(line.number ?? "1").")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .padding(.top, 1)
                
                Text(line.content)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
        case .spacing:
            Spacer()
                .frame(height: 8)
        }
    }
}

struct AnimatedWord: Identifiable, Hashable {
    let id = UUID()
    let text: String
    var isVisible: Bool
    let delay: Double
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AnimatedWord, rhs: AnimatedWord) -> Bool {
        lhs.id == rhs.id
    }
}

struct WrappingHStack<Content: View>: View {
    let words: [AnimatedWord]
    let spacing: CGFloat
    let lineSpacing: CGFloat
    let content: (AnimatedWord) -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(createLines(), id: \.self) { line in
                HStack(spacing: spacing) {
                    ForEach(line) { word in
                        content(word)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private func createLines() -> [[AnimatedWord]] {
        var lines: [[AnimatedWord]] = []
        var currentLine: [AnimatedWord] = []
        var currentWidth: CGFloat = 0
        let maxWidth: CGFloat = 350 // Approximate screen width
        
        for word in words {
            let estimatedWordWidth = CGFloat(word.text.count) * 10 + spacing
            
            if currentWidth + estimatedWordWidth > maxWidth && !currentLine.isEmpty {
                lines.append(currentLine)
                currentLine = [word]
                currentWidth = estimatedWordWidth
            } else {
                currentLine.append(word)
                currentWidth += estimatedWordWidth
            }
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        return lines
    }
}

struct ChatMessageRow: View {
    let message: ChatMessage
    @Environment(\.colorScheme) var colorScheme
    let onCopy: ((String) -> Void)?
    let onRegenerate: ((ChatMessage) -> Void)?
    
    init(message: ChatMessage, onCopy: ((String) -> Void)? = nil, onRegenerate: ((ChatMessage) -> Void)? = nil) {
        self.message = message
        self.onCopy = onCopy
        self.onRegenerate = onRegenerate
    }
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                Text(message.content)
                    .font(.uiHeading(size: 16))
                    .foregroundColor(colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .cornerRadius(16)
                    .frame(maxWidth: .infinity * 0.8, alignment: .trailing)
            } else {
                // AI message with text and action buttons
                VStack(alignment: .leading, spacing: 8) {
                    AIMessageView(content: message.content)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        // Copy button
                        Button(action: {
                            onCopy?(message.content)
                        }) {
                            Image(systemName: "square.on.square")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                        }
                        
                        // Regenerate button
                        Button(action: {
                            onRegenerate?(message)
                        }) {
                            Image(systemName: "arrow.trianglehead.2.clockwise")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    AIChatView(articleTitle: "Sample Article", articleContent: "Sample content")
}
