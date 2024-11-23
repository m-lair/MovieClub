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
    
    @State private var currentNonce: String? = nil
    @State private var error: Error?
    
    private var btnDisabled: Bool {
        if (name.isEmpty ||
            email.isEmpty ||
            password.isEmpty ||
            confirmPassword != password ||
            error != nil) {
            return true
        } else {
            return false
        }
    }
    
    @State private var confirmPassword = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var bio: String = ""
    
    var body: some View {
        VStack {
            Spacer()
            Text("Movie Club")
                .font(.title)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .padding(.bottom, 50)
            
            
            SignInWithAppleButton(.signIn) { request in
                // Use the AppleSignInManager to set up the Apple sign-in request
                let nonce = AppleSignInManager.shared.startSignInWithAppleFlow()
                
                // Configure the request with scopes and nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = nonce
            } onCompletion: { result in
                // Handle the authorization result directly
                AppleSignInManager.shared.handleAuthorization(result: result) { authResult in
                    switch authResult {
                    case .success:
                        dismiss()
                    case .failure(let error):
                        self.error = error
                    }
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 45)
            .padding(.horizontal, 50)
            
            
            
            Divider()
            TextField("Name", text: $name)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 50)
                .padding(.bottom, 20)
            
            /* TextField("Bio", text: $bio)
             .padding()
             .background(Color.gray.opacity(0.1))
             .cornerRadius(8)
             .padding(.horizontal, 50)
             .padding(.bottom, 20) */
            
            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 50)
                .padding(.bottom, 20)
        
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 50)
                .padding(.bottom, 20)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 50)
                .padding(.bottom, 50)
            
            Button {
                Task {
                    
                    await submit()
                    
                }
            } label: {
                switch btnDisabled {
                case true:
                    Text("Signup")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.gray)
                        .cornerRadius(8)
                case false:
                    Text("Signup")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .disabled(btnDisabled)
            
            Spacer()
            HStack{
                Button{
                    dismiss()
                } label: {
                    Text("Have an Account?")
                    Text("Sign In!")
                    
                        .bold()
                }
                
            }
            .foregroundStyle(.blue)
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") {
                error = nil
            }
        } message: {
            if let error {
                Text(error.localizedDescription)
            }
        }
    }
    
    @MainActor func submit() async {
        if error == nil {
            do{
                let uid = try await data.createUser(email: email, password:password, displayName:name)
                try await data.signIn(email: email, password: password)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}
