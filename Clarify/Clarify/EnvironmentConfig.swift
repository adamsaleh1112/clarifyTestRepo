import Foundation

/// Configuration manager for environment variables and app settings
class EnvironmentConfig {
    static let shared = EnvironmentConfig()
    
    private init() {}
    
    /// OpenAI API Key from environment or bundle
    var openAIAPIKey: String {
        // First try to get from environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return envKey
        }
        
        // Fallback to reading from .env file in bundle
        if let envKey = readFromEnvFile() {
            return envKey
        }
        
        // Last resort: check Info.plist (for backwards compatibility)
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String {
            return plistKey
        }
        
        // Return empty string if no key found (should handle this gracefully in the app)
        print("⚠️ Warning: No OpenAI API key found. Please set OPENAI_API_KEY environment variable or create .env file.")
        return ""
    }
    
    /// Read API key from .env file
    private func readFromEnvFile() -> String? {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            // Try to read from project root (for development)
            let projectRoot = Bundle.main.bundlePath.replacingOccurrences(of: "/build/", with: "/")
            let envPath = projectRoot + "/.env"
            return readEnvFile(at: envPath)
        }
        
        return readEnvFile(at: path)
    }
    
    /// Helper to read and parse .env file
    private func readEnvFile(at path: String) -> String? {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("OPENAI_API_KEY=") {
                let key = String(trimmed.dropFirst("OPENAI_API_KEY=".count))
                return key.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
        }
        
        return nil
    }
    
    /// Validate that required configuration is available
    func validateConfiguration() -> Bool {
        let apiKey = openAIAPIKey
        return !apiKey.isEmpty && apiKey != "your_openai_api_key_here"
    }
    
    /// Get configuration status for debugging
    func getConfigurationStatus() -> String {
        let hasEnvVar = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] != nil
        let hasEnvFile = readFromEnvFile() != nil
        let hasPlistKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") != nil
        let isValid = validateConfiguration()
        
        return """
        Configuration Status:
        - Environment Variable: \(hasEnvVar ? "✅" : "❌")
        - .env File: \(hasEnvFile ? "✅" : "❌")
        - Info.plist: \(hasPlistKey ? "✅" : "❌")
        - Valid Configuration: \(isValid ? "✅" : "❌")
        """
    }
}
