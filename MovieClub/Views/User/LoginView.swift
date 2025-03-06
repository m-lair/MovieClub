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
                    HStack {
                        Image(systemName: "lock")
                            .foregroundStyle(.gray)
                        SecureField("Password", text: $userPwd)
                           
                            
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(error == nil ? Color.clear : Color.red, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 50)
                    .padding(.bottom, 20)
                    // Sign in button
                    PrimaryButton(
                        title: "Sign In",
                        action: {
                            // Fix: Use a non-async wrapper for the button action
                            isLoading = true
                            // Store a reference to the task to avoid compiler warnings
                            let _ = Task { @MainActor in
                                do {
                                    try await handleSignIn()
                                } catch {
                                    // Handle any errors from sign-in process
                                    self.error = error
                                }
                                isLoading = false
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
    
    func handleSignIn() async throws {
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
        case .failure(let validationError): passwordError = nil
        }
        
        // Don't proceed if validation failed
        if emailError != nil || passwordError != nil {
            throw NSError(domain: "Login", code: 400, userInfo: [NSLocalizedDescriptionKey: "Validation failed"])
        }
        
        // Sign in - this will throw if it fails
        try await data.signIn(email: userEmail, password: userPwd)
        // Success - dismiss will happen automatically since auth state changes
    }
}
