//
//  CommentManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions
import FirebaseAuth

extension DataManager {
    
    // MARK: - Enums
    
    enum CommentError: Error {
        case commentTooLong
        case unauthorized
        case invalidData
        case networkError(Error)
        case unknownError
        
    }

    // MARK: - (Deprecated) Fetch Comments
    
    func fetchComments(movieClubId: String, movieId: String) async -> [Comment] {
        do {
            let querySnapshot = try await movieClubCollection()
                .document(movieClubId)
                .collection("movies")
                .document(movieId)
                .collection("comments")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            let comments = querySnapshot.documents.compactMap { document in
                do {
                    return try document.data(as: Comment.self)
                } catch {
                    print("Error decoding comment \(document.documentID): \(error)")
                    return nil
                }
            }
            return comments
        } catch {
            print("Error fetching comments: \(error)")
            return []
        }
    }
    
    //MARK: - CommentListener
    
    func listenForComments() {
        guard
            let movieId = movie?.id,
            let clubId = currentClub?.id
        else {
            print("unable to listen for comments")
            return
        }
        print("movieId: \(movieId), clubId: \(clubId)")
        let commentsRef = movieClubCollection()
            .document(clubId)
            .collection("movies")
            .document(movieId)
            .collection("comments")
            .order(by: "createdAt", descending: true)
        commentsListener?.remove()
        
        // Map Firestore documents to Comment model
        commentsListener = commentsRef.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else {
                print("Unknown error")
                return
            }
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            comments = snapshot.documents.compactMap { document in
                do {
                    //print("comment: \(document.data())")
                    return try document.data(as: Comment.self)
                } catch {
                    print("Error decoding comment: \(error)")
                    return nil
                }
            }
        }
    }

    func postComment(movieClubId: String, movieId: String, comment: Comment) async throws {
        let functions = Functions.functions()
        if let currentUser = Auth.auth().currentUser {
            print("User is signed in: \(currentUser.uid)")
        } else {
            print("No user is signed in.")
            // Prompt user to sign in
        }
        let parameters: [String: Any] = [
            "text" : comment.text,
            "userId": comment.userId,
            "username": comment.username,
            "movieClubId": movieClubId,
            "movieId": movieId
        ]
        let result = try await functions.httpsCallable("comments-postComment").call(parameters)
        
        if let data = result.data as? [String: Any] {
            print("comment posted: \(data)")
        }
    }
}
