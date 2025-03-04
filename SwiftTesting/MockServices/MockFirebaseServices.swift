//
//  MockFirebaseAuth.swift
//  MovieClub
//
//  Created by Marcus Lair on 11/24/24.
//

import Testing
import Firebase
import Foundation
import FirebaseFunctions
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import class MovieClub.User
import class MovieClub.Comment
import class MovieClub.MovieClub
@testable import MovieClub

// MARK: - Live Firebase Implementations
actor TestFirebaseAuth: @preconcurrency AuthService {
    private let auth: Auth
    
    var currentUser: FirebaseAuth.User?
    
    init(auth: Auth = Auth.auth()) {
        self.auth = auth
    }
    
    func signIn(withEmail email: String, password: String) async throws -> FirebaseAuth.User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return result.user
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func createUser(withEmail email: String, password: String) async throws -> FirebaseAuth.User {
        let result = try await auth.createUser(withEmail: email, password: password)
        return result.user
    }
}

actor TestFirestore: DatastoreService {
    private let db: Firestore
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    private func getCollectionReference(_ collection: String) -> CollectionReference {
        db.collection(collection)
    }
    
    func document(_ path: String, in collection: String) async throws -> [String: Any]? {
        let docRef = getCollectionReference(collection).document(path)
        let snapshot = try await docRef.getDocument()
        return snapshot.exists ? snapshot.data() : nil
    }
    
    func setDocument(_ data: [String: Any], at path: String, in collection: String) async throws {
        let docRef = getCollectionReference(collection).document(path)
        try await docRef.setData(data, merge: true)
    }
    
    func deleteDocument(at path: String, in collection: String) async throws {
        let docRef = getCollectionReference(collection).document(path)
        try await docRef.delete()
    }
    
    func documentExists(path: String, in collection: String) async throws -> Bool {
        let docRef = getCollectionReference(collection).document(path)
        let snapshot = try await docRef.getDocument()
        return snapshot.exists
    }
}

actor TestFunctions: FunctionsService {
    
    private let functions: Functions
    
    init(functions: Functions = Functions.functions()) {
        self.functions = functions
    }
    
    // MARK: - Users
    func createUserWithEmail(email: String, password: String, name: String) async throws -> String {
        let result = try await functions
            .httpsCallable("users-createUserWithEmail")
            .call(["email": email, "password": password, "name": name])
        
        guard let uid = result.data as? String else {
            throw URLError(.badServerResponse)
        }
        return uid
    }
    
    func createUserWithOAuth(_ email: String, signInProvider: String) async throws -> String {
        let result = try await functions
            .httpsCallable("users-createUserWithSignInProvider")
            .call(["email": email, "signInProvider": signInProvider])
        
        guard let uid = result.data as? String else {
            throw URLError(.badServerResponse)
        }
        return uid
    }
    
    func updateUser(userId: String, email: String?, displayName: String?) async throws {
        _ = try await functions
            .httpsCallable("users-updateUser")
            .call([
                "userId": userId,
                "email": email,
                "name": displayName
            ])
    }
    
    func deleteUser(_ id: String) async throws {
        _ = try await functions
            .httpsCallable("users-deleteUser")
            .call(["userId": id])
    }
    
    // MARK: - Comments
    func postComment(movieId: String, clubId: String, comment: Comment) async throws -> String {
        do {
            let result = try await functions
                .httpsCallable("comments-postComment")
                .call(["movieId": movieId, "userName": comment.userName, "text": comment.text, "userId": comment.userId, "clubId": clubId])
            return result.data as! String
        } catch {
            throw error
        }
    }
    
    func likeComment(commentId: String, clubId: String, movieId: String) async throws {
        do {
            _ = try await functions
                .httpsCallable("comments-likeComment")
                .call(["commentId": commentId, "clubId": clubId, "movieId": movieId])
        } catch {
            print(error)
        }
    }
    
    func unlikeComment(commentId: String, clubId: String, movieId: String) async throws {
        _ = try await functions
            .httpsCallable("comments-unlikeComment")
            .call(["commentId": commentId, "clubId": clubId, "movieId": movieId])
    }
    
    @available(*, deprecated, message: "Use anonymizeComment instead")
    func deleteComment(commentId: String, clubId: String, movieId: String) async throws {
        // Forward to anonymizeComment for backward compatibility
        _ = try await functions
            .httpsCallable("comments-anonymizeComment")
            .call(["commentId": commentId, "clubId": clubId, "movieId": movieId])
    }
    
    func anonymizeComment(commentId: String, clubId: String, movieId: String) async throws -> [String: Any] {
        let result = try await functions
            .httpsCallable("comments-anonymizeComment")
            .call(["commentId": commentId, "clubId": clubId, "movieId": movieId])
        
        if let data = result.data as? [String: Any] {
            return data
        } else {
            return ["success": true]
        }
    }
    
    // MARK: - Suggestions
    func createMovieClubSuggestion(clubId: String, suggestion: String) async throws -> String {
        let result = try await functions
            .httpsCallable("suggestions-createMovieClubSuggestion")
            .call(["clubId": clubId, "suggestion": suggestion])
        
        guard let suggestionId = result.data as? String else {
            throw URLError(.badServerResponse)
        }
        return suggestionId
    }
    
    func deleteMovieClubSuggestion(suggestionId: String) async throws {
        _ = try await functions
            .httpsCallable("suggestions.deleteMovieClubSuggestion")
            .call(["suggestionId": suggestionId])
    }
    
    // MARK: - Memberships
    func joinMovieClub(clubId: String, userId: String) async throws {
        _ = try await functions
            .httpsCallable("memberships.joinMovieClub")
            .call(["clubId": clubId, "userId": userId])
    }
    
    func leaveMovieClub(clubId: String, userId: String) async throws {
        _ = try await functions
            .httpsCallable("memberships.leaveMovieClub")
            .call(["clubId": clubId, "userId": userId])
    }
    
    // MARK: - Movie Clubs
    func createMovieClub(movieClub: MovieClub) async throws -> String {
        return try await functions
            .httpsCallable("movieClubs-createMovieClub")
            .call(movieClub)
        
    }
    
    func updateMovieClub(movieClub: MovieClub) async throws -> String? {
        return try await functions
            .httpsCallable("movieClubs-updateMovieClub")
            .call(movieClub)
                
    }
    
    // MARK: - Movies
    func handleMovieReaction(movieId: String, reaction: String) async throws {
        _ = try await functions
            .httpsCallable("movies-handleMovieReaction")
            .call(["movieId": movieId, "reaction": reaction])
    }
    
    func rotateMovie(movieId: String) async throws {
        _ = try await functions
            .httpsCallable("movies-rotateMovie")
            .call(["movieId": movieId])
    }
    
    // MARK: - Posters
    func collectPoster(poster: CollectionItem) async throws -> String{
        return try await functions.httpsCallable("posters-collectPoster").call(poster)
    }
}

/*
actor TestStorage: StorageService {
    private let storage: Storage!
    
    init(storage: Storage) {
        self.storage = Storage.storage()
    }
    
    func uploadFile(_ data: Data, path: String) async throws -> URL {
        let ref = getStorageReference(path)
        _ = try await ref.putDataAsync(data)
        return try await ref.downloadURL()
    }
    
    func downloadFile(at path: String) async throws -> Data? {
        let ref = getStorageReference(path)
        let maxSize: Int64 = 1 * 1024 * 1024 // 1MB
        return try await ref.data(maxSize: maxSize)
    }
    
    func deleteFile(at path: String) async throws {
        let ref = getStorageReference(path)
        try await ref.delete()
    }
    
    private func deleteRecursively(_ reference: StorageReference) async throws {
        do {
            // List all items in this reference
            let result = try await reference.listAll()
            
            // Delete all items
            for item in result.items {
                try await item.delete()
            }
            
            // Recursively delete prefixes (folders)
            for prefix in result.prefixes {
                try await deleteRecursively(prefix)
            }
        } catch {
            // If reference doesn't exist, that's fine
            if (error as NSError).domain != StorageErrorDomain ||
                (error as NSError).code != StorageErrorCode.objectNotFound.rawValue {
                throw error
            }
        }
    }*/
