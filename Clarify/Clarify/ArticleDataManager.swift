import Foundation

class ArticleDataManager: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let articlesKey = "SavedArticles"
    private let cloudManager = CloudArticleManager()
    
    @Published var articles: [Article] = []
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    init() {
        loadArticles()
    }
    
    // MARK: - Public Methods
    
    func addArticle(_ article: Article) {
        articles.insert(article, at: 0) // Add to beginning for newest-first order
        saveArticles()
        
        // Sync to Firebase in background
        Task {
            let result = await cloudManager.uploadArticle(article)
            if case .failure(let error) = result {
                await MainActor.run {
                    syncError = "Failed to sync article: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func removeArticle(_ article: Article) {
        articles.removeAll { $0.id == article.id }
        saveArticles()
        
        // Sync deletion to Firebase in background
        Task {
            let result = await cloudManager.deleteArticle(article.id.uuidString)
            if case .failure(let error) = result {
                await MainActor.run {
                    syncError = "Failed to delete article from cloud: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateArticle(_ article: Article) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index] = article
            saveArticles()
        }
    }
    
    func toggleFavorite(_ article: Article) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index].isFavorite.toggle()
            let updatedArticle = articles[index]
            saveArticles()
            
            // Sync favorite status to Firebase in background
            Task {
                let result = await cloudManager.toggleArticleFavorite(
                    updatedArticle.id.uuidString, 
                    isFavorite: updatedArticle.isFavorite
                )
                if case .failure(let error) = result {
                    await MainActor.run {
                        syncError = "Failed to sync favorite status: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    func updateReadingProgress(_ article: Article, progress: Double) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index].readingProgress = progress
            articles[index].lastReadDate = Date()
            let updatedArticle = articles[index]
            saveArticles()
            
            // Sync reading progress to Firebase in background
            Task {
                let result = await cloudManager.updateArticleProgress(
                    updatedArticle.id.uuidString,
                    progress: progress,
                    lastReadDate: updatedArticle.lastReadDate ?? Date()
                )
                if case .failure(let error) = result {
                    await MainActor.run {
                        syncError = "Failed to sync reading progress: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    func updateAISummary(_ article: Article, summary: String) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index].aiSummary = summary
            saveArticles()
        }
    }
    
    var favoriteArticles: [Article] {
        articles.filter { $0.isFavorite }
    }
    
    var recentlyReadArticles: [Article] {
        articles
            .filter { $0.readingProgress > 0.1 && $0.readingProgress < 1.0 }
            .sorted { ($0.lastReadDate ?? Date.distantPast) > ($1.lastReadDate ?? Date.distantPast) }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - Private Methods
    
    private func saveArticles() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(articles)
            userDefaults.set(data, forKey: articlesKey)
            print("✅ Saved \(articles.count) articles to UserDefaults")
        } catch {
            print("❌ Failed to save articles: \(error)")
        }
    }
    
    private func loadArticles() {
        guard let data = userDefaults.data(forKey: articlesKey) else {
            print("📄 No saved articles found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            articles = try decoder.decode([Article].self, from: data)
            print("✅ Loaded \(articles.count) articles from UserDefaults")
        } catch {
            print("❌ Failed to load articles: \(error)")
            // Reset to empty array if loading fails
            articles = []
        }
    }
    
    // MARK: - Utility Methods
    
    func clearAllArticles() {
        articles.removeAll()
        userDefaults.removeObject(forKey: articlesKey)
        syncError = nil
        lastSyncDate = nil
        print("🗑️ Cleared all articles")
    }
    
    // MARK: - Firebase Sync Methods
    
    /// Sync articles with Firebase - download cloud articles and merge with local
    @MainActor
    func syncWithFirebase() async {
        isSyncing = true
        syncError = nil
        
        let result = await cloudManager.performFullSync(localArticles: articles)
        
        switch result {
        case .success(let cloudArticles):
            // Replace local articles with cloud articles (cloud is source of truth)
            articles = cloudArticles
            saveArticles()
            lastSyncDate = Date()
            print("✅ Firebase sync completed: \(cloudArticles.count) articles")
            
        case .failure(let error):
            syncError = error.localizedDescription
            print("❌ Firebase sync failed: \(error.localizedDescription)")
        }
        
        isSyncing = false
    }
    
    /// Load articles on app launch - try Firebase first, fallback to local
    @MainActor
    func loadArticlesWithSync() async {
        // First load local articles immediately for UI
        loadArticles()
        
        // Then sync with Firebase in background
        await syncWithFirebase()
    }
    
    /// Manual sync trigger for pull-to-refresh
    @MainActor
    func refreshFromCloud() async {
        await syncWithFirebase()
    }
    
    func getArticleCount() -> Int {
        return articles.count
    }
    
    func exportArticles() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(articles)
        } catch {
            print("❌ Failed to export articles: \(error)")
            return nil
        }
    }
    
    func importArticles(from data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedArticles = try decoder.decode([Article].self, from: data)
            
            // Add imported articles to existing ones (avoiding duplicates by title)
            for article in importedArticles {
                if !articles.contains(where: { $0.title == article.title }) {
                    articles.append(article)
                }
            }
            
            saveArticles()
            print("✅ Imported \(importedArticles.count) articles")
            return true
        } catch {
            print("❌ Failed to import articles: \(error)")
            return false
        }
    }
}
