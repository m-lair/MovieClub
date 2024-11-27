//
//  AuthManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

import Observation
import Foundation
import FirebaseAuth

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
    
    // MARK: Validate Current User Token
    
    func checkUserAuthentication() async {
        guard let user = auth.currentUser else {
            // Do Nothing Auth State is nil
            authState = nil
            authCurrentUser = nil
            return
        }
        
        user.getIDTokenForcingRefresh(true) { (idToken, error) in
            if let error = error {
                // Token refresh failed, possibly because the user no longer exists
                print("Token refresh failed: \(error.localizedDescription)")
                self.handleTokenRefreshError(error)
            } else {
                // Token is valid; user is authenticated
                print("User is authenticated with UID: \(user.uid)")
                self.authCurrentUser = user
            }
        }
        
        do {
            currentUser = try await fetchUserDocument(uid: user.uid)
        } catch {
            print("Error fetching user document: \(error.localizedDescription)")
        }
    }
    
    private func handleTokenRefreshError(_ error: Error) {
           // Sign out the user locally
           do {
               try auth.signOut()
               self.authCurrentUser = nil
               print("User has been signed out due to authentication error.")
           } catch {
               print("Error signing out: \(error.localizedDescription)")
           }
       }

    // MARK: - New User Creation

    func createUser(email: String, password: String, displayName: String) async throws -> String {
        do {
            try auth.signOut()
            let result = try await functions.httpsCallable("users-createUserWithEmail").call([
                "email": email,
                "password": password
            ])
            let uid = result.data as! String
            return uid
        } catch {
            print("Error \(error)")
            throw error
        }
    }
    
    // MARK: - Fetch User Document

    func fetchUserDocument(uid: String) async throws -> User {
        let userRef = db.collection("users").document(uid)
        let user = try await userRef.getDocument(as: User.self)
        return user
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            self.authCurrentUser = result.user
            registerStateListener()
            try await fetchUser()
        } catch {
            print(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try auth.signOut()
            self.authState = nil
        } catch {
            print(error.localizedDescription)
        }
    }

    func registerStateListener() {
        authState = auth.addStateDidChangeListener { (auth, user) in
            // What is current firebase user auth state
            if let user = user {
                self.authCurrentUser = user
            } else {
                self.authCurrentUser = nil
            }
        }
    }
}
