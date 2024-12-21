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
    
    func setUp() async throws {
        let uid = Int.random(in: 1...100)
        mockAuth = TestFirebaseAuth()
        mockFirestore = TestFirestore()
        mockFunctions = TestFunctions()
        mockUser = User(id: "\(uid)", email: "test\(uid)@example.com", name: "test-user-\(uid)")
        print(mockUser.name)
    }
    
    func tearDown() async throws {
        mockAuth = nil
        mockFirestore = nil
        mockFunctions = nil
        mockUser = nil
    }
}
