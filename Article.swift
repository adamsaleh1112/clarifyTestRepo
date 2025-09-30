import Foundation

enum ArticleContent: Identifiable {
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

enum TextSegment: Identifiable {
    case text(String)
    case boldText(String)
    case italicText(String)
    case link(text: String, url: URL)
    
    var id: UUID { UUID() }
}

enum VideoPlatform {
    case youtube
    case vimeo
    case twitter
    case instagram
    case other(String)
}

struct Article: Identifiable {
    let id = UUID()
    var title: String
    var date: String
    var coverImageURL: URL?
    var content: [ArticleContent]
    var inlineImages: [String]? // Store inline image URLs
}

