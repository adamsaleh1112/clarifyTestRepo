import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showOverlay = false
    @State private var articles: [Article] = []
    @State private var searchText = ""
    @State private var showBookmarkedOnly = false
    @State private var isSearching = false
    @State private var deleteMode = false
    @State private var deleteButtonsScale: Double = 0.0
    @State private var rotationAngle: Double = 0
    @State private var selectedArticle: Article? = nil
    @State private var isListMode = false
    private let articleParser = ArticleParser()
    
    var filteredArticles: [Article] {
        if searchText.isEmpty {
            return articles
        } else {
            return articles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.content.contains { content in
                    switch content {
                    case .heading(let text, _):
                        return text.localizedCaseInsensitiveContains(searchText)
                    case .paragraph(let text):
                        return text.localizedCaseInsensitiveContains(searchText)
                    case .richParagraph(let segments):
                        return segments.contains { segment in
                            switch segment {
                            case .text(let text), .boldText(let text), .italicText(let text), .link(let text, _):
                                return text.localizedCaseInsensitiveContains(searchText)
                            }
                        }
                    case .quote(let text, let author):
                        return text.localizedCaseInsensitiveContains(searchText) ||
                               (author?.localizedCaseInsensitiveContains(searchText) ?? false)
                    case .list(let items, _):
                        return items.contains { $0.localizedCaseInsensitiveContains(searchText) }
                    case .linkEmbed(_, let title, let description):
                        return (title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                               (description?.localizedCaseInsensitiveContains(searchText) ?? false)
                    case .image(_, let caption, let alt):
                        return (caption?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                               (alt?.localizedCaseInsensitiveContains(searchText) ?? false)
                    case .twitterEmbed(_, _), .videoEmbed(_, _), .divider:
                        return false
                    }
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color.customBackgroundColor.ignoresSafeArea()

                // Main Content
                VStack(spacing: 0) {
                    // Extra top padding
                    Spacer()
                        .frame(height: 20)
                    
                    // Custom Header
                    HStack {
                        Text("Your articles")
                            .font(.system(size: 32.3, weight: .bold, design: .default))
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
                                Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(Color.customButtonBackgroundColor)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
                                    )
                            }
                            
                            // View Mode Toggle Button
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isListMode.toggle()
                                }
                            }) {
                                Image(systemName: isListMode ? "square.grid.2x2" : "list.bullet")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(Color.customButtonBackgroundColor)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
                                    )
                            }
                            
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(Color.customButtonBackgroundColor)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
                                    )
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    // Search Bar
                    if isSearching {
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextField("Search articles...", text: $searchText)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                
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
                            .background(.regularMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.systemGray5), lineWidth: 0.5)
                            )
                            .padding(.horizontal, 20)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .padding(.bottom, 10)
                    }

                    if filteredArticles.isEmpty && !articles.isEmpty && isSearching {
                        Spacer()
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No articles found")
                                .font(.system(size: 20.9, weight: .medium, design: .default))
                                .foregroundColor(.gray)
                            Text("Try a different search term")
                                .font(.system(size: 16.15, weight: .regular, design: .default))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else if articles.isEmpty {
                        Spacer()
                        Text("You have no articles")
                            .font(.system(size: 20.9, weight: .medium, design: .default))
                            .foregroundColor(.gray.opacity(0.5))
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
                .blur(radius: showOverlay ? 2 : 0)
                .animation(.easeInOut(duration: 0.3), value: showOverlay)
                
                if showOverlay {
                    Color.black.opacity(0.5).ignoresSafeArea()
                        .onTapGesture {
                            toggleOverlay()
                        }

                    VStack {
                        Button(action: {
                            pasteAndParse()
                        }) {
                            Text("Paste URL from clipboard")
                                .font(.system(size: 16.15, weight: .semibold, design: .default))
                                .foregroundColor(colorScheme == .dark ? Color(hex: "#101010") : .white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(colorScheme == .dark ? .white : Color(hex: "#101010"))
                                .cornerRadius(15)
                        }
                        .padding(.horizontal, 80)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                // Floating Action Button (stays on top of overlay)
                Button(action: {
                    toggleOverlay()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 84, height: 84)
                        .background(.regularMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: showOverlay ? 4 : 0)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                        .rotationEffect(.degrees(rotationAngle))
                }
                .padding(30)
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(
                    destination: selectedArticle.map { ArticleDetailView(article: $0) },
                    isActive: Binding(
                        get: { selectedArticle != nil },
                        set: { if !$0 { selectedArticle = nil } }
                    )
                ) {
                    EmptyView()
                }
            )
        }
    }

    private func pasteAndParse() {
        print("🔄 Paste button tapped")
        
        guard let urlString = UIPasteboard.general.string else {
            print("❌ Clipboard does not contain a string.")
            toggleOverlay()
            return
        }
        
        print("📋 Found URL in clipboard: \(urlString)")

        articleParser.parse(urlString: urlString) { result in
            switch result {
            case .success(let article):
                print("✅ Successfully parsed article: \(article.title)")
                articles.insert(article, at: 0)
            case .failure(let error):
                print("❌ Failed to parse article: \(error)")
            }
            toggleOverlay()
        }
    }

    private func toggleOverlay() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showOverlay.toggle()
            rotationAngle = showOverlay ? 45 : 0
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
            articles.removeAll { $0.id == article.id }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
