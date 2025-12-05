import SwiftUI

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    // TODO: Uncomment after adding Firebase SDK:
    // @StateObject private var userManager = FirebaseUserManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingSignUp = false
    @State private var isLoading = false
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State private var animationOffset: CGFloat = 0
    @State private var errorMessage = ""
    @State private var showError = false
    // @AppStorage("typography") private var typography: Typography = .serif
    
    var body: some View {
        ZStack {
            // Premium mesh gradient background
            meshGradientBackground
            
            VStack(spacing: 0) {
                Spacer()
                
                // Bypass button for testing
                HStack {
                    Spacer()
                    Button(action: {
                        isLoggedIn = true
                    }) {
                        Text("Skip Login")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorScheme == .dark ? Color(hex: "2C2928") : Color(hex: "F0ECEA"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(colorScheme == .dark ? Color(hex: "494544") : Color(hex: "B8B4B0"), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // App title
                VStack(spacing: 8) {
                    Text("Clarify")
                        .font(.system(size: 48, weight: .bold, design: .serif).width(.condensed))
                        .foregroundColor(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
                }
                .padding(.bottom, 60)
                
                // Login form
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(ClarifyTextFieldStyle())
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(ClarifyTextFieldStyle())
                    }
                    
                    // Error message
                    if showError {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                    
                    // Login button
                    Button(action: {
                        loginUser()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? Color(hex: "312D2B") : Color(hex: "ECE3DF")))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(colorScheme == .dark ? Color(hex: "312D2B") : Color(hex: "ECE3DF"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
                        )
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    .padding(.top, 10)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(colorScheme == .dark ? Color(hex: "8A827E") : Color(hex: "69605B"))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color(hex: "8A827E") : Color(hex: "69605B"))
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(colorScheme == .dark ? Color(hex: "8A827E") : Color(hex: "69605B"))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 20)
                    
                    // Create account button
                    Button(action: {
                        isShowingSignUp = true
                    }) {
                        Text("Create Account")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"), lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Button(action: {
                        // Handle forgot password
                    }) {
                        Text("Forgot Password?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .underline()
                    }
                    
                    Text("© 2024 Clarify")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView()
        }
    }
    
    private var meshGradientBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "201D1D") : Color(hex: "FEFCFB"),
                    colorScheme == .dark ? Color(hex: "2C2928") : Color(hex: "F0ECEA"),
                    colorScheme == .dark ? Color(hex: "201D1D").opacity(0.8) : Color(hex: "FEFCFB").opacity(0.8),
                    colorScheme == .dark ? Color(hex: "2C2928").opacity(0.6) : Color(hex: "F0ECEA").opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated overlay gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "3A3530").opacity(0.5) : Color(hex: "D4C4B8").opacity(0.8),
                    Color.clear,
                    colorScheme == .dark ? Color(hex: "1A1715").opacity(0.4) : Color(hex: "F8F5F2").opacity(0.4)
                ]),
                startPoint: UnitPoint(x: 0.5 + animationOffset * 0.3, y: 0.0 + animationOffset * 0.2),
                endPoint: UnitPoint(x: 1.0 - animationOffset * 0.3, y: 1.0 - animationOffset * 0.2)
            )
            .opacity(0.8)
            
            // Second animated overlay for more complexity
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    colorScheme == .dark ? Color(hex: "3A3530").opacity(0.3) : Color(hex: "D4C4B8").opacity(0.6),
                    Color.clear
                ]),
                startPoint: UnitPoint(x: 0.0 + animationOffset * 0.4, y: 0.5 + animationOffset * 0.3),
                endPoint: UnitPoint(x: 1.0 - animationOffset * 0.4, y: 0.5 - animationOffset * 0.3)
            )
            .opacity(0.6)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                animationOffset = 1.0
            }
        }
    }
    
    private func loginUser() {
        isLoading = true
        showError = false
        
        // Basic validation
        if email.isEmpty {
            errorMessage = "Email cannot be empty"
            showError = true
            isLoading = false
            return
        }
        
        if password.isEmpty {
            errorMessage = "Password cannot be empty"
            showError = true
            isLoading = false
            return
        }
        
        // Demo login - will be replaced with Firebase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            isLoggedIn = true
            print("Demo login successful with email: \(email)")
        }
        
        // TODO: Replace with Firebase authentication:
        // let result = await userManager.loginUser(email: email, password: password)
    }
}

struct ClarifyTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(hex: "2C2928") : Color(hex: "F0ECEA"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorScheme == .dark ? Color(hex: "494544") : Color(hex: "B8B4B0"), lineWidth: 1)
                    )
            )
            .foregroundColor(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
            .font(.system(size: 16, weight: .regular))
    }
}

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    // TODO: Uncomment after adding Firebase SDK:
    // @StateObject private var userManager = FirebaseUserManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var animationOffset: CGFloat = 0
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // Same animated gradient background
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "201D1D") : Color(hex: "FEFCFB"),
                        colorScheme == .dark ? Color(hex: "2C2928") : Color(hex: "F0ECEA"),
                        colorScheme == .dark ? Color(hex: "201D1D").opacity(0.8) : Color(hex: "FEFCFB").opacity(0.8),
                        colorScheme == .dark ? Color(hex: "2C2928").opacity(0.6) : Color(hex: "F0ECEA").opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Animated overlay gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "3A3530").opacity(0.5) : Color(hex: "D4C4B8").opacity(0.8),
                        Color.clear,
                        colorScheme == .dark ? Color(hex: "1A1715").opacity(0.4) : Color(hex: "F8F5F2").opacity(0.4)
                    ]),
                    startPoint: UnitPoint(x: 0.5 + animationOffset * 0.3, y: 0.0 + animationOffset * 0.2),
                    endPoint: UnitPoint(x: 1.0 - animationOffset * 0.3, y: 1.0 - animationOffset * 0.2)
                )
                .opacity(0.8)
                
                // Second animated overlay for more complexity
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        colorScheme == .dark ? Color(hex: "3A3530").opacity(0.3) : Color(hex: "D4C4B8").opacity(0.6),
                        Color.clear
                    ]),
                    startPoint: UnitPoint(x: 0.0 + animationOffset * 0.4, y: 0.5 + animationOffset * 0.3),
                    endPoint: UnitPoint(x: 1.0 - animationOffset * 0.4, y: 0.5 - animationOffset * 0.3)
                )
                .opacity(0.6)
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                    animationOffset = 1.0
                }
            }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(colorScheme == .dark ? Color(hex: "2C2928") : Color(hex: "F0ECEA")))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // Title
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold, design: .serif).width(.condensed))
                        .foregroundColor(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
                    
                    Text("Join the Clarify community")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundColor(colorScheme == .dark ? Color(hex: "8A827E") : Color(hex: "69605B"))
                }
                .padding(.bottom, 40)
                
                // Sign up form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(ClarifyTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
                        
                        SecureField("Create a password", text: $password)
                            .textFieldStyle(ClarifyTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
                        
                        SecureField("Confirm your password", text: $confirmPassword)
                            .textFieldStyle(ClarifyTextFieldStyle())
                    }
                    
                    // Error message
                    if showError {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                    
                    Button(action: {
                        registerUser()
                    }) {
                        Text("Create Account")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? Color(hex: "312D2B") : Color(hex: "ECE3DF"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(hex: "ECE3DF") : Color(hex: "312D2B"))
                            )
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
    
    private func registerUser() {
        isLoading = true
        showError = false
        
        // Basic validation
        if email.isEmpty {
            errorMessage = "Email cannot be empty"
            showError = true
            isLoading = false
            return
        }
        
        if password.isEmpty {
            errorMessage = "Password cannot be empty"
            showError = true
            isLoading = false
            return
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            showError = true
            isLoading = false
            return
        }
        
        // Demo registration - will be replaced with Firebase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            dismiss()
            print("Demo registration successful with email: \(email)")
        }
        
        // TODO: Replace with Firebase registration:
        // let result = await userManager.registerUser(...)
    }
}

#Preview {
    LoginView()
}
