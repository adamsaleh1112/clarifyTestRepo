import SwiftUI

struct ArticleGridView: View {
    let articles: [Article]
    let isListMode: Bool
    @Binding var deleteMode: Bool
    @Binding var deleteButtonsScale: Double
    let onDelete: (Article) -> Void
    let onLongPress: () -> Void
    let onArticleTap: (Article) -> Void
    let onFavoriteToggle: (Article) -> Void
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @State private var showDeleteAlert = false
    @State private var articleToDelete: Article?
    
    // Computed property to determine column count based on size classes
    private var columnCount: Int {
        // Use size classes to determine device type and orientation
        // Regular horizontal size class typically indicates iPad
        if horizontalSizeClass == .regular {
            // iPad: 3 columns in portrait (regular/regular), 5 columns in landscape (regular/compact)
            return verticalSizeClass == .compact ? 5 : 3
        } else {
            // iPhone: Always 2 columns (compact horizontal size class)
            return 2
        }
    }
    
    var body: some View {
        ScrollView {
            if isListMode {
                // List Mode - Vertical list with horizontal cards
                LazyVStack(spacing: 16) {
                    ForEach(articles) { article in
                        listItemView(for: article)
                    }
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 16)
            } else {
                // Grid Mode - Responsive grid based on device and orientation
                let sidePadding: CGFloat = 26
                let columnSpacing: CGFloat = 40  // Double the original 20px
                let rowSpacing: CGFloat = 20     // Use the original column spacing value
                
                // Create dynamic columns based on columnCount
                let columns = Array(repeating: GridItem(.flexible(), spacing: columnSpacing/2), count: columnCount)
                
                LazyVGrid(columns: columns, spacing: rowSpacing) {
                    ForEach(articles) { article in
                        GeometryReader { geometry in
                            let columnWidth = geometry.size.width
                            
                            ZStack {
                                Button(action: {
                                    if !deleteMode {
                                        onArticleTap(article)
                                    }
                                }) {
                                    ZStack(alignment: .bottomLeading) {
                                        // Background Image covering entire cover
                                        AsyncImage(url: article.coverImageURL) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: columnWidth, height: columnWidth * 1.45)
                                                .clipped()
                                        } placeholder: {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: columnWidth, height: columnWidth * 1.45)
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(Color.themeWhiteDark.opacity(0.6))
                                                )
                                        }
                                        
                                        // Bottom gradient overlay
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.themeBlack.opacity(0.8),
                                                Color.themeBlack.opacity(0.4),
                                                Color.clear
                                            ]),
                                            startPoint: .bottom,
                                            endPoint: .center
                                        )
                                        
                                        // Text overlay at bottom
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(article.title)
                                                .font(.system(size: 14, weight: .bold, design: .default))
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                            
                                            HStack {
                                                Text(article.date)
                                                    .font(.system(size: 11, weight: .medium, design: .default))
                                                    .foregroundColor(.white.opacity(0.9))
                                                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                                
                                                if let readingTime = article.estimatedReadingTimeMinutes {
                                                    Text("·")
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.7))
                                                    
                                                    Text("\(readingTime) min read")
                                                        .font(.system(size: 11, weight: .medium, design: .default))
                                                        .foregroundColor(.white.opacity(0.9))
                                                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                                }
                                                
                                                Spacer()
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.bottom, 12)
                                    }
                                    .frame(width: columnWidth, height: columnWidth * 1.45) // Responsive dimensions for all article covers
                                    .cornerRadius(16)
                                    .shadow(color: Color.themeBlack.opacity(0.08), radius: 8, x: 0, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke, lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contentShape(Rectangle())
                                
                                // Top-right buttons
                                VStack {
                                    HStack {
                                        Spacer()
                                        
                                        // Favorite button
                                        if !deleteMode {
                                            Button(action: {
                                                onFavoriteToggle(article)
                                                HapticsManager.shared.favoriteToggled()
                                            }) {
                                                Image(systemName: article.isFavorite ? "heart.fill" : "heart")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(article.isFavorite ? .red : Color.themeWhiteDark)
                                                    .frame(width: 28, height: 28)
                                                    .background(Color.themeBlack.opacity(0.3))
                                                    .clipShape(Circle())
                                                    .shadow(color: Color.themeBlack.opacity(0.3), radius: 2, x: 0, y: 1)
                                            }
                                            .padding(.trailing, 8)
                                            .padding(.top, 8)
                                        }
                                        
                                        // Delete button
                                        if deleteMode {
                                            Button(action: {
                                                articleToDelete = article
                                                showDeleteAlert = true
                                            }) {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(Color.themeBlackDark)
                                                    .frame(width: 24, height: 24)
                                                    .background(Color.themeRaised)
                                                    .clipShape(Circle())
                                                    .overlay(
                                                        Circle()
                                                            .stroke(colorScheme == .dark ? Color.themeBlack.opacity(0.2) : Color.themeBlack.opacity(0.2), lineWidth: 1)
                                                    )
                                                    .shadow(color: colorScheme == .dark ? Color.themeBlack.opacity(0.2) : Color.themeBlack.opacity(0.2), radius: 2, x: 0, y: 1)
                                            }
                                            .scaleEffect(deleteButtonsScale)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: deleteButtonsScale)
                                            .padding(.trailing, 8)
                                            .padding(.top, 8)
                                        }
                                    }
                                    Spacer()
                                }
                                .frame(width: columnWidth, height: columnWidth * 1.45)
                            }
                            .simultaneousGesture(
                                TapGesture()
                                    .onEnded { _ in
                                        print("🔥 TAP detected!")
                                    }
                            )
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.6)
                                    .onEnded { _ in
                                        print("🔥 Long press detected!")
                                        if !deleteMode {
                                            onLongPress()
                                        }
                                    }
                            )
                        }
                        .aspectRatio(1/1.45, contentMode: .fit)
                    }
                }
                .padding(.horizontal, sidePadding)
                .padding(.vertical, 16)
            }
        }
        .alert("Delete Article", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let article = articleToDelete {
                    onDelete(article)
                    articleToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this article? This action cannot be undone.")
        }
    }
    
    // List Item View for horizontal layout
    private func listItemView(for article: Article) -> some View {
            ZStack {
                Button(action: {
                    if !deleteMode {
                        onArticleTap(article)
                    }
                }) {
                    HStack(spacing: 0) {
                        // Image Container with 6px inset
                        VStack {
                            AsyncImage(url: article.coverImageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 68, height: 68)
                                    .clipped()
                                    .cornerRadius(13)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 68, height: 68)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 22))
                                            .foregroundColor(.secondary)
                                    )
                            }
                        }
                        .frame(width: 80, height: 80)
                        .padding(0)
                        .background(Color.clear)
                        
                        // Text Container with separate padding
                        VStack(alignment: .leading, spacing: 6) {
                            Text(article.title)
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Text(article.date)
                                .font(.system(size: 13, weight: .medium, design: .default))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        
                        Spacer()
                    }
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke, lineWidth: 0.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                
                // Delete button for list mode
                if deleteMode {
                    Button(action: {
                        articleToDelete = article
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.themeBlackDark)
                            .frame(width: 24, height: 24)
                            .background(Color.themeRaised)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(colorScheme == .dark ? Color.themeBlack.opacity(0.2) : Color.themeBlack.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: colorScheme == .dark ? Color.themeBlack.opacity(0.2) : Color.themeBlack.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    .scaleEffect(deleteButtonsScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: deleteButtonsScale)
                    .offset(x: 154, y: -18)
                }
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.6)
                    .onEnded { _ in
                        if !deleteMode {
                            onLongPress()
                        }
                    }
            )
        }
    }
