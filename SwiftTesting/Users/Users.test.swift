//
//  Users.test.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/6/24.
//

import Testing
import Firebase
import Foundation
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore
@testable import MovieClub

extension AppTests {
    
    
    @Suite struct UserFunctionsTests {
        let createUserWithEmail: Callable<[String: String], String> = Functions.functions().httpsCallable("users-createUserWithEmail")
        let createUserWithSignInProvider: Callable<[String: String], String> = Functions.functions().httpsCallable("users-createUserWithSignInProvider")
        let updateUser: Callable<String, String> = Functions.functions().httpsCallable("users-updateUser")
        
        let id = UUID()
        
        @Test func signUp() async throws {
            let userData = ["email": "test\(id)@test.com", "password": "123456", "name": "test\(id)"]
            let userId = try await createUserWithEmail(userData)
            #expect(userId != "")
        }
        
        @Test func signUpWithProvider() async throws {
            let providerData: [String: String] = [
                "signInProvider": "apple",
                "idToken": "sample-token",
                "email": "testuser@example.com",
                "name": "Test User"
            ]
            let userId = try await createUserWithSignInProvider(providerData)
            #expect(userId != "")
        }
        
        @Test func updateUser() async throws {
        }
    }
}
