//
//  DataManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import FirebaseFirestore
import UIKit
import FirebaseStorage
import Observation
import SwiftUI
import FirebaseMessaging
import FirebaseFunctions


@Observable @MainActor
class DataManager: Identifiable {
    // MARK: - API Key
    var apiKey: String
    
    var comments: [CommentNode] = []
    var suggestions: [Suggestion] = []
    var movies: [Movie] = []
    
    // MARK: - User Data
    var currentUser: User?
    var userClubs: [MovieClub] = []
    var currentClub: MovieClub?
    var currentCollection: [CollectionItem] = []
    
    // MARK: - Computed Properties
    var clubId: String {
        currentClub?.id ?? ""
    }

    var movieId: String {
        currentClub?.movies.first?.id ?? ""
    }
    
    
    // MARK: - Firebase References
    var db: Firestore
    var functions: Functions
    
    // MARK: - Cleanup
    var commentsListener: ListenerRegistration?
    var suggestionsListener: ListenerRegistration?
    
    init() throws {
        // Initialize API Key
        guard let filePath = Bundle.main.path(forResource: "TMDB-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let key = plist.object(forKey: "KEY") as? String else {
            throw DataError.invalidAPIKey
        }
        db = Firestore.firestore()
        functions = Functions.functions()
        apiKey = key
    }
    // MARK: - Collection References
    
    func movieClubCollection() -> CollectionReference {
        return db.collection("movieclubs")
    }
    
    func usersCollection() -> CollectionReference {
        return db.collection("users")
    }
}

    // MARK: - Error Handling
extension DataManager {
    enum DataError: LocalizedError {
        case invalidAPIKey
        case firestoreError(Error)
        case userNotFound
        
        var errorDescription: String? {
            switch self {
            case .invalidAPIKey:
                return "Could not load TMDB API key from configuration"
            case .firestoreError(let error):
                return "Firestore error: \(error.localizedDescription)"
            case .userNotFound:
                return "User not found"
            }
        }
    }
}

