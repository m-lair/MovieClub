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
import FirebaseFirestore
import class FirebaseAuth.Auth
import class MovieClub.User
@testable import MovieClub

extension AppTests {
    
    @Suite struct UserFunctionsTests {
        let createUserWithEmail: Callable<[String: String], String> = Functions.functions().httpsCallable("users-createUserWithEmail")
        let createUserWithSignInProvider: Callable<[String: String], String> = Functions.functions().httpsCallable("users-createUserWithSignInProvider")
        let updateUser: Callable<User, Bool?> = Functions.functions().httpsCallable("users-updateUser")
        
        
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
            let id = UUID()
            guard let auth = try await setUp(userId: id) else { return }
            print("auth: \(auth)")
            let userRef = Firestore.firestore().collection("users").document(auth)
            
            let user = User(email: "test\(id)@test.com", bio: "test-bio", name: "test\(id)", image: "test-image.png")
            try userRef.setData(from: user)
            
            user.name = "updated-name"
            user.bio = "updated-bio"
            user.image = "updated-image.png"

            let _ = try await updateUser(user)
            
           
            let result = try await userRef.getDocument().data(as: User.self)
            #expect(result.name == "updated-name")
            #expect(result.bio == "updated-bio")
            #expect(result.image == "updated-image.png")
            try await tearDown()
        }
    }
}
