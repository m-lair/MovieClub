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
    @State private var emailExists: Bool = false
    @State private var currentNonce: String? = nil
    @FocusState private var emailFieldFocused: Bool
    @State private var errorMessage: String = ""
    @State private var labelhidden = 0.0
    private var btnDisabled: Bool {
        if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword != password || emailExists) {
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
                        // Show error message
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 45)
            .padding(.horizontal, 50)
            
            
            
            Divider()
            Text("Email already exists.")
                .foregroundColor(.red)
                .opacity(labelhidden)
            
            
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
                .focused($emailFieldFocused)
                .onChange(of: emailFieldFocused) {
                    let _ = print("focus changed")
                    checkEmail()
                }
            
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
                    //check if user exists first
                    _ = try await data.createUser(email: email, password:password, displayName:name)
                    try await data.signIn(email: email, password: password)
                    dismiss()
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
        .padding()
    }
    
    @MainActor
    func checkEmail(){
        data.usersCollection().whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                emailExists = true
                labelhidden = 100.0
            } else {
                if let snapshot = querySnapshot, !snapshot.isEmpty {
                    emailExists = true
                    labelhidden = 100.0
                } else {
                    emailExists = false
                    labelhidden = 0.0
                }
            }
        }
    }
}





#Preview {
    SignUpView()
        .environment(DataManager())
}
