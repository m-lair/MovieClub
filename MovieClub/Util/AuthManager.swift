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
    
    // MARK: - Update User
    
    /*func updateUser(displayName: String) async throws {
        guard let user = auth?.currentUser else {
            throw AuthError.invalidUser
        }
        do {
            let functions = Functions.functions()
            let result = try await functions.httpsCallable("users-updateUser").call([
                "id": currentUser.id,
                "name": currentUser.name,
                "email": currentUser.email,
                "bio": currentUser.bio ?? "",
            ])
            print("Updated user \(result.data)")
        } catch {
            throw error
        }
    }*/
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.authCurrentUser = result.user
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func registerStateListener() {
        if authState == nil {
            authState = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
                self?.authCurrentUser = user
            }
        }
    }
    
   /* private var accessGroup: String {
        get {
            let info = KeyChainAccessGroupHelper.getAccessGroupInfo()
            let prefix = info?.prefix ?? "unknown"
            return prefix + "." + (Bundle.main.bundleIdentifier ?? "unknown")
        }
    }
    
    private func setupKeychainSharing() {
        do {
            let auth = Auth.auth()
            auth.shareAuthStateAcrossDevices = true
            try auth.useUserAccessGroup(accessGroup)
        }
        catch let error as NSError {
            print("Error changing user access group: %@", error)
        }
    }*/
}



