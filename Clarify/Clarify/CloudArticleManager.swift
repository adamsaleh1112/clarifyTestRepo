import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Cloud Data Models
struct CloudArticle: Codable {
    let id: String
    let title: String
    let content: String
    let url: String?
    let createdAt: Date
    let updatedAt: Date
    let readingProgress: Double
    let isFavorite: Bool
    let lastReadDate: Date?
    let aiSummary: String?
    let estimatedReadingTimeMinutes: Int
    
    // Convert to local Article model
    func toArticle() -> Article {
        return Article(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            content: content,
            url: url,
            createdAt: createdAt,
            readingProgress: readingProgress,
            isFavorite: isFavorite,
            lastReadDate: lastReadDate,
            aiSummary: aiSummary,
            estimatedReadingTimeMinutes: estimatedReadingTimeMinutes
        )
    }
}

struct UserPreferences: Codable {
    let appearance: String // "light", "dark", "system"
    let typography: String // "modern", "serif", "condensed"
    let readingSpeed: Int // words per minute
    let readingGoals: ReadingGoals?
    let notificationsEnabled: Bool
    let updatedAt: Date
}

struct ReadingGoals: Codable {
    let dailyArticles: Int
    let weeklyReadingTime: Int // minutes
    let monthlyGoal: Int
}

struct ReadingStats: Codable {
    let totalArticlesRead: Int
    let totalReadingTimeMinutes: Int
    let streakDays: Int
    let lastReadDate: Date?
    let updatedAt: Date
}

// MARK: - Cloud Article Manager
class CloudArticleManager: ObservableObject {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    // MARK: - Article Operations
    
    /// Upload article to Firebase for current user
    func uploadArticle(_ article: Article) async -> Result<Void, CloudError> {
        guard let userId = auth.currentUser?.uid else {
            return .failure(.notAuthenticated)
        }
        
        let cloudArticle = CloudArticle(
            id: article.id.uuidString,
            title: article.title,
            content: article.content,
            url: article.url,
            createdAt: article.createdAt,
            updatedAt: Date(),
            readingProgress: article.readingProgress,
            isFavorite: article.isFavorite,
            lastReadDate: article.lastReadDate,
            aiSummary: article.aiSummary,
            estimatedReadingTimeMinutes: article.estimatedReadingTimeMinutes
        )
        
        do {
            let encoder = Firestore.Encoder()
            let data = try encoder.encode(cloudArticle)
            
            try await db.collection("users")
                .document(userId)
                .collection("articles")
                .document(article.id.uuidString)
                .setData(data)
            
            print("✅ Article uploaded to Firebase: \(article.title)")
            return .success(())
            
        } catch {
            print("❌ Failed to upload article: \(error)")
            return .failure(.uploadFailed(error.localizedDescription))
        }
    }
    
    /// Download all articles for current user
    func downloadArticles() async -> Result<[Article], CloudError> {
        guard let userId = auth.currentUser?.uid else {
            return .failure(.notAuthenticated)
        }
        
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("articles")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let decoder = Firestore.Decoder()
            var articles: [Article] = []
            
            for document in snapshot.documents {
                do {
                    let cloudArticle = try decoder.decode(CloudArticle.self, from: document.data())
                    articles.append(cloudArticle.toArticle())
                } catch {
                    print("⚠️ Failed to decode article \(document.documentID): \(error)")
                }
            }
            
            print("✅ Downloaded \(articles.count) articles from Firebase")
            return .success(articles)
            
        } catch {
            print("❌ Failed to download articles: \(error)")
            return .failure(.downloadFailed(error.localizedDescription))
        }
    }
    
    /// Update article progress in Firebase
    func updateArticleProgress(_ articleId: String, progress: Double, lastReadDate: Date) async -> Result<Void, CloudError> {
        guard let userId = auth.currentUser?.uid else {
            return .failure(.notAuthenticated)
        }
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("articles")
                .document(articleId)
                .updateData([
                    "readingProgress": progress,
                    "lastReadDate": Timestamp(date: lastReadDate),
                    "updatedAt": Timestamp(date: Date())
                ])
            
            return .success(())
            
        } catch {
            print("❌ Failed to update article progress: \(error)")
            return .failure(.updateFailed(error.localizedDescription))
        }
    }
    
    /// Toggle article favorite status in Firebase
    func toggleArticleFavorite(_ articleId: String, isFavorite: Bool) async -> Result<Void, CloudError> {
        guard let userId = auth.currentUser?.uid else {
            return .failure(.notAuthenticated)
        }
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("articles")
                .document(articleId)
                .updateData([
                    "isFavorite": isFavorite,
                    "updatedAt": Timestamp(date: Date())
                ])
            
            return .success(())
            
        } catch {
            print("❌ Failed to toggle article favorite: \(error)")
            return .failure(.updateFailed(error.localizedDescription))
        }
    }
    
    /// Delete article from Firebase
    func deleteArticle(_ articleId: String) async -> Result<Void, CloudError> {
        guard let userId = auth.currentUser?.uid else {
            return .failure(.notAuthenticated)
        }
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("articles")
                .document(articleId)
                .delete()
            
            print("✅ Article deleted from Firebase: \(articleId)")
            return .success(())
            
        } catch {
            print("❌ Failed to delete article: \(error)")
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
    
    // MARK: - User Preferences Operations
    
    /// Upload user preferences to Firebase
    func uploadUserPreferences(_ preferences: UserPreferences) async -> Result<Void, CloudError> {
        guard let userId = auth.currentUser?.uid else {
            return .failure(.notAuthenticated)
        }
        
        do {
            let encoder = Firestore.Encoder()
            let data = try encoder.encode(preferences)
            
            try await db.collection("users")
                .document(userId)
                .collection("preferences")
                .document("settings")
                .setData(data)
            
            print("✅ User preferences uploaded to Firebase")
            return .success(())
            
        } catch {
            print("❌ Failed to upload preferences: \(error)")
            return .failure(.uploadFailed(error.localizedDescription))
        }
    }
    
    /// Download user preferences from Firebase
    func downloadUserPreferences() async -> Result<UserPreferences?, CloudError> {
        guard let userId = auth.currentUser?.uid else {
            return .failure(.notAuthenticated)
        }
        
        do {
            let document = try await db.collection("users")
                .document(userId)
                .collection("preferences")
                .document("settings")
                .getDocument()
            
            guard document.exists, let data = document.data() else {
                return .success(nil) // No preferences found
            }
            
            let decoder = Firestore.Decoder()
            let preferences = try decoder.decode(UserPreferences.self, from: data)
            
            print("✅ User preferences downloaded from Firebase")
            return .success(preferences)
            
        } catch {
            print("❌ Failed to download preferences: \(error)")
            return .failure(.downloadFailed(error.localizedDescription))
        }
    }
    
    // MARK: - Reading Stats Operations
    
    /// Update reading stats in Firebase
    func updateReadingStats(_ stats: ReadingStats) async -> Result<Void, CloudError> {
        guard let userId = auth.currentUser?.uid else {
            return .failure(.notAuthenticated)
        }
        
        do {
            let encoder = Firestore.Encoder()
            let data = try encoder.encode(stats)
            
            try await db.collection("users")
                .document(userId)
                .collection("reading_stats")
                .document("current")
                .setData(data)
            
            return .success(())
            
        } catch {
            print("❌ Failed to update reading stats: \(error)")
            return .failure(.updateFailed(error.localizedDescription))
        }
    }
    
    // MARK: - Sync Operations
    
    /// Perform full sync: upload local data and download cloud data
    @MainActor
    func performFullSync(localArticles: [Article]) async -> Result<[Article], CloudError> {
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
            lastSyncDate = Date()
        }
        
        // 1. Upload local articles that don't exist in cloud
        for article in localArticles {
            let uploadResult = await uploadArticle(article)
            if case .failure(let error) = uploadResult {
                await MainActor.run {
                    syncError = "Upload failed: \(error.localizedDescription)"
                }
                return .failure(error)
            }
        }
        
        // 2. Download all articles from cloud
        let downloadResult = await downloadArticles()
        switch downloadResult {
        case .success(let cloudArticles):
            print("🔄 Sync completed: \(cloudArticles.count) articles synced")
            return .success(cloudArticles)
        case .failure(let error):
            await MainActor.run {
                syncError = "Download failed: \(error.localizedDescription)"
            }
            return .failure(error)
        }
    }
}

// MARK: - Cloud Error Types
enum CloudError: Error, LocalizedError {
    case notAuthenticated
    case uploadFailed(String)
    case downloadFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .updateFailed(let message):
            return "Update failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
}
