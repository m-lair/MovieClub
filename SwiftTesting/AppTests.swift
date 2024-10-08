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



@Suite struct AppTests { }

public func setUp(userId: UUID? = nil, clubId: UUID? = nil) async throws {
    if let userId {
        try await Auth.auth().createUser(withEmail: "test\(userId)@test.com", password: "123456")
    }
    if let clubId {
        let db = Firestore.firestore()
        try await db.collection("movieclubs").document("\(clubId)").setData(["name": "testClub\(clubId)", "clubId": "testClub\(clubId)"])
    }
}

public func tearDown() async throws {
    try Auth.auth().signOut()
}
