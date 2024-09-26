//
//  CommentManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

//
//  DataManager+Comments.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

extension DataManager {
    
    // MARK: - Enums
    
    enum PostCommentError: Error {
        case encodingFailed
        case networkError(String)
        case invalidResponse
    }

    // MARK: - Fetch Comments
    
    func fetchComments(movieClubId: String, movieId: String) async -> [Comment] {
        do {
            let querySnapshot = try await movieClubCollection()
                .document(movieClubId)
                .collection("movies")
                .document(movieId)
                .collection("comments")
                //.order(by: "date", descending: true)
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
    
    func listenForComments() {
        // Stop any previous listener to avoid duplicating listener
        print("movie: \(movie?.id)" , "currentClub: \(currentClub?.id)")
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
            .order(by: "date", descending: true)
        
        commentsListener?.remove()
        
        // Map Firestore documents to Comment model
        commentsListener = commentsRef.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            
            self.comments = snapshot.documents.compactMap { document in
                do {
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
        guard let commentDict = try? encodeCommentToDict(comment) else {
            throw PostCommentError.encodingFailed
        }
        
        let parameters: [String: Any] = [
            "text" : comment.text,
            "userId": comment.userId,
            "userName": comment.username,
            "movieClubId": movieClubId,
            "movieId": movieId
        ]
        
        do {
            _ = try await functions.httpsCallable("comments-postComment").call(parameters)
        } catch {
            print(error)
            throw PostCommentError.invalidResponse
        }
    }

    // Helper function to encode the comment into a dictionary
    private func encodeCommentToDict(_ comment: Comment) throws -> [String: Any] {
        let encoder = JSONEncoder()
        let commentData = try encoder.encode(comment)
        guard let commentDict = try JSONSerialization.jsonObject(with: commentData, options: .fragmentsAllowed) as? [String: Any] else {
            throw PostCommentError.encodingFailed
        }
        return commentDict
    }
}
