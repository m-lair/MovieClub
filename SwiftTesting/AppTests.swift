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

public func setUp(userId: UUID? = nil, clubId: UUID? = nil) async throws  -> String? {
    if let userId {
        let result = try await Auth.auth().createUser(withEmail: "test\(userId)@test.com", password: "123456")
        return result.user.uid
    }
    if let clubId {
        let db = Firestore.firestore()
        try await db.collection("movieclubs").document("\(clubId)").setData(["name": "testClub\(clubId)", "clubId": "testClub\(clubId)"])
    }
    return ""
}

public func tearDown() async throws {
    try Auth.auth().signOut()
}
