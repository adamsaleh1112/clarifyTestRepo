import Foundation

enum ArticleContent: Identifiable, Codable {
    case heading(String, level: Int)
    case paragraph(String)
    case richParagraph([TextSegment])
    case image(URL, caption: String?, alt: String?)
    case quote(String, author: String?)
    case list([String], ordered: Bool)
    case twitterEmbed(tweetId: String, url: URL)
    case linkEmbed(url: URL, title: String?, description: String?)
    case videoEmbed(url: URL, platform: VideoPlatform)
    case divider
    
    var id: UUID { UUID() }
}

enum TextSegment: Identifiable, Codable {
    case text(String)
    case boldText(String)
    case italicText(String)
    case link(text: String, url: URL)
    
    var id: UUID { UUID() }
}

enum VideoPlatform: Codable {
    case youtube
    case vimeo
    case twitter
    case instagram
    case other(String)
}

struct Article: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: String
    var coverImageURL: URL?
    var content: [ArticleContent]
    var inlineImages: [String]? // Store inline image URLs
    var sourceName: String? // News source name (e.g., "CNBC.COM")
    var sourceLogoURL: URL? // URL to source logo image
    var pdfURL: URL? // For PDF documents
    var pdfTextContent: String? // Extracted text for AI context (not displayed)
    var isPDF: Bool { return pdfURL != nil }
    
    // Reading progress and metadata
    var isFavorite: Bool = false
    var readingProgress: Double = 0.0 // 0.0 to 1.0
    var lastReadDate: Date?
    var estimatedReadingTimeMinutes: Int?
    var aiSummary: String?
    
    init(title: String, date: String, coverImageURL: URL? = nil, content: [ArticleContent], inlineImages: [String]? = nil, sourceName: String? = nil, sourceLogoURL: URL? = nil, pdfURL: URL? = nil, pdfTextContent: String? = nil) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.coverImageURL = coverImageURL
        self.content = content
        self.inlineImages = inlineImages
        self.sourceName = sourceName
        self.sourceLogoURL = sourceLogoURL
        self.pdfURL = pdfURL
        self.pdfTextContent = pdfTextContent
        self.estimatedReadingTimeMinutes = Self.calculateReadingTime(content: content)
    }
    
    // Calculate estimated reading time (250 words per minute average)
    static func calculateReadingTime(content: [ArticleContent]) -> Int {
        let totalWords = content.reduce(0) { total, item in
            switch item {
            case .paragraph(let text), .heading(let text, _), .quote(let text, _):
                return total + text.split(separator: " ").count
            case .richParagraph(let segments):
                return total + segments.reduce(0) { segTotal, segment in
                    switch segment {
                    case .text(let text), .boldText(let text), .italicText(let text), .link(let text, _):
                        return segTotal + text.split(separator: " ").count
                    }
                }
            case .list(let items, _):
                return total + items.reduce(0) { $0 + $1.split(separator: " ").count }
            default:
                return total
            }
        }
        return max(1, Int(Double(totalWords) / 250.0))
    }
}

