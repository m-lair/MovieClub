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
    var authCurrentUser: FirebaseAuth.User? = nil
    var authState: AuthStateDidChangeListenerHandle?
    
    var comments: [CommentNode] = []
    var commentsTask: Task<Void, Never>?
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
    var storage: Storage
    // MARK: - Content Listeners
    var commentsListener: ListenerRegistration?
    var suggestionsListener: ListenerRegistration?
    
    // MARK: - TMDB (The Movie Database) Conroller
    var tmdb: APIController
    
    // MARK: - Caches
    private var movieDataCache: [String: Movie] = [:]
    private let imageCache = NSCache<NSURL, UIImage>()
    
    init() {
        // Initialize API Key
        let omdbKey = Bundle.main.infoDictionary?["OMDB_API_KEY"] as? String ?? "invalid api key"
        db = Firestore.firestore()
        functions = Functions.functions()
        auth = Auth.auth()
        storage = Storage.storage()
        tmdb = APIController(apiKey: omdbKey)
        registerStateListener()
        Task {
            try await fetchUser()
        }
    }
    
    func loadImage(from url: URL) async throws -> UIImage {
        // 1. Return cached image if available
        let nsUrl = url as NSURL
        if let cached = imageCache.object(forKey: nsUrl) {
            return cached
        }
        
        // 2. Otherwise fetch from network
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let image = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        
        // 3. Cache it
        imageCache.setObject(image, forKey: nsUrl)
        return image
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
    
    // MARK: - Stock Images
    func fetchStockProfilePictureURLs() async -> [URL] {
        let stockImagesRef = storage.reference().child("stockimages")
        
        do {
            // List all items in the stockimages folder
            let result = try await stockImagesRef.listAll()
            
            // Get download URLs for all items
            let urls = try await withThrowingTaskGroup(of: URL?.self) { group in
                for item in result.items {
                    group.addTask {
                        try? await item.downloadURL()
                    }
                }
                
                var urlArray: [URL] = []
                for try await url in group {
                    if let url = url {
                        urlArray.append(url)
                    }
                }
                return urlArray
            }
            
            return urls
        } catch {
            print("Error fetching stock images: \(error)")
            return []
        }
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

    func refreshUserProfile() async {
        if let userId = currentUser?.id {
            if let updatedUser = try? await fetchProfile(id: userId) {
                await MainActor.run {
                    self.currentUser = updatedUser
                }
            }
        }
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
                return "Could not load OMDB API key from configuration"
            case .firestoreError(let error):
                return "Firestore error: \(error.localizedDescription)"
            case .userNotFound:
                return "User not found"
            }
        }
    }
}

