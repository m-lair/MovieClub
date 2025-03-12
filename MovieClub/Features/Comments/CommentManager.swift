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
        
        // Remove any existing listener
        commentsListener?.remove()
        
        let commentsRef = movieClubCollection()
            .document(clubId)
            .collection("movies")
            .document(movieId)
            .collection("comments")
            .order(by: "createdAt", descending: false) // Use ascending order for thread readability
        
        commentsListener = commentsRef.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else {
                print("Unknown Error")
                return
            }
            
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            
            self.processCommentSnapshot(snapshot)
        }
    }
    
    // Method to manually refresh comments
    func refreshComments() {
        guard !movieId.isEmpty else {
            print("movieId is empty")
            return
        }
        
        Task {
            do {
                let snapshot = try await movieClubCollection()
                    .document(clubId)
                    .collection("movies")
                    .document(movieId)
                    .collection("comments")
                    .order(by: "createdAt", descending: false)
                    .getDocuments()
                
                // Process on the main thread
                await MainActor.run {
                    processCommentSnapshot(snapshot)
                }
            } catch {
                print("Error refreshing comments: \(error)")
            }
        }
    }
    
    // Helper method to process comment snapshots
    private func processCommentSnapshot(_ snapshot: QuerySnapshot) {
        let fetchedComments = snapshot.documents.compactMap { document -> Comment? in
            do {
                var comment = try document.data(as: Comment.self)
                comment.id = document.documentID
                return comment
            } catch {
                print("Error decoding comment: \(error)")
                return nil
            }
        }
        
        // Organize comments into a hierarchical structure
        DispatchQueue.main.async {
            self.comments = self.buildCommentTree(from: fetchedComments)
        }
    }
    
    func buildCommentTree(from comments: [Comment]) -> [CommentNode] {
        var commentDict = [String: CommentNode]()
        var rootComments = [CommentNode]()

        // Create nodes for all comments
        for comment in comments {
            let node = CommentNode(comment: comment)
            commentDict[comment.id] = node
        }

        // Build the tree
        for node in commentDict.values {
            if let parentId = node.comment.parentId, let parentNode = commentDict[parentId] {
                parentNode.replies.append(node)
            } else {
                rootComments.append(node)
            }
        }

        // Sort rootComments by createdAt
        rootComments.sort { $0.comment.createdAt < $1.comment.createdAt }

        // Sort replies recursively
        for node in commentDict.values {
            node.replies.sort { $0.comment.createdAt < $1.comment.createdAt }
        }
        
        // Filter out anonymized comments that have no replies
        rootComments = rootComments.filter { node in
            // Keep the comment if it's not anonymized or if it has replies
            return node.comment.userId != "anonymous-user" || !node.replies.isEmpty
        }
        
        // Do the same for all replies recursively
        for node in commentDict.values {
            node.replies = node.replies.filter { childNode in
                return childNode.comment.userId != "anonymous-user" || !childNode.replies.isEmpty
            }
        }

        return rootComments
    }
    
    
    
    // MARK: - Delete Comment
    
    @available(*, deprecated, message: "Use anonymizeComment instead")
    func deleteComment(movieClubId: String, movieId: String, commentId: String) async throws {
        // Forward to anonymizeComment for backward compatibility
        let parameters: [String: Any] = [
            "commentId": commentId,
            "clubId": movieClubId,
            "movieId": movieId
        ]
        
        do {
            _ = try await functions.httpsCallable("comments-anonymizeComment").call(parameters)
        } catch {
            throw error
        }
    }
    
    // MARK: - Anonymize Comment
    
    func anonymizeComment(commentId: String) async throws -> [String: Any] {
        let parameters: [String: Any] = [
            "commentId": commentId,
            "clubId": clubId,
            "movieId": movieId
        ]
        
        do {
            let result = try await functions.httpsCallable("comments-anonymizeComment").call(parameters)
            if let data = result.data as? [String: Any] {
                return data
            } else {
                return ["success": true]
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Report Comment
    
    func reportComment(commentId: String, reason: String) async throws -> [String: Any] {
        let parameters: [String: Any] = [
            "commentId": commentId,
            "clubId": clubId,
            "movieId": movieId,
            "reason": reason
        ]
        
        do {
            let result = try await functions.httpsCallable("comments-reportComment").call(parameters)
            if let data = result.data as? [String: Any] {
                return data
            } else {
                return ["success": true]
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Post Comment
    
    func postComment(clubId: String, movieId: String, comment: Comment) async throws {
        
        var parameters: [String: Any] = [
            "text": comment.text,
            "userId": comment.userId,
            "userName": comment.userName,
            "clubId": clubId,
            "movieId": movieId
        ]
        
        if let parentId = comment.parentId {
            parameters["parentId"] = parentId
        }
        
        do {
            _ = try await functions.httpsCallable("comments-postComment").call(parameters)
            print("Posted comment")
        } catch {
            print("Error posting comment: \(error)")
            throw error
        }
    }
    
    func likeComment(commentId: String, userId: String) async throws {
        let parameters: [String: Any] = [
            "commentId": commentId,
            "clubId": clubId,
            "movieId": movieId
        ]
        
        do {
            _ = try await functions.httpsCallable("comments-likeComment").call(parameters)
                                                                               
        } catch {
            throw error
        }
    }
    
    func unlikeComment(commentId: String, userId: String) async throws {
        let parameters: [String: Any] = [
            "commentId": commentId,
            "clubId": clubId,
            "movieId": movieId
        ]
        
        do {
            _ = try await functions.httpsCallable("comments-unlikeComment").call(parameters)
                                                                               
        } catch {
            throw error
        }
    }
}

