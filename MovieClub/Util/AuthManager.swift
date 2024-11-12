//
//  AuthManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

import Observation
import Foundation
import FirebaseAuth
import FirebaseFunctions
import AuthenticationServices

@Observable
class AuthManager {
    var authCurrentUser: FirebaseAuth.User?
    var authState: AuthStateDidChangeListenerHandle?

    init() {
        registerStateListener()
        self.authCurrentUser = Auth.auth().currentUser
        checkUserAuthentication()
    }

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
    
    
    private func checkUserAuthentication() {
        guard let user = Auth.auth().currentUser else {
            // No user is signed in
            print("No user is signed in.")
            return
        }
        
        user.getIDTokenForcingRefresh(true) { [weak self] (idToken, error) in
            if let error = error {
                // Token refresh failed, possibly because the user no longer exists
                print("Token refresh failed: \(error.localizedDescription)")
                self?.handleTokenRefreshError(error)
            } else {
                // Token is valid; user is authenticated
                print("User is authenticated with UID: \(user.uid)")
                self?.authCurrentUser = user
            }
        }
    }
    
    private func handleTokenRefreshError(_ error: Error) {
           // Sign out the user locally
           do {
               try Auth.auth().signOut()
               self.authCurrentUser = nil
               print("User has been signed out due to authentication error.")
           } catch {
               print("Error signing out: \(error.localizedDescription)")
           }
       }

    // MARK: - New User Creation

    func createUser(email: String, password: String, displayName: String) async throws -> String {
        do {
            try Auth.auth().signOut()
            let functions = Functions.functions()
            let result = try await functions.httpsCallable("users-createUserWithEmail").call([
                "email": email,
                "password": password,
                "name": displayName
            ])
            let uid = result.data as! String
            return uid
        } catch {
            print("Error \(error)")
            throw error
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.authCurrentUser = result.user
        } catch {
            print(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.authCurrentUser = nil
        } catch {
            print(error.localizedDescription)
        }
    }

    private func registerStateListener() {
        if authState == nil {
            authState = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
                if let user = user {
                    print("User is signed in: \(user.uid)")
                } else {
                    print("No user is signed in.")
                }
                self?.authCurrentUser = user
            }
        }
    }
}
