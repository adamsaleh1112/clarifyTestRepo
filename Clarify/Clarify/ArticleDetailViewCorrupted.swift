import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Extra top padding
                Spacer()
                    .frame(height: 20)
                
                // Display the main article title
                Text(article.title)
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .lineSpacing(4)
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .padding(.bottom, 16)

                // Simple text content for now
                Text("Article content will be displayed here with proper typography and spacing.")
                    .font(.system(size: 17, weight: .regular, design: .default))
                    .lineSpacing(10)
                    .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                    .padding(.bottom, 16)
                            
                    case .richParagraph(let segments):
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .top, spacing: 0) {
                                ForEach(segments) { segment in
                                    switch segment {
                                    case .text(let text):
                                        Text(text)
                                            .font(.system(size: 17.1, weight: .regular, design: .default))
                                            .lineSpacing(8)
                                    case .boldText(let text):
                                        Text(text)
                                            .font(.system(size: 17.1, weight: .bold, design: .default))
                                            .lineSpacing(8)
                                    case .italicText(let text):
                                        Text(text)
                                            .font(.system(size: 17.1, weight: .regular, design: .default))
                                            .italic()
                                            .lineSpacing(8)
                                    case .link(let text, let url):
                                        Link(text, destination: url)
                                            .font(.system(size: 17.1, weight: .regular, design: .default))
                                            .underline()
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(.bottom, 12)
                            
                    case .image(let url, let caption, let alt):
                        VStack(alignment: .leading, spacing: 12) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 250)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.secondary)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                            
                            if let caption = caption, !caption.isEmpty {
                                Text(caption)
                                    .font(.system(size: 14.25, weight: .regular, design: .default))
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(.vertical, 16)
                        
                    case .quote(let text, let author):
                        VStack(alignment: .leading, spacing: 8) {
                            Text(text)
                                .font(.system(size: 19, weight: .regular, design: .default))
                                .italic()
                                .padding(.leading, 16)
                                .overlay(
                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(width: 4)
                                        .padding(.leading, 0),
                                    alignment: .leading
                                )
                            
                            if let author = author, !author.isEmpty {
                                Text("— \(author)")
                                    .font(.system(size: 15.2, weight: .regular, design: .default))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 16)
                            }
                        }
                        .padding(.vertical, 16)
                        
                    case .list(let items, let ordered):
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                                HStack(alignment: .top, spacing: 12) {
                                    Text(ordered ? "\(index + 1)." : "•")
                                        .font(.system(size: 17.1, weight: .regular, design: .default))
                                        .foregroundColor(.secondary)
                                        .frame(width: 20, alignment: .leading)
                                    
                                    Text(item)
                                        .font(.system(size: 17.1, weight: .regular, design: .default))
                                        .lineSpacing(6)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        
                    case .twitterEmbed(let tweetId, let url):
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .foregroundColor(.blue)
                                Text("Twitter")
                                    .font(.custom("Georgia-Bold", size: 16))
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            
                            Link("View Tweet", destination: url)
                                .font(.custom("Georgia", size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.thinMaterial)
                                .cornerRadius(12)
                        }
                        .padding(.all, 16)
                        .background(.thinMaterial)
                        .cornerRadius(16)
                        .padding(.vertical, 8)
                        
                    case .linkEmbed(let url, let title, let description):
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.accentColor)
                                Text(title ?? url.absoluteString)
                                    .font(.custom("Georgia-Bold", size: 16))
                                    .lineLimit(2)
                                Spacer()
                            }
                            
                            if let description = description, !description.isEmpty {
                                Text(description)
                                    .font(.custom("Georgia", size: 14))
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                            }
                            
                            Link("Open Link", destination: url)
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(.accentColor)
                        }
                        .padding(.all, 16)
                        .background(.thinMaterial)
                        .cornerRadius(16)
                        .padding(.vertical, 8)
                        
                    case .videoEmbed(let url, let platform):
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "play.rectangle")
                                    .foregroundColor(.red)
                                Text(platformName(for: platform))
                                    .font(.custom("Georgia-Bold", size: 16))
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            
                            Link("Watch Video", destination: url)
                                .font(.custom("Georgia", size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.thinMaterial)
                                .cornerRadius(12)
                        }
                        .padding(.all, 16)
                        .background(.thinMaterial)
                        .cornerRadius(16)
                        .padding(.vertical, 8)
                        
                    case .divider:
                        Divider()
                            .padding(.vertical, 20)
                    }
                }
            }
            .frame(maxWidth: 680) // Roughly 68-72ch at 17px
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background((colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground).ignoresSafeArea())
    }
    
    // Helper functions
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
}
                        VStack(spacing: 20) {
                            Button(action: {}) {
                                Text("B")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .frame(width: 50, height: 50)
                            }
                            .scaleEffect(isPencilExpanded ? 1 : 0.1)
                            .blur(radius: isPencilExpanded ? 0 : 5)
                            .opacity(isPencilExpanded ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isPencilExpanded)
                            
                            Button(action: {}) {
                                Text("I")
                                    .font(.system(size: 24, weight: .regular))
                                    .italic()
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .frame(width: 50, height: 50)
                            }
                            .scaleEffect(isPencilExpanded ? 1 : 0.1)
                            .blur(radius: isPencilExpanded ? 0 : 5)
                            .opacity(isPencilExpanded ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: isPencilExpanded)
                            
                            Button(action: {}) {
                                Text("U")
                                    .font(.system(size: 24, weight: .regular))
                                    .underline()
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .frame(width: 50, height: 50)
                            }
                            .scaleEffect(isPencilExpanded ? 1 : 0.1)
                            .blur(radius: isPencilExpanded ? 0 : 5)
                            .opacity(isPencilExpanded ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isPencilExpanded)
                            
                            Button(action: {}) {
                                Text("S")
                                    .font(.system(size: 24, weight: .regular))
                                    .strikethrough()
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .frame(width: 50, height: 50)
                            }
                            .scaleEffect(isPencilExpanded ? 1 : 0.1)
                            .blur(radius: isPencilExpanded ? 0 : 5)
                            .opacity(isPencilExpanded ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: isPencilExpanded)
                            
                            Button(action: {}) {
                                Text("A")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(colorScheme == .dark ? .black : .white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.gray.opacity(0.6))
                                    .cornerRadius(8)
                            }
                            .scaleEffect(isPencilExpanded ? 1 : 0.1)
                            .blur(radius: isPencilExpanded ? 0 : 5)
                            .opacity(isPencilExpanded ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isPencilExpanded)
                        }
                    }
                    
                    // Bottom button (pencil transforms to X)
                    ZStack {
                        // Pencil icon
                        Image(systemName: "pencil")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .scaleEffect(isPencilExpanded ? 0.1 : 1)
                            .blur(radius: isPencilExpanded ? 5 : 0)
                            .opacity(isPencilExpanded ? 0 : 1)
                        
                        // X icon (close button)
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .scaleEffect(isPencilExpanded ? 1 : 0.1)
                            .blur(radius: isPencilExpanded ? 0 : 5)
                            .opacity(isPencilExpanded ? 1 : 0)
                    }
                    .frame(width: 84, height: 84)
                }
                .frame(width: 84, height: isPencilExpanded ? 434 : 84)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 42))
                .overlay(
                    RoundedRectangle(cornerRadius: 42)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Book Button (Bottom Right) - Comprehension Drawer
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isBookExpanded.toggle()
                }
            }) {
                VStack(spacing: isBookExpanded ? 15 : 0) {
                    // Top comprehension tools (fade in when expanded)
                    if isBookExpanded {
                        VStack(spacing: 20) {
                            Button(action: {}) {
                                HStack(spacing: 2) {
                                    Text("S")
                                        .font(.system(size: 20, weight: .regular))
                                        .blur(radius: 1)
                                    Text("r")
                                        .font(.system(size: 20, weight: .regular))
                                        .blur(radius: 1)
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(width: 50, height: 50)
                            }
                            .scaleEffect(isBookExpanded ? 1 : 0.1)
                            .blur(radius: isBookExpanded ? 0 : 5)
                            .opacity(isBookExpanded ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isBookExpanded)
                            
                            Button(action: {}) {
                                HStack(spacing: 1) {
                                    Text("B")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("r")
                                        .font(.system(size: 20, weight: .regular))
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(width: 50, height: 50)
                            }
                            .scaleEffect(isBookExpanded ? 1 : 0.1)
                            .blur(radius: isBookExpanded ? 0 : 5)
                            .opacity(isBookExpanded ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: isBookExpanded)
                            
                            Button(action: {}) {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 18))
                                    Image(systemName: "star")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(width: 50, height: 50)
                            }
                            .scaleEffect(isBookExpanded ? 1 : 0.1)
                            .blur(radius: isBookExpanded ? 0 : 5)
                            .opacity(isBookExpanded ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isBookExpanded)
                            
                            Button(action: {}) {
                                Text("Aa")
                                    .font(.custom("Times New Roman", size: 20))
                                    .italic()
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .frame(width: 50, height: 50)
                            }
                            .scaleEffect(isBookExpanded ? 1 : 0.1)
                            .blur(radius: isBookExpanded ? 0 : 5)
                            .opacity(isBookExpanded ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: isBookExpanded)
                            
                            Button(action: {}) {
                                HStack(spacing: 1) {
                                    Text("A")
                                        .font(.system(size: 22, weight: .regular))
                                    Text("A")
                                        .font(.system(size: 16, weight: .regular))
                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(width: 50, height: 50)
                            }
                            .scaleEffect(isBookExpanded ? 1 : 0.1)
                            .blur(radius: isBookExpanded ? 0 : 5)
                            .opacity(isBookExpanded ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isBookExpanded)
                        }
                    }
                    
                    // Bottom button (book transforms to X)
                    ZStack {
                        // Book icon
                        Image(systemName: "book")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .scaleEffect(isBookExpanded ? 0.1 : 1)
                            .blur(radius: isBookExpanded ? 5 : 0)
                            .opacity(isBookExpanded ? 0 : 1)
                        
                        // X icon (close button)
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .scaleEffect(isBookExpanded ? 1 : 0.1)
                            .blur(radius: isBookExpanded ? 0 : 5)
                            .opacity(isBookExpanded ? 1 : 0)
                    }
                    .frame(width: 84, height: 84)
                }
                .frame(width: 84, height: isBookExpanded ? 434 : 84)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 42))
                .overlay(
                    RoundedRectangle(cornerRadius: 42)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
        }
    }
    
    // Helper functions
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
    
    private func platformName(for platform: VideoPlatform) -> String {
        switch platform {
        case .youtube: return "YouTube"
        case .vimeo: return "Vimeo"
        case .twitter: return "Twitter"
        case .instagram: return "Instagram"
        case .other(let name): return name.capitalized
        }
    }
    
    @ViewBuilder
    private func renderImagePlaceholder(_ text: String) -> some View {
        // Extract image index from placeholder like [IMAGE_0] or [IMAGE_1] - Caption text
        if let range = text.range(of: "\\[IMAGE_(\\d+)\\](.*)$", options: .regularExpression) {
            let matchText = String(text[range])
            
            // Extract the image index
            if let indexRange = matchText.range(of: "\\d+", options: .regularExpression) {
                let imageIndex = Int(String(matchText[indexRange])) ?? 0
                
                // Extract caption (everything after the placeholder)
                let caption = matchText
                    .replacingOccurrences(of: "\\[IMAGE_\\d+\\]", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression)
                
                // Get the actual image URL from the article's inline images
                if let inlineImages = article.inlineImages,
                   imageIndex < inlineImages.count,
                   let imageURL = URL(string: inlineImages[imageIndex]) {
                    
                    VStack(alignment: .leading, spacing: 12) {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray5))
                                .frame(height: 250)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        
                        if !caption.isEmpty {
                            Text(caption)
                                .font(.custom("Georgia", size: 15))
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.vertical, 16)
                } else {
                    // Fallback if image not found - just show the text without placeholder
                    let cleanText = text.replacingOccurrences(of: "\\[IMAGE_\\d+\\]", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !cleanText.isEmpty {
                        Text(cleanText)
                            .font(.custom("Georgia", size: 18))
                            .lineSpacing(8)
                            .padding(.bottom, 12)
                    }
                }
            }
        } else {
            // Fallback - just render as regular text
            Text(text)
                .font(.custom("Georgia", size: 18))
                .lineSpacing(8)
                .padding(.bottom, 12)
        }
    }
}
