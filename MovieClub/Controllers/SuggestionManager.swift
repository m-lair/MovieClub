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
    
    func createSuggestion(suggestion: Suggestion) async throws -> String? {
        let createSuggestion: Callable<Suggestion, String?> = functions.httpsCallable("suggestions-createMovieClubSuggestion")
        do {
            let _ = try await createSuggestion(suggestion)
        } catch {
            throw SuggestionError.networkError(error)
        }
        print("Suggestion created")
        return "200"
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
    
    func listenToSuggestions(clubId: String) throws {
        guard
            let clubId = currentClub?.id
        else {
            throw ClubError.invalidData
        }
        
        let suggestionsRef = movieClubCollection()
            .document(clubId)
            .collection("suggestions")
            .order(by: "createdAt", descending: true)
        
        suggestionsListener?.remove()
    
        suggestionsListener = suggestionsRef.addSnapshotListener { [weak self] snapshot, error in
            
            guard let self else {
                print ("Unknown Error")
                return
            }
            
            guard let snapshot = snapshot else {
                print("Snapshot is nil")
                return
            }
            
            suggestions = snapshot.documents.compactMap { document in
                do{
                    return try document.data(as: Suggestion.self)
                } catch {
                    return nil
                }
                
            }
        }
        
    }

}
