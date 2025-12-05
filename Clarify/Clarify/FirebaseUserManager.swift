import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Firebase User Model
struct FirebaseUser: Identifiable, Codable {
    let id: String
    let email: String
    let displayName: String?
    let createdAt: Date
    
    init(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.displayName = firebaseUser.displayName
        self.createdAt = firebaseUser.metadata.creationDate ?? Date()
    }
    
    init(id: String, email: String, displayName: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
    }
}

// MARK: - Firebase User Manager
class FirebaseUserManager: ObservableObject {
    static let shared = FirebaseUserManager()
    
    @Published var currentUser: FirebaseUser?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {
        // Listen for authentication state changes
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.currentUser = FirebaseUser(from: user)
                    self?.isLoggedIn = true
                } else {
                    self?.currentUser = nil
                    self?.isLoggedIn = false
                }
            }
        }
    }
    
    // MARK: - User Registration
    @MainActor
    func registerUser(email: String, password: String, confirmPassword: String, displayName: String? = nil) async -> FirebaseAuthResult {
        // Validate input
        guard !email.isEmpty else {
            return .failure(.invalidEmail("Email cannot be empty"))
        }
        
        guard isValidEmail(email) else {
            return .failure(.invalidEmail("Please enter a valid email address"))
        }
        
        guard !password.isEmpty else {
            return .failure(.invalidPassword("Password cannot be empty"))
        }
        
        guard isValidPassword(password) else {
            return .failure(.invalidPassword("Password must be at least 8 characters and contain both letters and numbers"))
        }
        
        guard password == confirmPassword else {
            return .failure(.invalidPassword("Passwords do not match"))
        }
        
        isLoading = true
        
        do {
            // Create user with Firebase Auth
            let authResult = try await auth.createUser(withEmail: email, password: password)
            
            // Update display name if provided
            if let displayName = displayName {
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }
            
            // Store additional user data in Firestore
            let userData: [String: Any] = [
                "email": email,
                "displayName": displayName ?? "",
                "createdAt": Timestamp()
            ]
            
            try await db.collection("users").document(authResult.user.uid).setData(userData)
            
            let firebaseUser = FirebaseUser(from: authResult.user)
            
            isLoading = false
            return .success(firebaseUser)
            
        } catch {
            isLoading = false
            return .failure(.registrationFailed(error.localizedDescription))
        }
    }
    
    // MARK: - User Login
    @MainActor
    func loginUser(email: String, password: String) async -> FirebaseAuthResult {
        // Validate input
        guard !email.isEmpty else {
            return .failure(.invalidEmail("Email cannot be empty"))
        }
        
        guard !password.isEmpty else {
            return .failure(.invalidPassword("Password cannot be empty"))
        }
        
        isLoading = true
        
        do {
            let authResult = try await auth.signIn(withEmail: email, password: password)
            let firebaseUser = FirebaseUser(from: authResult.user)
            
            isLoading = false
            return .success(firebaseUser)
            
        } catch {
            isLoading = false
            
            // Handle specific Firebase Auth errors
            if let authError = error as NSError? {
                switch AuthErrorCode(rawValue: authError.code) {
                case .userNotFound:
                    return .failure(.invalidCredentials("No account found with this email address"))
                case .wrongPassword:
                    return .failure(.invalidCredentials("Incorrect password"))
                case .invalidEmail:
                    return .failure(.invalidEmail("Invalid email address"))
                case .userDisabled:
                    return .failure(.invalidCredentials("This account has been disabled"))
                default:
                    return .failure(.invalidCredentials(error.localizedDescription))
                }
            }
            
            return .failure(.invalidCredentials(error.localizedDescription))
        }
    }
    
    // MARK: - User Session Management
    @MainActor
    func logout() async {
        do {
            try auth.signOut()
            // State will be updated automatically by the auth state listener
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Password Reset
    @MainActor
    func resetPassword(email: String) async -> FirebaseAuthResult {
        guard !email.isEmpty else {
            return .failure(.invalidEmail("Email cannot be empty"))
        }
        
        guard isValidEmail(email) else {
            return .failure(.invalidEmail("Please enter a valid email address"))
        }
        
        do {
            try await auth.sendPasswordReset(withEmail: email)
            return .success(nil)
        } catch {
            return .failure(.invalidEmail("Failed to send password reset email: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Validation Helpers
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters, contains letter and number
        return password.count >= 8 && 
               password.rangeOfCharacter(from: .letters) != nil &&
               password.rangeOfCharacter(from: .decimalDigits) != nil
    }
}

// MARK: - Firebase Auth Result Types
enum FirebaseAuthResult {
    case success(FirebaseUser?)
    case failure(FirebaseAuthError)
}

enum FirebaseAuthError {
    case invalidEmail(String)
    case invalidPassword(String)
    case invalidCredentials(String)
    case registrationFailed(String)
    
    var message: String {
        switch self {
        case .invalidEmail(let message),
             .invalidPassword(let message),
             .invalidCredentials(let message),
             .registrationFailed(let message):
            return message
        }
    }
}
