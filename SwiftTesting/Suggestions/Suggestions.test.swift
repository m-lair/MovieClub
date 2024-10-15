//
//  Suggestions.test.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/14/24.
//

import Foundation
import Testing
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions
@testable import MovieClub

extension AppTests {
    
    @Suite struct SuggestionsTests {
        let createSuggestion: Callable<Suggestion, String?> = Functions.functions().httpsCallable("suggestions-createMovieClubSuggestion")
        
        let deleteSuggestion: Callable<[String: String], String?> = Functions.functions().httpsCallable("suggestions-deleteUserMovieClubSuggestion")
        
        @Test func createSuggestion() async throws {
            if Auth.auth().currentUser == nil {
                let _ = try await setUp(userId: UUID())
            }
            let suggestion = Suggestion(title: "The Matrix", userImage: "image", username: "username", clubId: "test-club")
            
            let response = try await createSuggestion(suggestion)
            #expect(response == nil)
        }
        
        @Test func deleteSuggestion() async throws {
            if Auth.auth().currentUser == nil {
                let _ = try await setUp(userId: UUID())
            }
            
            let response = try await deleteSuggestion(["clubId" : "test-club"])
            #expect(response == nil)
        }
    }
}
