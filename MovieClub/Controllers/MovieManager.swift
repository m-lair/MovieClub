//
//  MovieManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

import Foundation

// MARK: - DataManager Extension
extension DataManager {
    func fetchMovieDetails(for movie: Movie) async throws -> Movie {
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
            let apiResponse = try decoder.decode(MovieAPIResponse.self, from: data)
            return Movie(
                id: movie.id,
                imdbId: apiResponse.imdbId,
                title: apiResponse.plot,
                poster: apiResponse.poster,
                secPoster: movie.secPoster,
                startDate: movie.startDate,
                endDate: movie.endDate,
                userName: movie.userName,
                userId: movie.userId,
                authorAvi: movie.authorAvi,
                runtime: apiResponse.runtime
            )
        } catch {
            print("Failed to decode API response: \(error)")
            throw URLError(.cannotParseResponse)
        }
    }
}

// MARK: - API Response Model
private struct MovieAPIResponse: Decodable {
    let imdbId: String
    let title: String
    let plot: String
    let poster: String
    let year: String
    let runtime: String
    let director: String
    let actors: String
    
    enum CodingKeys: String, CodingKey {
        case imdbId = "imdbID"
        case title = "Title"
        case plot = "Plot"
        case poster = "Poster"
        case year = "Year"
        case runtime = "Runtime"
        case director = "Director"
        case actors = "Actors"
    }
}
