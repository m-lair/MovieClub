//
//  MovieManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

import Foundation
import FirebaseFunctions

// MARK: - DataManager Extension
extension DataManager {
    
    enum MovieError: Error {
        case noMovieFound
        case cantRotate
        case custom(message: String)
    }
    
    struct MovieResponse: Codable {
        let success: Bool
        let message: String?
    }
    
    func fetchMovies(clubId: String) async throws {
        let moviesSnapshot = try await movieClubCollection()
            .document(clubId)
            .collection("movies")
            .order(by: "endDate", descending: false)
            .limit(to: 1)
            .getDocuments()
        
        for document in moviesSnapshot.documents {
            var baseMovie = try document.data(as: Movie.self)
            baseMovie.id = document.documentID
            
            // Fetch API data for the movie
            if let apiMovie = try await fetchMovieDetails(for: baseMovie) {
                baseMovie.apiData = MovieAPIData(from: apiMovie)
            }
            currentClub?.movies.append(baseMovie)
        }
        
    }
    
    func fetchMovieDetails(for movie: Movie) async throws -> MovieAPIResponse? {
        let urlString = "https://omdbapi.com/?i=\(movie.imdbId)&apikey=ab92d369&plot=full"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("Bad server response: \(response)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(MovieAPIResponse.self, from: data)
            
            
        } catch {
            print("Failed to decode API response: \(error)")
            throw URLError(.cannotParseResponse)
        }
    }
    
    func searchMovies(query: String) async throws -> [MovieSearchResult] {
        guard !query.isEmpty else { return [] }
        
        let formattedQuery = query.replacingOccurrences(of: " ", with: "+")
        let urlString = "https://omdbapi.com/?s=\(formattedQuery)&apikey=\(omdbKey)&plot=full"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("Bad server response: \(response)")
            throw URLError(.badServerResponse)
        }
        
        do {
            let decoder = JSONDecoder()
            let searchResponse = try decoder.decode(SearchResponse.self, from: data)
            // Only return movies (filter out games and other types)
            return searchResponse.search.filter { $0.type.lowercased() == "movie" }
        } catch {
            print("Decoding error: \(error)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw URLError(.cannotParseResponse)
        }
    }
    
    
    func rotateMovie(clubId: String) async throws -> Bool {
        let rotateMovie: Callable<[String: String], MovieResponse> = functions.httpsCallable("movies-rotateMovie")
        do {
            let result = try await rotateMovie.call(["clubId": clubId])
            if result.success {
                print("Rotated movie successfully")
                return true
                
            } else {
                return false
            }
        } catch {
            throw MovieError.custom(message: error.localizedDescription)
        }
    }
}
    
    // MARK: - movie query by title
struct MovieSearchResult: Decodable, Identifiable {
    let title: String
    let year: String
    let imdbID: String
    let type: String
    let poster: String
    
    // Conform to Identifiable
    var id: String { imdbID }
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case year = "Year"
        case imdbID = "imdbID"
        case type = "Type"
        case poster = "Poster"
    }
}
    
struct SearchResponse: Decodable {
    let search: [MovieSearchResult]
    let totalResults: String
    let response: String
    
    enum CodingKeys: String, CodingKey {
        case search = "Search"
        case totalResults
        case response = "Response"
    }
}

