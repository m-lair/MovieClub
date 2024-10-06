//
//  MovieClubTests.swift
//  MovieClubTests
//
//  Created by Marcus Lair on 9/28/24.
//

import Testing
import Firebase
import FirebaseFunctions
@testable import MovieClub


    
    @Suite struct UserAuthTests {
        let createUserWithEmail: Callable<[String: String], String> = Functions.functions().httpsCallable("users-createUserWithEmail")
        let createUserWithSignInProvider: Callable<[String: String], String> = Functions.functions().httpsCallable("users-createUserWithSignInProvider")
        let updateUser: Callable<[String: String], String> = Functions.functions().httpsCallable("users-updateUser")
        
        let id = UUID()
        
        @Test func signUp() async throws {
            let userData = ["email": "test\(id)@test.com", "password": "123456", "name": "test\(id)"]
            let userId = try await createUserWithEmail(userData)
            #expect(userId != "")
        }
        
        @Test func signUpWithProvider() async throws {
            let providerData = ["signInProvider": "apple", "idToken": "sampleIdToken", "email": "test\(id)@test.com", "name": "test\(id)"]
            let userId = try await createUserWithSignInProvider(providerData)
            #expect(userId != "")
        }
        
        @Test func updateUser() async throws {
            let userUpdateData = ["email": "newtest\(id)@test.com", "name": "updatedName"]
            let updatedUserId = try await updateUser(userUpdateData)
            #expect(updatedUserId != "")
        }
    }
    
    @Suite struct CommentTests {
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
    
@Suite struct MovieClubTests {
    let createMovieClub: Callable<MovieClub, MovieClub> = Functions.functions().httpsCallable("movieClubs-createMovieClub")
    let updateMovieClub: Callable<MovieClub, MovieClub> = Functions.functions().httpsCallable("movieClubs-updateMovieClub")
    let movieClub = MovieClub(name: "test-club",
                              desc: "this is a test movie club",
                              ownerName: "test-user",
                              timeInterval: 2,
                              ownerId: "test-user-id",
                              isPublic: true,
                              bannerUrl: "no-image")
    
    //MARK: - Set Up
    
    private func populateClubData() async throws {
        
        //Test Club w/ no members
    }
    
    @Test func createMovieClub() async throws {
        let createdClub = try await createMovieClub(movieClub)
        #expect(createdClub != nil && createdClub.name == movieClub.name)
    }
    
    @Test func updateMovieClub() async throws {
        var movieClub = try await createMovieClub(movieClub)
        print(movieClub.id)
        movieClub.name = "updated-club"
        let resultClub = try await updateMovieClub(movieClub)
        #expect(resultClub != nil && resultClub.id != movieClub.id)
    }
}

