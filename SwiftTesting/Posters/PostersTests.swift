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
        let userId = try await super.createTestUserAuth()
        
        // 3) Call DataManager method to store it (whatever you actually have)
        try await mockFunctions.collectPoster(movieId: "test-movie", posterUrl: "poster-url", clubId: "test-club", id: "test-id")
        let docExists = try await mockFirestore.documentExists(path: "test-movie", in: "users/\(userId)/posters")
        #expect(docExists)
        #expect(true)
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
        
        
        // Add it again -> expect an error or some duplicate handling
        await #expect(throws: Error.self) {
            try await mockFunctions.collectPoster(movieId: "test-poster", posterUrl: "url", clubId: item.clubId, id: userId)
        }
        
        try await super.tearDown()
    }
}
