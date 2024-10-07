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
            let club = MovieClub(name: "test\(UUID())", ownerName: "test-user", timeInterval: 2, ownerId: "0001", isPublic: true)
            let response = try await createClub(club)
            #expect(response.name == club.name)
        }
        
        @Test func joinClub() async throws {
            //Join Club
        }
    }
    
}
