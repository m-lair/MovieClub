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
        let joinMovieClub: Callable<[String: String], String?> = Functions.functions().httpsCallable("users-joinMovieClub")
        
        let id = UUID()
        
        @Test func signUp() async throws {
            let userData = ["email": "test\(id)@test.com", "password": "123456", "name": "test\(id)"]
            let userId = try await createUserWithEmail(userData)
            #expect(userId != "")
        }
        
        @Test func signUpWithProvider() async throws {
            let id = UUID()
            let providerData: [String: String] = [
                "signInProvider": "apple",
                "idToken": "sample-token",
                "email": "testuser\(id)@example.com",
                "name": "Test User \(id)"
            ]
            let userId = try await createUserWithSignInProvider(providerData)
            #expect(userId != "")
        }
        
        @Test func updateUser() async throws {
        }
        
        @Test func joinClub() async throws {
            try await setUp(userId: UUID())
            let requestData = ["movieClubId": "\(UUID())", "movieClubName": "test-club", "image": "test-image.png", "username": "test-username"]
            let response = try await joinMovieClub(requestData)
            if let response {
                #expect(response != "")
            }
        }
    }
}
