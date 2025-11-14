import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var dataManager = ArticleDataManager()
    @State private var showOverlay = false
    @State private var searchText = ""
    @State private var showBookmarkedOnly = false
    @State private var isSearching = false
    @State private var deleteMode = false
    @State private var deleteButtonsScale: Double = 0.0
    @State private var rotationAngle: Double = 0
    @State private var selectedArticle: Article? = nil
    @State private var isListMode = false
    @State private var showFilePicker = false
    @State private var isProcessingSharedURL = false
    @State private var incomingURL: URL? = nil
    private let articleParser = ArticleParser()
    
    var filteredArticles: [Article] {
        // Articles are already stored in newest-first order in dataManager
        if searchText.isEmpty {
            return dataManager.articles
        } else {
            return dataManager.articles.filter { article in
                articleMatchesSearch(article, searchText: searchText)
            }
        }
    }
    
    private func articleMatchesSearch(_ article: Article, searchText: String) -> Bool {
        // Check title first
        if article.title.localizedCaseInsensitiveContains(searchText) {
            return true
        }
        
        // Check content
        return article.content.contains { content in
            contentMatchesSearch(content, searchText: searchText)
        }
    }
    
    private func contentMatchesSearch(_ content: ArticleContent, searchText: String) -> Bool {
        switch content {
        case .heading(let text, _):
            return text.localizedCaseInsensitiveContains(searchText)
        case .paragraph(let text):
            return text.localizedCaseInsensitiveContains(searchText)
        case .richParagraph(let segments):
            return segmentsMatchSearch(segments, searchText: searchText)
        case .quote(let text, let author):
            return quoteMatchesSearch(text: text, author: author, searchText: searchText)
        case .list(let items, _):
            return items.contains { $0.localizedCaseInsensitiveContains(searchText) }
        case .linkEmbed(_, let title, let description):
            return linkEmbedMatchesSearch(title: title, description: description, searchText: searchText)
        case .image(_, let caption, let alt):
            return imageMatchesSearch(caption: caption, alt: alt, searchText: searchText)
        case .twitterEmbed(_, _), .videoEmbed(_, _), .divider:
            return false
        }
    }
    
    private func segmentsMatchSearch(_ segments: [TextSegment], searchText: String) -> Bool {
        return segments.contains { segment in
            switch segment {
            case .text(let text), .boldText(let text), .italicText(let text), .link(let text, _):
                return text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func quoteMatchesSearch(text: String, author: String?, searchText: String) -> Bool {
        return text.localizedCaseInsensitiveContains(searchText) ||
               (author?.localizedCaseInsensitiveContains(searchText) ?? false)
    }
    
    private func linkEmbedMatchesSearch(title: String?, description: String?, searchText: String) -> Bool {
        return (title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
               (description?.localizedCaseInsensitiveContains(searchText) ?? false)
    }
    
    private func imageMatchesSearch(caption: String?, alt: String?, searchText: String) -> Bool {
        return (caption?.localizedCaseInsensitiveContains(searchText) ?? false) ||
               (alt?.localizedCaseInsensitiveContains(searchText) ?? false)
    }
    
    private func headerButtonStyle<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
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
    
    private var backgroundView: some View {
        (colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground).ignoresSafeArea()
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Extra top padding
            Spacer()
                .frame(height: 20)
            
            headerSection
            searchBarSection
            contentSection
        }
        .blur(radius: showOverlay ? 2 : 0)
        .animation(.easeInOut(duration: 0.3), value: showOverlay)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                backgroundView
                mainContentView
                overlaySection
                floatingActionButton
            }
            .navigationBarHidden(true)
            .tint(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
            .background(navigationLinkSection)
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("IncomingURL"))) { notification in
                if let url = notification.object as? URL {
                    handleIncomingURL(url)
                }
            }
            .alert("Processing Article", isPresented: $isProcessingSharedURL) {
                // No buttons - just show processing
            } message: {
                Text("Adding article from shared URL...")
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Library")
                .font(.system(size: 32.3, weight: .bold, design: .default))
                .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
            Spacer()
            
            if !deleteMode {
                // Search Button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSearching.toggle()
                        if !isSearching {
                            searchText = ""
                        }
                    }
                }) {
                    headerButtonStyle {
                        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                    }
                }
                
                // View Mode Toggle Button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isListMode.toggle()
                    }
                }) {
                    headerButtonStyle {
                        Image(systemName: isListMode ? "square.grid.2x2" : "list.bullet")
                    }
                }
                
                NavigationLink(destination: SettingsView()) {
                    headerButtonStyle {
                        Image(systemName: "gearshape.fill")
                    }
                }
            } else {
                // Done Button in delete mode
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        deleteMode = false
                        deleteButtonsScale = 0.0
                    }
                }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 16)
    }
    
    private var searchBarSection: some View {
        Group {
            if isSearching {
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("Search articles...", text: $searchText)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .tint(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                            .accentColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                        }
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
                    .padding(.horizontal, 26)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .padding(.bottom, 10)
            }
        }
    }
    
    private var contentSection: some View {
        Group {
            if filteredArticles.isEmpty && !dataManager.articles.isEmpty && isSearching {
                Spacer()
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No articles found")
                        .font(.system(size: 20.9, weight: .medium, design: .default))
                        .foregroundColor(.gray)
                    Text("Try a different search term")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if dataManager.articles.isEmpty {
                Spacer()
                Text("Library")
                    .font(.system(size: 32.3, weight: .bold, design: .default))
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .opacity(0.5)
                Spacer()
                Spacer()
            } else {
                // Article Grid
                ArticleGridView(
                    articles: filteredArticles,
                    isListMode: isListMode,
                    deleteMode: $deleteMode,
                    deleteButtonsScale: $deleteButtonsScale,
                    onDelete: { article in
                        deleteArticle(article)
                    },
                    onLongPress: {
                        print("🔥 Long press triggered in ContentView!")
                        enterDeleteMode()
                    },
                    onArticleTap: { article in
                        selectedArticle = article
                    }
                )
            }
        }
    }
    
    private var overlaySection: some View {
        Group {
            if showOverlay {
                Color.black.opacity(0.5).ignoresSafeArea()
                    .onTapGesture {
                        toggleOverlay()
                    }

                VStack(spacing: 16) {
                    Button(action: {
                        pasteAndParse()
                    }) {
                        Text("Paste URL from clipboard")
                            .font(.system(size: 16.15, weight: .semibold, design: .default))
                            .foregroundColor(colorScheme == .dark ? Color.themeBlack : Color.themeWhiteDark)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 80)
                    
                    Button(action: {
                        showFilePicker = true
                        toggleOverlay()
                    }) {
                        Text("Upload PDF or TXT file")
                            .font(.system(size: 16.15, weight: .semibold, design: .default))
                            .foregroundColor(colorScheme == .dark ? Color.themeBlack : Color.themeWhiteDark)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 80)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    private var floatingActionButton: some View {
        Button(action: {
            toggleOverlay()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                .frame(width: 84, height: 84)
                .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke, lineWidth: 0.5)
                )
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack, lineWidth: showOverlay ? 4 : 0)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .rotationEffect(.degrees(rotationAngle))
        }
        .padding(30)
    }
    
    private var navigationLinkSection: some View {
        EmptyView()
            .navigationDestination(isPresented: Binding(
                get: { selectedArticle != nil },
                set: { if !$0 { selectedArticle = nil } }
            )) {
                if let article = selectedArticle {
                    if article.isPDF, let pdfURL = article.pdfURL {
                        PDFViewerView(pdfURL: pdfURL, fileName: article.title, pdfTextContent: article.pdfTextContent)
                    } else {
                        ArticleDetailView(article: article)
                    }
                }
            }
    }

    private func pasteAndParse() {
        print("🔄 Paste button tapped")
        
        guard let urlString = UIPasteboard.general.string else {
            print("❌ Clipboard does not contain a string.")
            toggleOverlay()
            return
        }
        
        print("📋 Clipboard content: \(urlString)")
        
        articleParser.parse(urlString: urlString) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let article):
                    print("✅ Successfully parsed article: \(article.title)")
                    self.dataManager.addArticle(article)
                case .failure(let error):
                    print("❌ Failed to parse article: \(error)")
                }
                self.toggleOverlay()
            }
        }
    }
    
    private func toggleOverlay() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showOverlay.toggle()
            rotationAngle = showOverlay ? 45 : 0
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        print("📱 Received URL: \(url.absoluteString)")
        
        // Check if it's a Clarify URL scheme or a web URL
        if url.scheme == "clarify" {
            handleClarifyScheme(url)
        } else if url.scheme == "http" || url.scheme == "https" {
            handleWebURL(url)
        }
    }
    
    private func handleClarifyScheme(_ url: URL) {
        // Handle clarify://add-article?url=https://example.com/article
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("❌ Invalid Clarify URL format")
            return
        }
        
        // Extract the actual article URL from query parameters
        if let urlString = queryItems.first(where: { $0.name == "url" })?.value,
           let articleURL = URL(string: urlString) {
            handleWebURL(articleURL)
        }
    }
    
    private func handleWebURL(_ url: URL) {
        isProcessingSharedURL = true
        
        articleParser.parse(urlString: url.absoluteString) { result in
            DispatchQueue.main.async {
                self.isProcessingSharedURL = false
                
                switch result {
                case .success(let article):
                    print("✅ Successfully parsed article: \(article.title)")
                    
                    // Save to user's library
                    self.saveSharedArticleToLibrary(article)
                    
                    // Navigate to the article
                    self.selectedArticle = article
                    
                case .failure(let error):
                    print("❌ Failed to parse article: \(error)")
                    // Could show an alert to user here
                }
            }
        }
    }
    
    private func saveSharedArticleToLibrary(_ article: Article) {
        // Check if article already exists (by title)
        let articleExists = dataManager.articles.contains { existingArticle in
            existingArticle.title == article.title
        }
        
        if !articleExists {
            // Add new article using data manager
            dataManager.addArticle(article)
            
            print("💾 Shared article saved to library")
        } else {
            print("📖 Shared article already exists in library")
        }
    }
    
    private func enterDeleteMode() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            deleteMode = true
            deleteButtonsScale = 1.0
            // Hide search when entering delete mode
            if isSearching {
                isSearching = false
                searchText = ""
            }
        }
    }
    
    private func deleteArticle(_ article: Article) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dataManager.removeArticle(article)
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            print("📁 File selected: \(url)")
            
            // Determine file type and parse accordingly
            let fileExtension = url.pathExtension.lowercased()
            
            switch fileExtension {
            case "pdf":
                articleParser.createPDFArticle(from: url) { result in
                    switch result {
                    case .success(let article):
                        print("✅ Successfully created PDF article: \(article.title)")
                        self.dataManager.addArticle(article)
                    case .failure(let error):
                        print("❌ Failed to create PDF article: \(error)")
                    }
                }
                
            case "txt":
                articleParser.parseTextFile(from: url) { result in
                    switch result {
                    case .success(let article):
                        print("✅ Successfully parsed text file: \(article.title)")
                        self.dataManager.addArticle(article)
                    case .failure(let error):
                        print("❌ Failed to parse text file: \(error)")
                    }
                }
                
            default:
                print("❌ Unsupported file type: \(fileExtension)")
            }
            
        case .failure(let error):
            print("❌ File import failed: \(error)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
