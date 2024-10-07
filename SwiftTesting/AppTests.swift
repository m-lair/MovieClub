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
import FirebaseAuth
import FirebaseFirestore
@testable import MovieClub



@Suite struct AppTests {

    
}

public func setUp() async throws {
    let user = try await Auth.auth().createUser(withEmail: "test\(UUID())@test.com", password: "123456")
}

public func tearDown() async throws {
    
}
