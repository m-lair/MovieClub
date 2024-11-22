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


@Observable
class DataManager: Identifiable {
    
    // MARK: Auth Items
    var authCurrentUser: FirebaseAuth.User?
    var authState: AuthStateDidChangeListenerHandle?
    
    // MARK: - API Key
    var omdbKey: String
    
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
    var auth: Auth
    
    // MARK: - Content Listeners
    var commentsListener: ListenerRegistration?
    var suggestionsListener: ListenerRegistration?
    
    init() {
        // Initialize API Key
        let key = ProcessInfo.processInfo.environment["OMDB_API_KEY"]
        db = Firestore.firestore()
        functions = Functions.functions()
        auth = Auth.auth()
        omdbKey = key ?? "invalid key"
        registerStateListener()
    }
    
    // MARK: - Collection References
    
    func movieClubCollection() -> CollectionReference {
        return db.collection("movieclubs")
    }
    
    func usersCollection() -> CollectionReference {
        return db.collection("users")
    }
    
    func updateUser(with user: User) {
        self.currentUser = user
    }
    
    // MARK: Cleanup

    func removeStateListener() {
        if let authState = authState {
            auth.removeStateDidChangeListener(authState)
        }
    }
    
    func removeCommentsListener() {
        commentsListener?.remove()
    }
    
    func removeSuggestionsListener() {
        suggestionsListener?.remove()
    }

    deinit {
        removeStateListener()
        removeCommentsListener()
        removeSuggestionsListener()
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

