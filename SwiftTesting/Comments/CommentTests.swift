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
    
    @Test("Post comment successfully")
    func testPostComment_Success() async throws {
        try await super.setUp()
        let userId = try await super.createTestUserAuth()
        let movieId = UUID().uuidString
        let comment = Comment(id: UUID().uuidString, userId: "testUserId", userName: "test-user", createdAt: Date(), text: "testing comment", likes: 0)
        let commentId = try await mockFunctions.postComment(movieId: "test-movie", clubId: "test-club", comment: comment)
        #expect(!commentId.isEmpty)
        try await super.tearDown()
    }
    
    @Test("Like comment successfully")
    func testLikeComment_Success() async throws {
        try await super.setUp()
        let commentId = UUID().uuidString
        try await mockFunctions.likeComment(commentId: commentId)
        let document = try await mockFirestore.document(commentId, in: "comments")
        #expect(document?["likes"] as! Int > 0)
        try await super.tearDown()
    }
    
    @Test("Unlike comment successfully")
    func testUnlikeComment_Success() async throws {
        try await super.setUp()
        let commentId = UUID().uuidString
        try await mockFunctions.unlikeComment(commentId: commentId)
        let document = try await mockFirestore.document(commentId, in: "comments")
        #expect(document?["likes"] as! Int == 0)
        try await super.tearDown()
    }
    
    @Test("Delete comment successfully")
    func testDeleteComment_Success() async throws {
        try await super.setUp()
        let userId = try await super.createTestUserAuth()
        
        let comment = Comment(id: UUID().uuidString, userId: "testUserId", userName: "test-user", createdAt: Date(), text: "testing comment", likes: 0)
        let commentId = try await mockFunctions.postComment(movieId: "test-movie", clubId: "test-club", comment: comment)
        try await mockFunctions.deleteComment(commentId: commentId)
        let exists = try await mockFirestore.documentExists(path: commentId, in: "comments")
        #expect(!exists)
        try await super.tearDown()
    }
}
