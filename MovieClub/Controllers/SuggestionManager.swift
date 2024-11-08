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
    }
    
    // MARK: Create Suggestion
    
    func createSuggestion(suggestion: Suggestion) async throws {
        let createSuggestion: Callable<Suggestion, String?> = functions.httpsCallable("suggestions-createMovieClubSuggestion")
        do {
            let _ = try await createSuggestion(suggestion)
        } catch {
            print("error \(error)")
            throw SuggestionError.networkError(error)
        }
        print("Suggestion created")
        
    }
    
    // MARK: Delete Suggestion
    
    func deleteSuggestion(clubId: String) async throws -> String? {
        let deleteSuggestion: Callable<String, String?> = functions.httpsCallable("suggestions-deleteUserMovieClubSuggestion")
        do {
            let _ = try await deleteSuggestion(clubId)
        } catch {
            throw SuggestionError.networkError(error)
        }
        return "200"
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
