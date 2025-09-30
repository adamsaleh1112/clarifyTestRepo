import SwiftUI

struct ArticleGridView: View {
    let articles: [Article]
    let isListMode: Bool
    @Binding var deleteMode: Bool
    @Binding var deleteButtonsScale: Double
    let onDelete: (Article) -> Void
    let onLongPress: () -> Void
    let onArticleTap: (Article) -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            if isListMode {
                // List Mode - Vertical list with horizontal cards
                LazyVStack(spacing: 16) {
                    ForEach(articles) { article in
                        listItemView(for: article)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            } else {
                // Grid Mode - Original 2-column grid
                LazyVGrid(columns: [
                    GridItem(.fixed(165), spacing: 20),
                    GridItem(.fixed(165), spacing: 20)
                ], spacing: 20) {
                ForEach(articles) { article in
                    ZStack {
                        Button(action: {
                            if !deleteMode {
                                onArticleTap(article)
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 0) {
                                // ACTUAL COVER IMAGE
                                AsyncImage(url: article.coverImageURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 165, height: 180)
                                        .clipped()
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1), lineWidth: 1)
                                        )
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 165, height: 180)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .font(.system(size: 40))
                                                .foregroundColor(.secondary)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1), lineWidth: 1)
                                        )
                                }

                                // Text Container - FIXED WIDTH
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(article.title)
                                        .font(.system(size: 15.2, weight: .semibold, design: .default))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text(article.date)
                                        .font(.system(size: 12.35, weight: .medium, design: .default))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .frame(width: 165, alignment: .leading)
                            }
                            .frame(width: 165) // Fixed width for all article covers
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.regularMaterial)
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Delete button - positioned absolutely in top-right corner
                        if deleteMode {
                            Button(action: {
                                onDelete(article)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 24, height: 24)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                            .scaleEffect(deleteButtonsScale)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: deleteButtonsScale)
                            .position(x: 165 - 10 - 12, y: -20) // 10px from edges, accounting for button radius
                            .frame(width: 165, height: 180)
                        }
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
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            }
        }
    }
    
    // List Item View for horizontal layout
    func listItemView(for article: Article) -> some View {
        ZStack {
            Button(action: {
                if !deleteMode {
                    onArticleTap(article)
                }
            }) {
                HStack(spacing: 12) {
                    // Cover image on the left
                    AsyncImage(url: article.coverImageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1), lineWidth: 1)
                            )
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Text content on the right
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
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.leading, 10)
                .padding(.trailing, 12)
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Delete button for list mode
            if deleteMode {
                Button(action: {
                    onDelete(article)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .scaleEffect(deleteButtonsScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: deleteButtonsScale)
                .offset(x: 150, y: -40)
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
