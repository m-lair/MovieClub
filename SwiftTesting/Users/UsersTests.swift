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
    
    let testPassword = "123456"
    
    @Test("Create user with email successfully")
    func testCreateUserWithEmail_Success() async throws {
        try await super.setUp()
        let uid = UUID().uuidString
        let user = User(email: "test\(uid)@example.com", name: "createUserWithEmail\(uid)")
        let userId = try await mockFunctions.createUserWithEmail(email: user.email, password: testPassword, name: user.name)
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
        
        // Create User
        let uid = UUID().uuidString
        let userId = try await mockFunctions.createUserWithEmail(email: mockUser.email, password: testPassword, name: mockUser.name)
        let user = try await mockAuth.signIn(withEmail: mockUser.email, password: testPassword)
        mockAuth.currentUser = user
        
        // Delete Them
        try await mockFunctions.deleteUser(userId)
        let exists = try await mockFirestore.documentExists(path: userId, in: "users")
       
        let document = try await mockFirestore.document(userId, in: "users")
        #expect(exists)
        #expect(document?["name"] as! String == "[deleted user]")
        try await super.tearDown()
    }
    
    @Test("Fail to create duplicate user")
    func testCreateUserWithEmail_DuplicateUser() async throws {
        try await super.setUp()
        // Create first user
        _ = try await mockFunctions.createUserWithEmail(email: mockUser.email, password: testPassword, name: mockUser.name)
        
        // Attempt duplicate creation
        await #expect(throws: Error.self) {
            _ = try await mockFunctions.createUserWithEmail(email: mockUser.email, password: testPassword, name: mockUser.name)
        }
        try await super.tearDown()
    }
    
    @Test("Update User")
    func testUpdateUserName() async throws {
        try await super.setUp()
        // create user
        let userId = try await mockFunctions.createUserWithEmail(email: mockUser.email, password: testPassword, name: mockUser.email)
        // sign into auth
        mockAuth.currentUser = try await mockAuth.signIn(withEmail: mockUser.email, password: testPassword)
        // update user
        // currently this function only updates bio, name, and image
        try await mockFunctions.updateUser(userId: userId, email: "newemail@example.com", displayName: "New Name")
        
        let document = try await mockFirestore.document(userId, in: "users")
        #expect(document?["name"] as! String == "New Name")
        
        try await super.tearDown()
    }
}

