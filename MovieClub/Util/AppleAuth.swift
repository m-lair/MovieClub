//
//  Apple.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/20/24.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import FirebaseFunctions

@MainActor
class AppleSignInManager: NSObject {
    
    private var currentNonce: String?
    private var data = DataManager()
    
    // Singleton instance (optional but useful)
    static let shared = AppleSignInManager()
    
    // Generate a random nonce to use with the sign-in request
    func startSignInWithAppleFlow() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }

    // Handle the completion of the Apple Sign-In flow
    func handleAuthorization(result: Result<ASAuthorization, Error>, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    completion(.failure(SignInError.invalidToken))
                    return
                }
                
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    completion(.failure(SignInError.serializationFailed))
                    return
                }
                
                // Get the fullName from the Apple ID credential, if available
                let fullName = appleIDCredential.fullName
                let displayName = [fullName?.givenName, fullName?.familyName].compactMap { $0 }.joined(separator: " ")
                
                // Create an OAuth credential with the ID token and nonce, and include the full name
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: fullName
                )
                
                // Sign in with Firebase
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if let error = error {
                        print("Error signing in with Apple: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    guard let authResult = authResult else {
                        completion(.failure(SignInError.unknownError))
                        return
                    }
                    if !displayName.isEmpty {
                        let changeRequest = authResult.user.createProfileChangeRequest()
                        changeRequest.displayName = displayName
                        changeRequest.commitChanges { error in
                            if let error = error {
                                print("Error updating user profile: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    Task {
                        try await self.data.createUser(email: authResult.user.email!, password: "", displayName: authResult.user.displayName ?? "")
                    }
                    completion(.success(authResult))
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }

    // Generate a random nonce string
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    // Hash the nonce using SHA256
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    // Custom error handling
    enum SignInError: Error {
        case invalidToken
        case serializationFailed
        case unknownError
    }
}

