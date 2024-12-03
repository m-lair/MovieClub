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
import FirebaseStorage
import class FirebaseAuth.Auth
import class MovieClub.User
@testable import MovieClub
    

@Suite("User Tests")
class UserTests: BaseTests {
    
    @Test("Create user with email successfully")
    func testCreateUserWithEmail_Success() async throws {
        try await super.setUp()
        let userId = try await mockFunctions.createUserWithEmail(email: mockUser.email, password: "123456", name: mockUser.name)
        
        #expect(!userId.isEmpty)
        let exists = try await mockFirestore.documentExists(path: userId, in: "users")
        #expect(exists)
        try await super.tearDown()
    }
    
    @Test("Create user with OAuth successfully", .disabled())
    func testCreateUserWithOAuth_Success() async throws {
        try await super.setUp()
        let provider = "Apple"
        let userId = try await mockFunctions.createUserWithOAuth(mockUser.email, signInProvider: provider)
        #expect(!userId.isEmpty)

    }
    
    @Test("Delete user successfully")
    func testDeleteUser_Success() async throws {
        try await super.setUp()
        // Make user
        let uid = try await mockFunctions.createUserWithEmail(email: mockUser.email, password: "123456", name: mockUser.name)
        let result = try await mockAuth.signIn(withEmail: mockUser.email, password: "123456")
        // Then delete them
        try #require(uid != nil && result.uid == uid)
        try await mockFunctions.deleteUser(uid)
        
        let exists = try await mockFirestore.documentExists(path: uid, in: "users")
        #expect(exists)
        try await super.tearDown()
    }
    
    @Test("Fail to create duplicate user")
    func testCreateUserWithEmail_DuplicateUser() async throws {
        try await super.setUp()
        // Create first user
        _ = try await mockFunctions.createUserWithEmail(email: mockUser.email, password: "123456", name: mockUser.name)
        
        // Attempt duplicate creation
        await #expect(throws: Error.self) {
            _ = try await mockFunctions.createUserWithEmail(email: mockUser.email, password: "123456", name: mockUser.name)
        }
        try await super.tearDown()
    }
}

