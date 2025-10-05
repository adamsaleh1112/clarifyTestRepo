import Foundation
import SwiftSoup
import PDFKit
import UIKit

enum ArticleParseError: Error {
    case invalidURL
    case networkError(Error)
    case parsingFailed
}

struct ContentBlock {
    enum BlockType {
        case heading
        case paragraph
        case quote
        case caption
        case listItem
        case image
    }
    
    let type: BlockType
    let text: String
    let imageUrl: String?
    let position: Int
    
    init(type: BlockType, text: String, imageUrl: String? = nil, position: Int) {
        self.type = type
        self.text = text
        self.imageUrl = imageUrl
        self.position = position
    }
}

class ArticleParser {
    
    func parse(urlString: String, completion: @escaping (Result<Article, ArticleParseError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Validate URL format
        guard urlString.hasPrefix("http://") || urlString.hasPrefix("https://") else {
            completion(.failure(.parsingFailed))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(.networkError(error))) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(.failure(.parsingFailed)) }
                return
            }
            
            // Handle HTTP errors like the React Native version
            if httpResponse.statusCode == 404 {
                DispatchQueue.main.async { completion(.failure(.parsingFailed)) }
                return
            } else if httpResponse.statusCode == 403 {
                DispatchQueue.main.async { completion(.failure(.parsingFailed)) }
                return
            } else if httpResponse.statusCode >= 500 {
                DispatchQueue.main.async { completion(.failure(.parsingFailed)) }
                return
            } else if httpResponse.statusCode != 200 {
                DispatchQueue.main.async { completion(.failure(.parsingFailed)) }
                return
            }

            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async { completion(.failure(.parsingFailed)) }
                return
            }
            
            // Check if HTML is too short
            if html.count < 100 {
                DispatchQueue.main.async { completion(.failure(.parsingFailed)) }
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let doc = try SwiftSoup.parse(html)
                    
                    // Extract title (matching React Native priority)
                    let title = try self.extractTitle(from: doc, html: html)
                    
                    // Extract main image (matching React Native priority)
                    let imageUrl = try self.extractMainImage(from: doc, html: html, baseURL: url)
                    
                    // Extract structured content with inline images
                    let (content, inlineImages) = try self.extractStructuredContent(from: doc, html: html, baseURL: url)
                    
                    // Validate content quality
                    if content.count < 100 {
                        DispatchQueue.main.async { completion(.failure(.parsingFailed)) }
                        return
                    }
                    
                    let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).count > 5 }
                    if sentences.count < 2 {
                        DispatchQueue.main.async { completion(.failure(.parsingFailed)) }
                        return
                    }
                    
                    // Clean content
                    let cleanedContent = self.cleanContent(content)
                    
                    let publishDate = self.formatCurrentDate()
                    
                    // Create article content from structured text
                    let articleContent = self.parseStructuredContent(cleanedContent, inlineImages: inlineImages)
                    
                    let article = Article(
                        title: String(title.prefix(150)),
                        date: publishDate,
                        coverImageURL: imageUrl,
                        content: articleContent,
                        inlineImages: inlineImages.isEmpty ? nil : inlineImages,
                        sourceName: url.host?.uppercased(),
                        sourceLogoURL: self.generateFaviconURL(from: url)
                    )
                    
                    DispatchQueue.main.async {
                        completion(.success(article))
                    }
                } catch {
                    print("❌ Parsing error: \(error)")
                    DispatchQueue.main.async {
                        completion(.failure(.parsingFailed))
                    }
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Title Extraction (matching React Native priority)
    private func extractTitle(from document: Document, html: String) throws -> String {
        // Try title tag first
        if let titleMatch = html.range(of: "<title>(.*?)</title>", options: [.regularExpression, .caseInsensitive]) {
            let titleText = String(html[titleMatch])
                .replacingOccurrences(of: "<title>", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "</title>", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "&[^;]+;", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !titleText.isEmpty {
                return titleText
            }
        }
        
        return "Untitled Article"
    }
    
    // MARK: - Main Image Extraction (matching React Native priority)
    private func extractMainImage(from document: Document, html: String, baseURL: URL) throws -> URL? {
        // Try Open Graph image first (most reliable for news sites)
        if let ogImageMatch = html.range(of: "<meta[^>]*property=[\"']og:image[\"'][^>]*content=[\"']([^\"']+)[\"']", options: [.regularExpression, .caseInsensitive]) {
            let ogImageText = String(html[ogImageMatch])
            if let contentMatch = ogImageText.range(of: "content=[\"']([^\"']+)[\"']", options: .regularExpression) {
                let imageUrl = String(ogImageText[contentMatch])
                    .replacingOccurrences(of: "content=[\"']", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "[\"']", with: "", options: .regularExpression)
                
                if let resolvedURL = resolveImageURL(imageUrl, baseURL: baseURL) {
                    return resolvedURL
                }
            }
        }
        
        // Fallback to Twitter Card image
        if let twitterImageMatch = html.range(of: "<meta[^>]*name=[\"']twitter:image[\"'][^>]*content=[\"']([^\"']+)[\"']", options: [.regularExpression, .caseInsensitive]) {
            let twitterImageText = String(html[twitterImageMatch])
            if let contentMatch = twitterImageText.range(of: "content=[\"']([^\"']+)[\"']", options: .regularExpression) {
                let imageUrl = String(twitterImageText[contentMatch])
                    .replacingOccurrences(of: "content=[\"']", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "[\"']", with: "", options: .regularExpression)
                
                if let resolvedURL = resolveImageURL(imageUrl, baseURL: baseURL) {
                    return resolvedURL
                }
            }
        }
        
        // Fallback to article images (matching React Native selectors)
        let articleImagePatterns = [
            "<article[^>]*>[\\s\\S]*?<img[^>]*src=[\"']([^\"']+)[\"'][^>]*>",
            "<main[^>]*>[\\s\\S]*?<img[^>]*src=[\"']([^\"']+)[\"'][^>]*>",
            "<div[^>]*class=[\"'][^\"']*(?:hero|featured|main)[^\"']*[\"'][^>]*>[\\s\\S]*?<img[^>]*src=[\"']([^\"']+)[\"'][^>]*>"
        ]
        
        for pattern in articleImagePatterns {
            if let match = html.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchText = String(html[match])
                if let srcMatch = matchText.range(of: "src=[\"']([^\"']+)[\"']", options: .regularExpression) {
                    let imageUrl = String(matchText[srcMatch])
                        .replacingOccurrences(of: "src=[\"']", with: "", options: .regularExpression)
                        .replacingOccurrences(of: "[\"']", with: "", options: .regularExpression)
                    
                    if let resolvedURL = resolveImageURL(imageUrl, baseURL: baseURL) {
                        return resolvedURL
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Structured Content Extraction (matching React Native logic)
    private func extractStructuredContent(from document: Document, html: String, baseURL: URL) throws -> (String, [String]) {
        var extractedInlineImages: [String] = []
        
        // Enhanced content extraction with better selectors and priority (matching React Native)
        let articleSelectors = [
            // High priority - semantic article tags
            "<article[^>]*>([\\s\\S]*?)</article>",
            "<main[^>]*>([\\s\\S]*?)</main>",
            
            // Medium priority - common content containers
            "<div[^>]*class=[\"'][^\"']*(?:post-content|article-content|entry-content|story-body|article-body)[^\"']*[\"'][^>]*>([\\s\\S]*?)</div>",
            "<div[^>]*class=[\"'][^\"']*(?:content|article|post|entry|story)[^\"']*[\"'][^>]*>([\\s\\S]*?)</div>",
            "<section[^>]*class=[\"'][^\"']*(?:content|article|post|entry|story)[^\"']*[\"'][^>]*>([\\s\\S]*?)</section>",
            
            // Lower priority - ID-based selectors
            "<div[^>]*id=[\"'][^\"']*(?:content|article|post|entry|story)[^\"']*[\"'][^>]*>([\\s\\S]*?)</div>",
            
            // News-specific selectors
            "<div[^>]*class=[\"'][^\"']*(?:article-text|story-text|post-body|entry-body)[^\"']*[\"'][^>]*>([\\s\\S]*?)</div>",
            "<div[^>]*data-module=[\"']ArticleBody[\"'][^>]*>([\\s\\S]*?)</div>"
        ]
        
        for selector in articleSelectors {
            let matches = html.matches(of: selector, options: [.regularExpression, .caseInsensitive])
            
            if !matches.isEmpty {
                for match in matches {
                    let matchText = String(html[match])
                    let (blocks, images) = extractStructuredContentBlocks(from: matchText, baseURL: baseURL)
                    
                    if blocks.count >= 3 {
                        extractedInlineImages = images
                        let formattedContent = formatStructuredBlocks(blocks, inlineImages: images)
                        
                        if formattedContent.count > 300 {
                            return (formattedContent, extractedInlineImages)
                        }
                    }
                }
            }
        }
        
        // Enhanced fallback with basic paragraph detection (matching React Native)
        let paragraphMatches = html.matches(of: "<p[^>]*>([\\s\\S]*?)</p>", options: [.regularExpression, .caseInsensitive])
        
        if !paragraphMatches.isEmpty {
            var processedParagraphs: [String] = []
            
            for match in paragraphMatches {
                let pText = String(html[match])
                let cleanText = cleanParagraphText(pText)
                
                if cleanText.count > 40 && isValidParagraph(cleanText) {
                    let captionKeywords = "^(photo|image|picture|caption|credit|getty|reuters|ap|afp):"
                    if cleanText.count < 150 && cleanText.range(of: captionKeywords, options: [.regularExpression, .caseInsensitive]) != nil {
                        processedParagraphs.append("*\(cleanText)*")
                    } else {
                        processedParagraphs.append(cleanText)
                    }
                }
            }
            
            if processedParagraphs.count >= 3 {
                let content = Array(processedParagraphs.prefix(15)).joined(separator: "\n\n")
                return (content, extractedInlineImages)
            }
        }
        
        return ("Content could not be extracted", [])
    }
    
    // MARK: - Helper Methods
    private func extractStructuredContentBlocks(from htmlContent: String, baseURL: URL) -> ([ContentBlock], [String]) {
        var extractedImages: [String] = []
        
        // Remove unwanted elements first but preserve structure for positioning
        let cleanHtml = cleanHTMLContent(htmlContent)
        
        // Parse content in document order to maintain positioning
        var contentElements: [ContentBlock] = []
        
        // Extract all content elements with their positions (matching React Native regex)
        let allElementsPattern = "<(h[1-6]|p|blockquote|figure|img|li)[^>]*>[\\s\\S]*?</\\1>|<img[^>]*/?>"
        let allElements = cleanHtml.matches(of: allElementsPattern, options: [.regularExpression, .caseInsensitive])
        
        for (index, match) in allElements.enumerated() {
            let element = String(cleanHtml[match])
            let tagMatch = element.matches(of: "<(\\w+)", options: .regularExpression)
            
            guard let firstTagMatch = tagMatch.first else { continue }
            let tag = String(element[firstTagMatch]).replacingOccurrences(of: "<", with: "").lowercased()
            
            switch tag {
            case "h1", "h2", "h3", "h4", "h5", "h6":
                let headingText = stripHTMLTags(element).trimmingCharacters(in: .whitespacesAndNewlines)
                if headingText.count > 5 {
                    contentElements.append(ContentBlock(type: .heading, text: headingText, position: index))
                }
                
            case "p":
                let paraText = cleanParagraphText(element)
                if paraText.count > 30 {
                    let captionKeywords = "^(photo|image|picture|caption|credit|getty|reuters|ap|afp):"
                    let isShortAndImageRelated = paraText.count < 150 && paraText.range(of: captionKeywords, options: [.regularExpression, .caseInsensitive]) != nil
                    
                    if isShortAndImageRelated {
                        contentElements.append(ContentBlock(type: .caption, text: paraText, position: index))
                    } else {
                        contentElements.append(ContentBlock(type: .paragraph, text: paraText, position: index))
                    }
                }
                
            case "blockquote":
                let quoteText = stripHTMLTags(element).trimmingCharacters(in: .whitespacesAndNewlines)
                if quoteText.count > 20 {
                    contentElements.append(ContentBlock(type: .quote, text: quoteText, position: index))
                }
                
            case "figure":
                // Extract image from figure
                if let imgMatch = element.range(of: "<img[^>]*src=[\"']([^\"']+)[\"'][^>]*>", options: [.regularExpression, .caseInsensitive]) {
                    let imgText = String(element[imgMatch])
                    if let srcMatch = imgText.range(of: "src=[\"']([^\"']+)[\"']", options: .regularExpression) {
                        let imgSrc = String(imgText[srcMatch])
                            .replacingOccurrences(of: "src=[\"']", with: "", options: .regularExpression)
                            .replacingOccurrences(of: "[\"']", with: "", options: .regularExpression)
                        
                        if let imgUrl = resolveImageURL(imgSrc, baseURL: baseURL) {
                            extractedImages.append(imgUrl.absoluteString)
                            contentElements.append(ContentBlock(type: .image, text: "", imageUrl: imgUrl.absoluteString, position: index))
                            
                            // Check for figcaption
                            if let captionMatch = element.range(of: "<figcaption[^>]*>([\\s\\S]*?)</figcaption>", options: [.regularExpression, .caseInsensitive]) {
                                let captionText = stripHTMLTags(String(element[captionMatch])).trimmingCharacters(in: .whitespacesAndNewlines)
                                if captionText.count > 10 {
                                    contentElements.append(ContentBlock(type: .caption, text: captionText, position: index))
                                }
                            }
                        }
                    }
                }
                
            case "img":
                if let srcMatch = element.range(of: "src=[\"']([^\"']+)[\"']", options: .regularExpression) {
                    let imgSrc = String(element[srcMatch])
                        .replacingOccurrences(of: "src=[\"']", with: "", options: .regularExpression)
                        .replacingOccurrences(of: "[\"']", with: "", options: .regularExpression)
                    
                    let altText = extractAttribute(from: element, attribute: "alt")
                    
                    // Filter out small/icon images (matching React Native logic)
                    let width = Int(extractAttribute(from: element, attribute: "width")) ?? 0
                    let height = Int(extractAttribute(from: element, attribute: "height")) ?? 0
                    
                    // Only include substantial images (not icons/buttons)
                    if (width == 0 || width > 100) && (height == 0 || height > 100) {
                        if let imgUrl = resolveImageURL(imgSrc, baseURL: baseURL) {
                            extractedImages.append(imgUrl.absoluteString)
                            contentElements.append(ContentBlock(type: .image, text: altText, imageUrl: imgUrl.absoluteString, position: index))
                        }
                    }
                }
                
            case "li":
                let listText = stripHTMLTags(element).trimmingCharacters(in: .whitespacesAndNewlines)
                if listText.count > 15 {
                    contentElements.append(ContentBlock(type: .listItem, text: listText, position: index))
                }
                
            default:
                break
            }
        }
        
        // Sort by position to maintain document order
        let sortedElements = contentElements.sorted { $0.position < $1.position }
        return (sortedElements, extractedImages)
    }
    
    private func formatStructuredBlocks(_ blocks: [ContentBlock], inlineImages: [String]) -> String {
        return blocks.map { block in
            switch block.type {
            case .heading:
                return "\n\n## \(block.text)\n"
            case .quote:
                return "\n> \(block.text)\n"
            case .caption:
                return "\n*\(block.text)*\n"
            case .listItem:
                return "• \(block.text)"
            case .image:
                if let imageUrl = block.imageUrl, let imageIndex = inlineImages.firstIndex(of: imageUrl) {
                    let altText = block.text.isEmpty ? "" : " - \(block.text)"
                    return "\n[IMAGE_\(imageIndex)]\(altText)\n"
                }
                return ""
            case .paragraph:
                return "\n\(block.text)\n"
            }
        }.joined().replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseStructuredContent(_ content: String, inlineImages: [String]) -> [ArticleContent] {
        var articleContent: [ArticleContent] = []
        
        // Split content by image placeholders and render mixed content
        let parts = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        for part in parts {
            let trimmedPart = part.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for image placeholder
            if let imageMatch = trimmedPart.range(of: "\\[IMAGE_(\\d+)\\](.*)$", options: .regularExpression) {
                let imageText = String(trimmedPart[imageMatch])
                if let indexMatch = imageText.range(of: "\\d+", options: .regularExpression) {
                    let imageIndex = Int(String(imageText[indexMatch])) ?? 0
                    let imageCaption = imageText.replacingOccurrences(of: "\\[IMAGE_\\d+\\]", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression)
                    
                    if imageIndex < inlineImages.count, let imageURL = URL(string: inlineImages[imageIndex]) {
                        articleContent.append(.image(imageURL, caption: imageCaption.isEmpty ? nil : imageCaption, alt: nil))
                    }
                }
            }
            // Check for heading
            else if trimmedPart.hasPrefix("## ") {
                let headingText = String(trimmedPart.dropFirst(3))
                articleContent.append(.heading(headingText, level: 2))
            }
            // Check for quote
            else if trimmedPart.hasPrefix("> ") {
                let quoteText = String(trimmedPart.dropFirst(2))
                articleContent.append(.quote(quoteText, author: nil))
            }
            // Check for caption
            else if trimmedPart.hasPrefix("*") && trimmedPart.hasSuffix("*") {
                let captionText = String(trimmedPart.dropFirst().dropLast())
                // For now, treat captions as paragraphs with italic styling
                articleContent.append(.paragraph(captionText))
            }
            // Check for list item
            else if trimmedPart.hasPrefix("• ") {
                let listText = String(trimmedPart.dropFirst(2))
                articleContent.append(.paragraph("• \(listText)"))
            }
            // Regular paragraph
            else if !trimmedPart.isEmpty {
                articleContent.append(.paragraph(trimmedPart))
            }
        }
        
        return articleContent
    }
    
    // MARK: - Utility Methods
    private func resolveImageURL(_ imageUrl: String, baseURL: URL) -> URL? {
        if imageUrl.isEmpty || imageUrl.hasPrefix("data:") {
            return nil
        }
        
        if imageUrl.hasPrefix("http") {
            return URL(string: imageUrl)
        }
        
        if imageUrl.hasPrefix("//") {
            return URL(string: "\(baseURL.scheme ?? "https"):\(imageUrl)")
        }
        
        if imageUrl.hasPrefix("/") {
            return URL(string: "\(baseURL.scheme ?? "https")://\(baseURL.host ?? "")\(imageUrl)")
        }
        
        return URL(string: "\(baseURL.scheme ?? "https")://\(baseURL.host ?? "")/\(imageUrl)")
    }
    
    private func cleanHTMLContent(_ html: String) -> String {
        return html
            .replacingOccurrences(of: "<script[\\s\\S]*?</script>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<style[\\s\\S]*?</style>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<nav[\\s\\S]*?</nav>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<header[\\s\\S]*?</header>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<footer[\\s\\S]*?</footer>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<aside[\\s\\S]*?</aside>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<form[\\s\\S]*?</form>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<iframe[\\s\\S]*?</iframe>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<div[^>]*class=[\"'][^\"']*(?:ad|advertisement|ads|promo|social|share|sidebar|menu|navigation|related|recommended|newsletter|subscribe)[^\"']*[\"'][^>]*>[\\s\\S]*?</div>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<!--[\\s\\S]*?-->", with: "", options: .regularExpression)
    }
    
    private func stripHTMLTags(_ html: String) -> String {
        return html
            .replacingOccurrences(of: "<[^>]*>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&[^;]+;", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func cleanParagraphText(_ pText: String) -> String {
        return pText
            .replacingOccurrences(of: "<[^>]*>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&mdash;", with: "—")
            .replacingOccurrences(of: "&ndash;", with: "–")
            .replacingOccurrences(of: "&[^;]+;", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func isValidParagraph(_ text: String) -> Bool {
        let invalidPatterns = [
            "^(advertisement|ad|subscribe|follow|share|click|read more|continue reading|related articles|tags:|categories:|posted by|published|updated|copyright|all rights reserved)$",
            "^[\\d\\s\\/:-]+$"
        ]
        
        for pattern in invalidPatterns {
            if text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                return false
            }
        }
        
        return text.components(separatedBy: " ").count >= 8
    }
    
    private func extractAttribute(from element: String, attribute: String) -> String {
        let pattern = "\(attribute)=[\"']?([^\"'\\s>]+)[\"']?"
        if let match = element.range(of: pattern, options: .regularExpression) {
            let matchText = String(element[match])
            return matchText
                .replacingOccurrences(of: "\(attribute)=[\"']?", with: "", options: .regularExpression)
                .replacingOccurrences(of: "[\"']", with: "", options: .regularExpression)
        }
        return ""
    }
    
    private func cleanContent(_ content: String) -> String {
        return content
            .replacingOccurrences(of: "^(By\\s+[^\\n]+\\n|Published\\s+[^\\n]+\\n|Updated\\s+[^\\n]+\\n)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "(Subscribe to our newsletter|Follow us on|Share this article|Related articles?)[\\s\\S]*$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func formatCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
    
    private func generateFaviconURL(from url: URL) -> URL? {
        guard let host = url.host else { return nil }
        return URL(string: "https://\(host)/favicon.ico")
    }
    
    // MARK: - PDF Parsing
    func createPDFArticle(from url: URL, completion: @escaping (Result<Article, ArticleParseError>) -> Void) {
        // Ensure we can access the file
        guard url.startAccessingSecurityScopedResource() else {
            completion(.failure(.parsingFailed))
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Verify it's a valid PDF and extract text for AI
        guard let pdfDocument = PDFDocument(url: url) else {
            completion(.failure(.parsingFailed))
            return
        }
        
        // Extract text from all pages for AI context
        var extractedText = ""
        let pageCount = pdfDocument.pageCount
        
        for pageIndex in 0..<pageCount {
            if let page = pdfDocument.page(at: pageIndex) {
                if let pageText = page.string {
                    extractedText += pageText + "\n\n"
                }
            }
        }
        
        // Clean up the extracted text
        extractedText = extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Generate thumbnail from first page
        var thumbnailURL: URL? = nil
        if let firstPage = pdfDocument.page(at: 0) {
            thumbnailURL = generatePDFThumbnail(from: firstPage, fileName: url.lastPathComponent)
        }
        
        // Copy PDF to app's documents directory for persistent access
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = url.lastPathComponent
        let destinationURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy the PDF to documents directory
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Create article with PDF reference
            let title = url.deletingPathExtension().lastPathComponent
            let displayTitle = title.isEmpty ? "PDF Document" : title
            
            let article = Article(
                title: displayTitle,
                date: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                coverImageURL: thumbnailURL,
                content: [], // Empty content for PDF articles (not displayed)
                inlineImages: nil,
                sourceName: "PDF Document",
                sourceLogoURL: nil,
                pdfURL: destinationURL,
                pdfTextContent: extractedText.isEmpty ? nil : extractedText
            )
            
            DispatchQueue.main.async {
                completion(.success(article))
            }
            
        } catch {
            completion(.failure(.networkError(error)))
        }
    }
    
    // MARK: - Text File Parsing
    func parseTextFile(from url: URL, completion: @escaping (Result<Article, ArticleParseError>) -> Void) {
        // Ensure we can access the file
        guard url.startAccessingSecurityScopedResource() else {
            completion(.failure(.parsingFailed))
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let fileName = url.deletingPathExtension().lastPathComponent
            let title = fileName.isEmpty ? "Text Document" : fileName
            
            // Split text into paragraphs
            let paragraphs = content.components(separatedBy: "\n\n")
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            let articleContent: [ArticleContent] = paragraphs.map { paragraph in
                let cleanParagraph = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Simple heuristic for headings
                if cleanParagraph.count < 100 && (cleanParagraph.hasPrefix("#") || cleanParagraph.uppercased() == cleanParagraph) {
                    return .heading(cleanParagraph.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces), level: 2)
                } else {
                    return .paragraph(cleanParagraph)
                }
            }
            
            let article = Article(
                title: title,
                date: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                coverImageURL: nil,
                content: articleContent,
                inlineImages: nil,
                sourceName: "Text Document",
                sourceLogoURL: nil
            )
            
            DispatchQueue.main.async {
                completion(.success(article))
            }
            
        } catch {
            completion(.failure(.networkError(error)))
        }
    }
    
    // MARK: - PDF Thumbnail Generation
    private func generatePDFThumbnail(from page: PDFPage, fileName: String) -> URL? {
        // Create thumbnail image from PDF page
        let thumbnailSize = CGSize(width: 300, height: 400) // Standard thumbnail size
        let pageRect = page.bounds(for: .mediaBox)
        
        // Calculate scale to fit thumbnail size while maintaining aspect ratio
        let scaleX = thumbnailSize.width / pageRect.width
        let scaleY = thumbnailSize.height / pageRect.height
        let scale = min(scaleX, scaleY)
        
        let scaledSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )
        
        // Create image context
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        // Fill with white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: scaledSize))
        
        // Save the graphics state
        context.saveGState()
        
        // Fix coordinate system - flip vertically and translate
        context.translateBy(x: 0, y: scaledSize.height)
        context.scaleBy(x: scale, y: -scale)
        
        // Draw the PDF page
        page.draw(with: .mediaBox, to: context)
        
        // Restore the graphics state
        context.restoreGState()
        
        // Get the image
        guard let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()
        
        // Save thumbnail to documents directory
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let thumbnailFileName = fileName.replacingOccurrences(of: ".pdf", with: "_thumbnail.jpg")
        let thumbnailURL = documentsPath.appendingPathComponent("thumbnails").appendingPathComponent(thumbnailFileName)
        
        // Create thumbnails directory if it doesn't exist
        let thumbnailsDir = documentsPath.appendingPathComponent("thumbnails")
        try? FileManager.default.createDirectory(at: thumbnailsDir, withIntermediateDirectories: true)
        
        // Convert to JPEG and save
        guard let imageData = thumbnailImage.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        do {
            try imageData.write(to: thumbnailURL)
            return thumbnailURL
        } catch {
            print("❌ Failed to save PDF thumbnail: \(error)")
            return nil
        }
    }
}

// Extension to help with regex matching
extension String {
    func matches(of pattern: String, options: NSString.CompareOptions = []) -> [Range<String.Index>] {
        var matches: [Range<String.Index>] = []
        var searchRange = self.startIndex..<self.endIndex
        
        while let range = self.range(of: pattern, options: options.union(.regularExpression), range: searchRange) {
            matches.append(range)
            searchRange = range.upperBound..<self.endIndex
        }
        
        return matches
    }
}