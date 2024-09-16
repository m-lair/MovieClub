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
                let nonce = randomNonceString()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
            } onCompletion: { result in
                switch result {
                case .success(let authResults):
                    handleAuthorization(authResults)
                case .failure(let error):
                    errorMessage = error.localizedDescription
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
                    
                    try await data.createUser(email: email, password:password, displayName:name)
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
    @MainActor
    func handleAuthorization(_ authResults: ASAuthorization) {
        // Handle the authorization results
        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
           let nonce = randomNonceString()
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                // User is signed in to Firebase with Apple.
                print("Successfully signed in with Apple.")
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}





#Preview {
    SignUpView()
        .environment(DataManager())
}
