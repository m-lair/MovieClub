//
//  AuthManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

import Foundation
import FirebaseAuth
import FirebaseFunctions

extension DataManager {
    
    // MARK: - Enums
    enum AuthError: Error {
        case invalidEmail
        case invalidPassword
        case invalidDisplayName
        case invalidUser
        case invalidToken
        case invalidRefreshToken
        case invalidTokenExpiration
        case invalidTokenSignature
        case invalidTokenIssuer
    }
    
    // MARK: - New User Creation
    
    func createUser(email: String, password: String, displayName: String) async throws -> String {
        do {
            let functions = Functions.functions()
            let result = try await functions.httpsCallable("createUserWithEmail").call([
                "email": email,
                "password": password,
                "displayName": displayName
            ])
            guard let data = result.data as? [String: Any],
                  let uid = data["uid"] as? String else {
                throw NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
            }
            return uid
        } catch {
            throw error
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        print("Signing in")
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            print("Signed in user \(result.user)")
            try await fetchUser()
        } catch {
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            print(error.localizedDescription)
        }
    }
}

