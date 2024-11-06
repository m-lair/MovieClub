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
    
    func fetchComments(clubId: String, movieId: String) async throws -> [Comment] {
        
        let snapshot = try await movieClubCollection()
            .document(clubId)
            .collection("movies")
            .document(movieId)
            .collection("comments")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> Comment? in
            do {
                let comment = try document.data(as: Comment.self)
                comment.id = document.documentID
                return comment
            } catch {
                print("Error decoding comment \(document.documentID): \(error)")
                return nil
            }
        }
    }
    
    //MARK: - CommentListener
    
    func listenToComments(movieId: String) {
        guard !movieId.isEmpty else {
            print("movieId is empty")
            return
        }
        
        let commentsRef = movieClubCollection()
            .document(clubId)
            .collection("movies")
            .document(movieId)
            .collection("comments")
            .order(by: "createdAt", descending: true)
        
        commentsListener?.remove()
        
        // Map Firestore documents to Comment model
        commentsListener = commentsRef.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self else {
                print("Unknown Eror")
                return
            }
            
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            
            comments = snapshot.documents.compactMap { document -> Comment? in
                do {
                    var comment = try document.data(as: Comment.self)
                    comment.id = document.documentID
                    print("comment id: \(comment.id)")
                    return comment
                } catch {
                    print("Error decoding comment: \(error)")
                    return nil
                }
            }
        }
    }
    
    // MARK: - Delete Comment
    
    func deleteComment(movieClubId: String, movieId: String, commentId: String) async throws {
        guard
            let currentUser
        else {
            throw CommentError.unauthorized
        }
        
        let parameters: [String: Any] = [
            "movieClubId": movieClubId,
            "movieId": movieId
        ]
        
        do {
            let result = try await functions.httpsCallable("comments-deleteComment").call(parameters)
        } catch {
            throw error
        }
    }
    
    // MARK: - Post Comment

    func postComment(clubId: String, movieId: String, comment: Comment) async throws {
        let parameters: [String: Any] = [
            "text" : comment.text,
            "userId": comment.userId,
            "userName": comment.userName,
            "clubId": clubId,
            "movieId": movieId
        ]
        
        do {
            _ = try await functions.httpsCallable("comments-postComment").call(parameters)
            print("posted comment")
        } catch {
            print("error posting comment: \(error)")
            throw error
        }
    }
}
