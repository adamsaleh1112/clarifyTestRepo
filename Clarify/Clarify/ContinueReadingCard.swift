import SwiftUI

struct ContinueReadingCard: View {
    let article: Article
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Cover Image with minimal padding from edges
                AsyncImage(url: article.coverImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 184, height: 120) // Reduced width to account for 8pt margins
                        .clipped()
                        .cornerRadius(12)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 184, height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                        )
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.horizontal, 8)
                
                // Text content area with margins
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(article.title)
                        .font(.articleCardTitle(size: 16))
                        .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Progress and metadata
                    HStack(spacing: 12) {
                        // Reading progress
                        if article.readingProgress > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "book")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("\(Int(article.readingProgress * 100))%")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Reading time
                        if let readingTime = article.estimatedReadingTimeMinutes {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("\(readingTime) min")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Progress bar
                    ProgressView(value: article.readingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack))
                        .scaleEffect(y: 0.6)
                        .frame(height: 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16) // 16pt margin from card edges
                .padding(.bottom, 16) // 16pt margin from bottom
                .padding(.top, 12) // 12pt spacing from image
            }
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContinueReadingCard(
        article: Article(
            title: "Sample Article Title That Might Be Long",
            date: "Nov 24, 2024",
            content: []
        ),
        onTap: {}
    )
}
