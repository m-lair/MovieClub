//
//  Memberships.test.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/16/24.
//


import Testing
import Firebase
import Foundation
import FirebaseFunctions
import FirebaseFirestore
import class FirebaseAuth.Auth
import class MovieClub.User
@testable import MovieClub

extension AppTests {
  
    @Suite struct MembershipsTests {
        let joinMovieClub: Callable<[String: String], String?> = Functions.functions().httpsCallable("memberships-joinMovieClub")
        let leaveMovieClub: Callable<[String: String], String?> = Functions.functions().httpsCallable("memberships-leaveMovieClub")
        let clubId: String = "test-club-\(UUID())"
        
        // MARK: - Join Club
        
        @Test func joinClub() async throws {
            if Auth.auth().currentUser == nil {
                let _ = try await setUp(userId: UUID())
            }
            let requestData = ["movieClubId": clubId,
                               "movieClubName": "test-club",
                               "image": "test-image.png",
                               "username": "test-username"]
            
            let response = try await joinMovieClub(requestData)
            #expect(response == nil)
        }
        
        // MARK: - Leave Club
        
        @Test func leaveClub() async throws {
            if Auth.auth().currentUser == nil {
                let _ = try await setUp(userId: UUID())
            }
            let requestData = ["movieClubId": clubId]
            
            let response = try await leaveMovieClub(requestData)
            #expect(response == nil)
        }
    }
}
