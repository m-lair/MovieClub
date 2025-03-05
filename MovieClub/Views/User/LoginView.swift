//
//  LoginView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/6/24.
//

import SwiftUI
import AuthenticationServices
import Observation
import FirebaseAuth

struct LoginView: View {
    
    @Environment(DataManager.self) private var data
    @Environment(\.dismiss) private var dismiss
    
    // State variables
    @State private var userEmail = ""
    @State private var userPwd = ""
    @State private var error: Error? = nil
    @State private var isLoading = false
    
    // Validation error states
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    
    private var isFormValid: Bool {
        return emailError == nil && 
               passwordError == nil && 
               !userEmail.isEmpty && 
               !userPwd.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Spacer()
                    Text("Movie Club")
                        .font(.title)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .padding(.bottom, 50)
                    
                    // Email field with validation
                    ValidatedTextField(
                        title: "Email",
                        text: $userEmail,
                        error: $emailError,
                        validate: UserValidationService.validateEmail,
                        icon: "envelope"
                    )
                    .padding(.horizontal, 50)
                    .padding(.bottom, 20)
                    
                    // Password field with validation
                    ValidatedTextField(
                        title: "Password",
                        text: $userPwd,
                        error: $passwordError,
                        validate: UserValidationService.validatePassword,
                        isSecure: true,
                        icon: "lock"
                    )
                    .padding(.horizontal, 50)
                    .padding(.bottom, 50)
                    
                    // Sign in button
                    PrimaryButton(
                        title: "Sign In",
                        action: {
                            Task {
                                await handleSignIn()
                            }
                        },
                        isDisabled: !isFormValid,
                        isLoading: isLoading
                    )
                    
                    Spacer()
                    
                    // Sign up link
                    NavigationLink {
                        SignUpView()
                            .navigationBarBackButtonHidden(true)
                    } label: {
                        HStack(spacing: 3) {
                            Text("Don't have an account?")
                            Text("Sign Up!")
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.blue)
                        .font(.body)
                    }
                }
                
                // Error banner that slides in from the top
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
    }
    
    func handleSignIn() async {
        // Validate fields first
        let emailValidation = UserValidationService.validateEmail(userEmail)
        let passwordValidation = UserValidationService.validatePassword(userPwd)
        
        // Update validation errors
        switch emailValidation {
        case .success: emailError = nil
        case .failure(let validationError): emailError = validationError.errorDescription
        }
        
        switch passwordValidation {
        case .success: passwordError = nil
        case .failure(let validationError): passwordError = validationError.errorDescription
        }
        
        // Don't proceed if validation failed
        if emailError != nil || passwordError != nil {
            return
        }
        
        // Show loading state
        isLoading = true
        
        do {
            try await data.signIn(email: userEmail, password: userPwd)
            // Success - dismiss will happen automatically since auth state changes
        } catch {
            // Show error with animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                self.error = error
            }
        }
        
        // Hide loading state
        isLoading = false
    }
}
