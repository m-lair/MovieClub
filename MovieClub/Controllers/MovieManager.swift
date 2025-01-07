//
//  MovieManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

import Foundation
import FirebaseFunctions


extension DataManager {
    enum MovieError: Error {
        case noMovieFound
        case cantRotate
        case custom(message: String)
    }
    
    struct MovieFunctionsResponse: Codable {
        let success: Bool
        let message: String?
    }
    
    // MARK: - Fetch Movies for Club
    func fetchFirestoreMovies(clubId: String) async throws {
        // Fetch movies from Firestore
        let moviesSnapshot = try await movieClubCollection()
            .document(clubId)
            .collection("movies")
            .order(by: "endDate", descending: false)
            .getDocuments()
        
        for document in moviesSnapshot.documents {
            var baseMovie = try document.data(as: Movie.self)
            baseMovie.id = document.documentID
            
            // Fetch and attach API data to the movie
            if let apiMovieData = try await fetchMovieAPIData(for: baseMovie.imdbId) {
                baseMovie.apiData = apiMovieData
            }
            
            currentClub?.movies.append(baseMovie)
        }
    }
    
    // MARK: - Fetch Movie Details
    func fetchMovieAPIData(for imdbId: String) async throws -> MovieAPIData? {
        guard !imdbId.isEmpty else { throw MovieError.noMovieFound }
        
        // Use the APIController to fetch movie details
        do {
            let apiResponse = try await tmdb.fetchMovieDetails(imdbId)
            return apiResponse
        } catch {
            throw MovieError.custom(message: "Failed to fetch movie details: \(error.localizedDescription)")
        }
    }
    
    func fetchTMDBMovies(query: String) async throws -> [MovieAPIData] {
        guard !query.isEmpty else { return [] }

        do {
            let tmdbResults = try await tmdb.fetchMovies(query: query)
            return tmdbResults
        } catch {
            throw MovieError.custom(message: "Failed to fetch movies: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Rotate Movie (Firebase Function)
    func rotateMovie(clubId: String) async throws -> Bool {
        let rotateMovie: Callable<[String: String], MovieFunctionsResponse> = functions.httpsCallable("movies-rotateMovie")
        do {
            let result = try await rotateMovie.call(["clubId": clubId])
            return result.success
        } catch {
            throw MovieError.custom(message: error.localizedDescription)
        }
    }
}
