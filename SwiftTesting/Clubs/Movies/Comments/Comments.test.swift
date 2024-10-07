//
//  Comments.test.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/6/24.
//

import Testing
import Firebase
import Foundation
import FirebaseFunctions
import FirebaseAuth
import FirebaseFirestore
@testable import MovieClub


@Suite struct CommentFunctionsTests {
    let postComment: Callable<[String: String], String> = Functions.functions().httpsCallable("comments-postComment")
    let deleteComment: Callable<[String: String], String?> = Functions.functions().httpsCallable("comments-deleteComment")
    
    let commentId = UUID()
    let movieId = "test-movie"
    let movieClubId = "test-movie-club"
    
    @Test func postComment() async throws {
        let commentData = ["text": "This is a test comment", "movieClubId": movieClubId, "movieId": movieId, "username": "test-user", "userId": "\("test-user-id")"]
        let response = try await postComment(commentData)
        #expect(response != "")
    }
    
    @Test func deleteComment() async throws {
        let deleteData = ["id": "\(commentId)", "movieClubId": movieClubId, "movieId": movieId]
        do {
            _ = try await deleteComment(deleteData)
            #expect(true)
        } catch {
            #expect(Bool(false))
        }
    }
}
