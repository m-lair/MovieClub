//
//  Clubs.test.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/6/24.
//

import Testing
import Firebase
import Foundation
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore
@testable import MovieClub

extension AppTests {
    
    @Suite struct ClubFunctionsTests {
        let createClub: Callable<MovieClub, MovieClub> = Functions.functions().httpsCallable("movieClubs-createMovieClub")
        
        @Test func createClub() async throws {
            let _ = try await setUp(userId: UUID())
            let club = MovieClub(name: "test\(UUID())", desc: "test-desc", ownerName: "test-user", timeInterval: 2, ownerId: "0001", isPublic: true, banner: Data(count: 10), bannerUrl: "no-image")

            let response = try await createClub(club)
            #expect(response.name == club.name)
            try await tearDown()
        }
        
    }
    
}
