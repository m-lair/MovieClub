//
//  PostersTests.swift
//  MovieClub
//
//  Created by Marcus Lair on 1/11/25.
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
        
        let item = CollectionItem(
            movieId: "test-movie",
            imdbId: "tt8765432",
            clubId: "anotherClubId",
            clubName: "Another Club",
            colorStr: "red",
            posterUrl: "poster-url"
        )
        
        let posterId = try await mockFunctions.collectPoster(poster: item)
        let docExists = try await mockFirestore.documentExists(path: "\(posterId)", in: "users/\(userId)/posters")
        #expect(docExists)
        try await super.tearDown()
    }
    
    @Test("Fail to add a duplicate poster")
    func testAddPoster_Fail() async throws {
        try await super.setUp()
        let userId = try await super.createTestUserAuth()
        
        // define the item (poster)
        let item = CollectionItem(
            movieId: "test-movie",
            imdbId: "tt8765432",
            clubId: "anotherClubId",
            clubName: "Another Club",
            colorStr: "red",
            posterUrl: "poster-url"
        )
        // add poster once
        let posterId = try await mockFunctions.collectPoster(poster: item)
        
        // attempt to add same poster again
        await #expect(throws: Error.self) {
            try await mockFunctions.collectPoster(poster: item)
        }
        
        try await super.tearDown()
    }
}
