//
//  SignUpView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/10/24.
//

import SwiftUI
import Observation
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import FirebaseFunctions

struct SignUpView: View {
    @Environment(DataManager.self) private var data
    @Environment(\.dismiss) var dismiss
    
    // State variables
    @State private var isLoading: Bool = false
    @State private var error: Error? = nil
    @State private var currentNonce: String? = nil
    
    // Form fields
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword = ""
    
    // Validation errors
    @State private var nameError: String? = nil
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var confirmPasswordError: String? = nil
    
    private var isFormValid: Bool {
        return nameError == nil && 
               emailError == nil && 
               passwordError == nil && 
               confirmPasswordError == nil &&
               !name.isEmpty &&
               !email.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 20)
                    
                    Text("Movie Club")
                        .font(.title)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .padding(.bottom, 30)
                    
                    // Name field
                    ValidatedTextField(
                        title: "Name",
                        text: $name,
                        error: $nameError,
                        validate: UserValidationService.validateName,
                        icon: "person"
                    )
                    .padding(.horizontal, 50)
                    
                    // Email field
                    ValidatedTextField(
                        title: "Email",
                        text: $email,
                        error: $emailError,
                        validate: UserValidationService.validateEmail,
                        icon: "envelope"
                    )
                    .padding(.horizontal, 50)
                    
                    // Password field
                    ValidatedTextField(
                        title: "Password",
                        text: $password,
                        error: $passwordError,
                        validate: UserValidationService.validatePassword,
                        isSecure: true,
                        icon: "lock"
                    )
                    .padding(.horizontal, 50)
                    
                    // Confirm password field
                    ValidatedTextField(
                        title: "Confirm Password",
                        text: $confirmPassword,
                        error: $confirmPasswordError,
                        validate: { pwd in 
                            UserValidationService.validatePasswordConfirmation(
                                password: password, 
                                confirmation: pwd
                            )
                        },
                        isSecure: true,
                        icon: "lock.shield"
                    )
                    .padding(.horizontal, 50)
                    .padding(.bottom, 20)
                    
                    // Password strength indicator
                    if !password.isEmpty {
                        PasswordStrengthView(password: password)
                            .padding(.horizontal, 50)
                            .padding(.bottom, 30)
                            .transition(.opacity)
                    }
                    
                    // Signup button
                    PrimaryButton(
                        title: "Sign Up",
                        action: {
                            Task {
                                await submit()
                            }
                        },
                        isDisabled: !isFormValid,
                        isLoading: isLoading
                    )
                    
                    Spacer()
                    
                    // Sign in link
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 3) {
                            Text("Have an Account?")
                            Text("Sign In!")
                                .bold()
                        }
                        .foregroundStyle(.blue)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.vertical)
            }
            
            // Error banner
            VStack {
                FormErrorBanner(error: error) {
                    withAnimation {
                        error = nil
                    }
                }
                .padding(.top)
                
                Spacer()
            }
        }
    }
    
    func submit() async {
        // Validate all fields
        let nameValidation = UserValidationService.validateName(name)
        let emailValidation = UserValidationService.validateEmail(email)
        let passwordValidation = UserValidationService.validatePassword(password)
        let confirmPasswordValidation = UserValidationService.validatePasswordConfirmation(
            password: password,
            confirmation: confirmPassword
        )
        
        // Update error states
        switch nameValidation {
        case .success: nameError = nil
        case .failure(let error): nameError = error.errorDescription
        }
        
        switch emailValidation {
        case .success: emailError = nil
        case .failure(let error): emailError = error.errorDescription
        }
        
        switch passwordValidation {
        case .success: passwordError = nil
        case .failure(let error): passwordError = error.errorDescription
        }
        
        switch confirmPasswordValidation {
        case .success: confirmPasswordError = nil
        case .failure(let error): confirmPasswordError = error.errorDescription
        }
        
        // Don't proceed if any validation failed
        if nameError != nil || emailError != nil || passwordError != nil || confirmPasswordError != nil {
            return
        }
        
        // Start loading
        isLoading = true
        
        do {
            _ = try await data.createUser(email: email, password: password, name: name)
            try await data.signIn(email: email, password: password)
            // Success - dismiss will happen automatically due to auth state change
        } catch {
            // Show error with animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                self.error = error
            }
        }
        
        // Hide loading
        isLoading = false
    }
}

// MARK: - Password Strength View
struct PasswordStrengthView: View {
    let password: String
    
    private var strength: PasswordStrength {
        passwordStrength(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Password Strength: \(strength.title)")
                .font(.caption)
                .foregroundColor(strength.color)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(strength.color)
                        .frame(width: CGFloat(strength.rawValue) / 4.0 * geometry.size.width, height: 4)
                }
            }
            .frame(height: 4)
            
            if strength == .weak {
                Text("Try adding uppercase letters, numbers or special characters.")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
    
    enum PasswordStrength: Int {
        case veryWeak = 1
        case weak = 2
        case medium = 3
        case strong = 4
        
        var title: String {
            switch self {
            case .veryWeak: return "Very Weak"
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
        
        var color: Color {
            switch self {
            case .veryWeak: return .red
            case .weak: return .orange
            case .medium: return .yellow
            case .strong: return .green
            }
        }
    }
    
    func passwordStrength(_ password: String) -> PasswordStrength {
        if password.count < 8 {
            return .veryWeak
        }
        
        var score = 0
        
        // Check for uppercase letters
        let uppercaseRegex = ".*[A-Z]+.*"
        if NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: password) {
            score += 1
        }
        
        // Check for numbers
        let numberRegex = ".*[0-9]+.*"
        if NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: password) {
            score += 1
        }
        
        // Check for special characters
        let specialCharRegex = ".*[!@#$%^&*()_\\-+=\\[\\]{}|:;\"'<>,.?/~`]+.*"
        if NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: password) {
            score += 1
        }
        
        // Check length
        if password.count >= 12 {
            score += 1
        }
        
        switch score {
        case 0: return .veryWeak
        case 1: return .weak
        case 2: return .medium
        case 3, 4: return .strong
        default: return .veryWeak
        }
    }
}
