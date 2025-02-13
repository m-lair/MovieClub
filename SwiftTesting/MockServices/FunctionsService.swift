//
//  FunctionsService.swift
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
import FirebaseAuth
import class MovieClub.Comment
import class MovieClub.MovieClub
@testable import MovieClub

protocol FunctionsService {
    // MARK: - Users
    func createUserWithEmail(email: String, password: String, name: String) async throws -> String
    func createUserWithOAuth(_ email: String, signInProvider: String) async throws -> String
    func updateUser(userId: String, email: String?, displayName: String?) async throws
    func deleteUser(_ id: String) async throws
    
    // MARK: - Comments
    func postComment(movieId: String, clubId: String, comment: Comment) async throws -> String
    func likeComment(commentId: String, clubId: String, movieId: String) async throws
    func unlikeComment(commentId: String, clubId: String, movieId: String) async throws
    func deleteComment(commentId: String, clubId: String, movieId: String) async throws
    
    // MARK: - Suggestions
    func createMovieClubSuggestion(clubId: String, suggestion: String) async throws -> String
    func deleteMovieClubSuggestion(suggestionId: String) async throws
    
    // MARK: - Memberships
    func joinMovieClub(clubId: String, userId: String) async throws
    func leaveMovieClub(clubId: String, userId: String) async throws
    
    // MARK: - Movie Clubs
    func createMovieClub(movieClub: MovieClub) async throws -> String
    func updateMovieClub(movieClub: MovieClub) async throws -> String?
    
    // MARK: - Movies
    func handleMovieReaction(movieId: String, reaction: String) async throws
    func rotateMovie(movieId: String) async throws
    
    // MARK: - Posters
    func collectPoster(poster: CollectionItem) async throws -> String
}
