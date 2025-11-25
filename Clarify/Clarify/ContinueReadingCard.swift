import SwiftUI

struct ContinueReadingCard: View {
    let article: Article
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Cover Image
                AsyncImage(url: article.coverImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 120)
                        .clipped()
                        .cornerRadius(12)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(article.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Progress and metadata
                    HStack(spacing: 12) {
                        // Reading progress
                        HStack(spacing: 4) {
                            Image(systemName: "book")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("\(Int(article.readingProgress * 100))%")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        if let readingTime = article.estimatedReadingTimeMinutes {
                            Text("·")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("\(readingTime) min")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Progress bar
                    ProgressView(value: article.readingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 0.6)
                        .frame(height: 4)
                }
                .frame(width: 200, alignment: .leading)
            }
            .frame(width: 200)
            .padding(16)
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
