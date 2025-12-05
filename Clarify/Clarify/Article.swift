import Foundation
import CryptoKit

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

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let passwordHash: String
    let createdAt: Date
    let firstName: String?
    let lastName: String?
    
    init(email: String, password: String, firstName: String? = nil, lastName: String? = nil) {
        self.id = UUID()
        self.email = email.lowercased()
        self.passwordHash = User.hashPassword(password)
        self.createdAt = Date()
        self.firstName = firstName
        self.lastName = lastName
    }
    
    // Hash password using SHA256
    private static func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // Verify password against stored hash
    func verifyPassword(_ password: String) -> Bool {
        let hashedInput = User.hashPassword(password)
        return hashedInput == self.passwordHash
    }
    
    var displayName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            return firstName
        } else {
            return email
        }
    }
}

// MARK: - User Validation
extension User {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters, contains letter and number
        return password.count >= 8 && 
               password.rangeOfCharacter(from: .letters) != nil &&
               password.rangeOfCharacter(from: .decimalDigits) != nil
    }
}

// MARK: - User Manager
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    
    private let usersKey = "clarify_users"
    private let currentUserKey = "clarify_current_user"
    
    private init() {
        loadCurrentUser()
    }
    
    // MARK: - User Registration
    func registerUser(email: String, password: String, confirmPassword: String, firstName: String? = nil, lastName: String? = nil) -> AuthResult {
        // Validate input
        guard !email.isEmpty else {
            return .failure(.invalidEmail("Email cannot be empty"))
        }
        
        guard User.isValidEmail(email) else {
            return .failure(.invalidEmail("Please enter a valid email address"))
        }
        
        guard !password.isEmpty else {
            return .failure(.invalidPassword("Password cannot be empty"))
        }
        
        guard User.isValidPassword(password) else {
            return .failure(.invalidPassword("Password must be at least 8 characters and contain both letters and numbers"))
        }
        
        guard password == confirmPassword else {
            return .failure(.invalidPassword("Passwords do not match"))
        }
        
        // Check if user already exists
        if userExists(email: email) {
            return .failure(.userExists("An account with this email already exists"))
        }
        
        // Create new user
        let newUser = User(email: email, password: password, firstName: firstName, lastName: lastName)
        
        // Save user
        if saveUser(newUser) {
            return .success(newUser)
        } else {
            return .failure(.registrationFailed("Failed to create account. Please try again."))
        }
    }
    
    // MARK: - User Login
    func loginUser(email: String, password: String) -> AuthResult {
        // Validate input
        guard !email.isEmpty else {
            return .failure(.invalidEmail("Email cannot be empty"))
        }
        
        guard !password.isEmpty else {
            return .failure(.invalidPassword("Password cannot be empty"))
        }
        
        // Find user
        guard let user = getUser(email: email) else {
            return .failure(.invalidCredentials("No account found with this email address"))
        }
        
        // Verify password
        guard user.verifyPassword(password) else {
            return .failure(.invalidCredentials("Incorrect password"))
        }
        
        // Login successful
        setCurrentUser(user)
        return .success(user)
    }
    
    // MARK: - User Session Management
    func setCurrentUser(_ user: User) {
        DispatchQueue.main.async {
            self.currentUser = user
            self.isLoggedIn = true
        }
        saveCurrentUser(user)
    }
    
    func logout() {
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isLoggedIn = false
        }
        clearCurrentUser()
    }
    
    // MARK: - Data Persistence
    private func saveUser(_ user: User) -> Bool {
        var users = getAllUsers()
        users.append(user)
        
        do {
            let data = try JSONEncoder().encode(users)
            UserDefaults.standard.set(data, forKey: usersKey)
            return true
        } catch {
            print("Failed to save user: \(error)")
            return false
        }
    }
    
    private func getAllUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: usersKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([User].self, from: data)
        } catch {
            print("Failed to load users: \(error)")
            return []
        }
    }
    
    private func getUser(email: String) -> User? {
        let users = getAllUsers()
        return users.first { $0.email.lowercased() == email.lowercased() }
    }
    
    private func userExists(email: String) -> Bool {
        return getUser(email: email) != nil
    }
    
    private func saveCurrentUser(_ user: User) {
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.set(data, forKey: currentUserKey)
        } catch {
            print("Failed to save current user: \(error)")
        }
    }
    
    private func loadCurrentUser() {
        guard let data = UserDefaults.standard.data(forKey: currentUserKey) else {
            return
        }
        
        do {
            let user = try JSONDecoder().decode(User.self, from: data)
            DispatchQueue.main.async {
                self.currentUser = user
                self.isLoggedIn = true
            }
        } catch {
            print("Failed to load current user: \(error)")
        }
    }
    
    private func clearCurrentUser() {
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }
}

// MARK: - Auth Result Types
enum AuthResult {
    case success(User)
    case failure(AuthError)
}

enum AuthError {
    case invalidEmail(String)
    case invalidPassword(String)
    case invalidCredentials(String)
    case userExists(String)
    case registrationFailed(String)
    
    var message: String {
        switch self {
        case .invalidEmail(let message),
             .invalidPassword(let message),
             .invalidCredentials(let message),
             .userExists(let message),
             .registrationFailed(let message):
            return message
        }
    }
}

