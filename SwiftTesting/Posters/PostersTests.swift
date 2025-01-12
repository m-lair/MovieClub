//
//  PostersTests.swift
//  MovieClub
//
//  Created by Marcus Lair on 1/11/25.
//


//
//  Posters.test.swift
//  MovieClubTests
//
//  Created by Marcus Lair on 1/12/25.
//

import Testing
import class MovieClub.DataManager
@testable import MovieClub

@Suite("Posters Tests")
class PostersTests: BaseTests {
    
    @Test("Add a poster to user’s collection successfully")
    func testAddPoster_Success() async throws {
        try await super.setUp()
        
        // 1) Suppose we create or fetch an existing user (mockUser)
        let userId = mockUser.id ?? ""
        #expect(!userId.isEmpty)
        
        // 2) Build a CollectionItem (poster)
        let item = CollectionItem(
            imdbId: "tt1234567",
            clubId: "someClubId",
            clubName: "Some Club",
            colorStr: "blue"
        )
        
        // 3) Call DataManager method to store it (whatever you actually have)
        try await mockFunctions.collectPoster(movieId: "test-movie", posterUrl: "nil")
        
        // 4) Confirm the doc exists in Firestore at users/{userId}/posters/{posterId}
        let docExists = try await mockFirestore.documentExists(path: item.id ?? "", in: "users/\(userId)/posters")
        #expect(docExists)
        
        try await super.tearDown()
    }
    
    @Test("Fail to add a duplicate poster")
    func testAddPoster_Fail() async throws {
        try await super.setUp()
        
        let userId = mockUser.id ?? ""
        let item = CollectionItem(
            imdbId: "tt8765432",
            clubId: "anotherClubId",
            clubName: "Another Club",
            colorStr: "red"
        )
        
        // Add it once
        try await mockFunctions.collectPoster(movieId: "movieId", posterUrl: "url")
        
        // Add it again -> expect an error or some duplicate handling
        await #expect(throws: Error.self) {
            try await mockFunctions.collectPoster(movieId: "movieId", posterUrl: "url")
        }
        
        try await super.tearDown()
    }
}
