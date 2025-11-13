import Foundation

class OpenAIService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        // Get API key from environment or plist
        // For security, never hardcode the API key
        self.apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
    }
    
    func sendMessage(_ message: String, articleContext: String? = nil) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.noAPIKey
        }
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = createSystemPrompt(with: articleContext)
        let requestBody = OpenAIRequest(
            model: "gpt-4",
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: message)
            ],
            maxTokens: 1000,
            temperature: 0.7
        )
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw OpenAIError.httpError(httpResponse.statusCode)
            }
            
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            return openAIResponse.choices.first?.message.content ?? "I'm sorry, I couldn't generate a response."
            
        } catch {
            throw OpenAIError.networkError(error)
        }
    }
    
    private func createSystemPrompt(with articleContext: String?) -> String {
        var prompt = """
        You are Clara/Clark, an intelligent AI assistant integrated into Clarify, a reading app. You help users understand, analyze, and engage with articles they're reading.
        
        Your capabilities include:
        - Summarizing articles clearly and concisely
        - Identifying key points and main arguments
        - Fact-checking claims when possible
        - Answering questions about article content
        - Providing additional context or explanations
        - Helping users think critically about what they read
        
        Always be helpful, accurate, and concise. If you're unsure about something, acknowledge the uncertainty.
        """
        
        if let context = articleContext, !context.isEmpty {
            prompt += "\n\nCurrent article context:\n\(context)"
        }
        
        return prompt
    }
}

// MARK: - Data Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

// MARK: - Error Handling

enum OpenAIError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not found. Please add your API key to the app configuration."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
