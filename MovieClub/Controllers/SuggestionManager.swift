//
//  SuggestionManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/14/24.
//

import Foundation
import FirebaseFunctions

extension DataManager {
    
    // MARK: - Enums
    
    enum SuggestionError: Error {
        case movieAlreadySuggested
        case movieNotFound
        case networkError(Error)
        case custom(message: String)
        
    }
    
    struct SuggestionResponse: Codable {
        let success: Bool
        let message: String? // Optional in case you want to pass a message with the result
    }
    
    // MARK: Create Suggestion
    
    func createSuggestion(suggestion: Suggestion) async throws {
        let createSuggestion: Callable<Suggestion, SuggestionResponse> = functions.httpsCallable("suggestions-createMovieClubSuggestion")
        do {
            let result = try await createSuggestion(suggestion)
            if result.success {
                print("Suggestion created successfully")
            } else {
                print("Failed to create suggestion: \(result.message ?? "Unknown error")")
                throw SuggestionError.custom(message: result.message ?? "Unknown error")
            }
        } catch {
            print("Network error: \(error)")
            throw SuggestionError.networkError(error)
        }
    }
    
    // MARK: Delete Suggestion
    
    func deleteSuggestion(suggestion: Suggestion) async throws {
        let deleteSuggestion: Callable<Suggestion, SuggestionResponse> = functions.httpsCallable("suggestions-deleteMovieClubSuggestion")
        
        do {
          let result = try await deleteSuggestion(suggestion)
            if result.success {
                print("Suggestion deleted successfully")
            } else {
                print("Failed to delete suggestion: \(result.message ?? "Unknown error")")
                throw SuggestionError.custom(message: result.message ?? "Unknown error")
            }
        } catch {
            throw SuggestionError.networkError(error)
        }
    }
    
    // MARK: Fetch Suggestions
    
    func listenToSuggestions(clubId: String) {
        guard !clubId.isEmpty else {
            print("Invalid club ID")
            return
        }
        
        let suggestionsRef = movieClubCollection()
            .document(clubId)
            .collection("suggestions")
            .order(by: "createdAt", descending: true)
        
        // Remove existing listener if any
        suggestionsListener?.remove()
        
        suggestionsListener = suggestionsRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error listening to suggestions: \(error)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("No snapshot received")
                return
            }
            
            let suggestions = snapshot.documents.compactMap { document -> Suggestion? in
                do {
                    var suggestion = try document.data(as: Suggestion.self)
                    suggestion.id = document.documentID
                    return suggestion
                } catch {
                    print("Error decoding suggestion: \(error)")
                    return nil
                }
            }
            
            // Update suggestions on main thread
            Task { @MainActor in
                self.suggestions = suggestions
            }
        }
    }
    
    func fetchSuggestions(clubId: String) async throws -> [Suggestion] {
        guard !clubId.isEmpty else {
            throw NSError(domain: "Invalid club ID", code: -1)
        }
        
        let snapshot = try await movieClubCollection()
            .document(clubId)
            .collection("suggestions")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> Suggestion? in
            do {
                let suggestion = try document.data(as: Suggestion.self)
                suggestion.id = document.documentID
                return suggestion
            } catch {
                print("Error decoding suggestion: \(error)")
                return nil
            }
        }
    }
}
