//
//  CommentTests.swift
//  MovieClub
//
//  Created by Marcus Lair on 1/22/25.
//

import Testing
import Firebase
import Foundation
import FirebaseFunctions
import FirebaseFirestore
import FirebaseStorage
import class FirebaseAuth.Auth
import class MovieClub.User
@testable import MovieClub
    

@Suite("Comment Tests")
class CommentTests: BaseTests {
    
    let db = Firestore.firestore()
    
    @Test("Post comment successfully")
    func testPostComment_Success() async throws {
        try await super.setUp()
        let userId = try await super.createTestUserAuth()
        try await populateTestData()
        
        let comment = Comment(
            id: UUID().uuidString,
            userId: userId,
            userName: "test-user",
            createdAt: Date(),
            text: "testing comment",
            likes: 0
        )
        
        let _ = try await mockFunctions.postComment(movieId: "test-movie", clubId: "test-club", comment: comment)
        
        try await #expect(
            db.collection("movieclubs")
                .document("test-club")
                .collection("movies")
                .document("test-movie")
                .collection("comments")
                .getDocuments()
                .count > 0
        )
        
        try await super.tearDown()
    }
    
    @Test("Like comment successfully")
    func testLikeComment_Success() async throws {
        try await super.setUp()
        let userId = try await super.createTestUserAuth()
        try await populateTestData()
        
        // Create and post a comment
        let comment = Comment(
            id: UUID().uuidString,
            userId: userId,
            userName: "test-user",
            createdAt: Date(),
            text: "testing like",
            likes: 0
        )
        let commentId = try await mockFunctions.postComment(movieId: "test-movie", clubId: "test-club", comment: comment)
        // Like it
        try await mockFunctions.likeComment(commentId: commentId, clubId: "test-club", movieId: "test-movie")
        
        // Expect likes to increment
        let likedDoc = try await db.collection("movieclubs")
            .document("test-club")
            .collection("movies")
            .document("test-movie")
            .collection("comments")
            .document(commentId)
            .getDocument()
        
        #expect(likedDoc.data()?["likes"] as? Int == 1)
        
        try await super.tearDown()
    }
    
    @Test("Unlike comment successfully")
    func testUnlikeComment_Success() async throws {
        try await super.setUp()
        let userId = try await super.createTestUserAuth()
        try await populateTestData()

        // Create and post a comment (starting with 1 like)
        let comment = Comment(
            id: UUID().uuidString,
            userId: userId,
            userName: "test-user",
            createdAt: Date(),
            text: "testing unlike",
            likes: 1
        )
        
        let commentId = try await mockFunctions.postComment(movieId: "test-movie", clubId: "test-club", comment: comment)
        
        // Like it
        try await mockFunctions.likeComment(commentId: commentId, clubId: "test-club", movieId: "test-movie")
        
        // Unlike it
        try await mockFunctions.unlikeComment(commentId: commentId, clubId: "test-club", movieId: "test-movie")

        // Expect likes to decrement to 0
        let unlikedDoc = try await db.collection("movieclubs")
            .document("test-club")
            .collection("movies")
            .document("test-movie")
            .collection("comments")
            .document(commentId)
            .getDocument()

        #expect(unlikedDoc.data()?["likes"] as? Int == 0)

        try await super.tearDown()
    }

    @Test("Delete comment successfully")
    func testDeleteComment_Success() async throws {
        try await super.setUp()
        let userId = try await super.createTestUserAuth()
        try await populateTestData()

        // Create and post a comment
        let comment = Comment(
            id: UUID().uuidString,
            userId: userId,
            userName: "test-user",
            createdAt: Date(),
            text: "testing delete",
            likes: 0
        )
        let commentId = try await mockFunctions.postComment(movieId: "test-movie", clubId: "test-club", comment: comment)

        // Delete it
        try await mockFunctions.deleteComment(commentId: commentId, clubId: "test-club", movieId: "test-movie")

        // Expect the doc no longer exists
        let deletedDoc = try await db.collection("movieclubs")
            .document("test-club")
            .collection("movies")
            .document("test-movie")
            .collection("comments")
            .document(commentId)
            .getDocument()

        #expect(deletedDoc.exists == false)

        try await super.tearDown()
    }
    
    private func populateTestData() async throws {
        let clubData: [String: Any] = [
            "id": "test-club",
            "name": "Test Club",
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("movieclubs").document("test-club").setData(clubData)
        
        let movieData: [String: Any] = [
            "id": "test-movie",
            "title": "Test Movie",
        ]
        try await db.collection("movieclubs")
            .document("test-club")
            .collection("movies")
            .document("test-movie")
            .setData(movieData)
        
        let memberData: [String: Any] = [
            "userName": "test-user"
        ]
        try await db.collection("users")
            .document(mockAuth.currentUser!.uid)
            .collection("memberships")
            .document("test-club")
            .setData(memberData)
    }
}
