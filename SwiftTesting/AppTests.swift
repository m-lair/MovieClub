//
//  MovieClubTests.swift
//  MovieClubTests
//
//  Created by Marcus Lair on 9/28/24.
//
import Testing
import Firebase
import Foundation
import FirebaseFunctions
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import class MovieClub.User
@testable import MovieClub

/// Base test class that provides common setup and teardown functionality
class BaseTests {
    // Shared test dependencies
    var datamanager: DataManager!
    var mockAuth: AuthService!
    var mockFirestore: DatastoreService!
    var mockFunctions: FunctionsService!
    var mockUser: User!
    
    init() async throws {
        // Only configure Firebase if it hasn't been configured yet
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    func setUp() async throws {
        let uid = Int.random(in: 1...100)
        mockAuth = TestFirebaseAuth()
        mockFirestore = TestFirestore()
        mockFunctions = TestFunctions()
        mockUser = User(id: "", email: "test\(uid)@example.com", name: "test-user-\(uid)")
        
    }
    
    func tearDown() async throws {
        mockFirestore = nil
        mockFunctions = nil
        mockUser = nil
    }
    
    func createTestUserAuth() async throws -> String {
        _ = try await mockAuth.createUser(withEmail: mockUser.email, password: "123456")
        mockAuth.currentUser = try await mockAuth.signIn(withEmail: mockUser.email, password: "123456")
       return mockAuth.currentUser!.uid
    }
}
