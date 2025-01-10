//
//  APIError.swift
//  MovieClub
//
//  Created by Marcus Lair on 1/4/25.
//


import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
}

// A wrapper response for TMDB results
struct ApiResponse<T: Codable>: Codable {
    let results: [T]
    let posterPath: String?
    
    enum CodingKeys: String, CodingKey {
        case results
        case posterPath = "poster_path"
    }
}

// MARK: - APIController
@Observable
class APIController {
    
    // MARK: - Properties
    private let baseURL = "https://api.themoviedb.org/3"
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Public Methods
    func fetchMovies(query: String) async throws -> [MovieAPIData] {
        let endpoint = "/search/movie"
        guard let url = buildURL(endpoint: endpoint, queryItems: ["query": query]) else {
            throw APIError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        
        do {
            let response = try JSONDecoder().decode(ApiResponse<MovieAPIData>.self, from: data)
            return response.results
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
    
    func fetchMovieDetails(_ imdbId: String) async throws -> MovieAPIData? {
        let endpoint = "/find/\(imdbId)"
        guard let url = buildURL(endpoint: endpoint) else {
            throw APIError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        let response = try JSONDecoder().decode(TMDBFindResponse.self, from: data)
        
        guard let firstResult = response.movieResults.first else {
            return nil
        }
        
        // Quick partial data from "/find"
        let posterFullPath = "https://image.tmdb.org/t/p/w500\(firstResult.posterPath ?? "")"
        let releaseYear = parseYear(from: firstResult.releaseDate)

        let baseData = MovieAPIData(
            imdbId: imdbId,
            title: firstResult.title,
            plot: firstResult.overview,
            poster: posterFullPath,
            releaseYear: releaseYear,
            runtime: 0,
            director: "Unknown",
            cast: []
        )
        
        // Now get the FULL details
        let fullyLoaded = try await fetchMovieFullDetails(tmdbId: firstResult.id, baseData: baseData)
        
        return fullyLoaded
    }


    // A tiny helper to parse just the year out of "YYYY-MM-DD"
    private func parseYear(from dateString: String?) -> Int {
        guard let dateString = dateString,
              let yearString = dateString.split(separator: "-").first else {
            return 0
        }
        return Int(yearString) ?? 0
    }
    
    func fetchMovieFullDetails(tmdbId: Int, baseData: MovieAPIData) async throws -> MovieAPIData {
        // Build a URL: /movie/{tmdb_id}?append_to_response=credits
        let endpoint = "/movie/\(tmdbId)"
        guard let url = buildURL(endpoint: endpoint, queryItems: [
            "append_to_response": "credits"
        ]) else {
            throw APIError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        
        // Decode the details
        let details = try JSONDecoder().decode(TMDBDetailsResponse.self, from: data)
        
        // Figure out the director
        let directorName = details.credits?.crew.first(where: { $0.job == "Director" })?.name ?? "Unknown"
        
        // Map cast (limit or grab them all, your choice)
        let castNames = details.credits?.cast.map { $0.name } ?? []
        
        // Build backdrop URLs
        // Example: building a backdrop for horizontal usage
        let horizontalBackdrop = details.backdropPath.map {
            "https://image.tmdb.org/t/p/w1280\($0)"
        }

        // Example: building a backdrop for vertical usage
        let verticalBackdrop = details.backdropPath.map {
            "https://image.tmdb.org/t/p/w780\($0)"
        }

        let updatedData = MovieAPIData(
            imdbId: baseData.imdbId,
            title: baseData.title,
            plot: baseData.plot,
            poster: baseData.poster,                        // w500
            releaseYear: baseData.releaseYear,
            runtime: details.runtime ?? 0,
            director: directorName,
            cast: castNames,
            backdropHorizontal: horizontalBackdrop, // w1280
            backdropVertical: verticalBackdrop      // w780
        )
        
        return updatedData
    }


    
    func fetchPopularMovies() async throws -> [MovieAPIData] {
        let endpoint = "/movie/popular"
        guard let url = buildURL(endpoint: endpoint) else {
            throw APIError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        
        do {
            let response = try JSONDecoder().decode(ApiResponse<MovieAPIData>.self, from: data)
            return response.results
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
    
    func fetchPosterUrl(imdbId: String) async throws -> String {
        let endpoint = "/movie/\(imdbId)"
        guard let url = buildURL(endpoint: endpoint) else {
            throw APIError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        
        struct APIResponse: Decodable {
            let posterPath: String?
            
            enum CodingKeys: String, CodingKey {
                case posterPath = "poster_path"
            }
        }
        
        do {
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            if let posterPath = apiResponse.posterPath {
                return "https://image.tmdb.org/t/p/w500\(posterPath)"
            } else {
                return ""
            }
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    
    // MARK: - Private Helpers
    private func buildURL(endpoint: String, queryItems: [String: String] = [:]) -> URL? {
        var components = URLComponents(string: baseURL + endpoint)
        var items = [URLQueryItem(name: "api_key", value: apiKey), URLQueryItem(name: "external_source", value: "imdb_id")]
        for (key, value) in queryItems {
            items.append(URLQueryItem(name: key, value: value))
        }
        components?.queryItems = items
        return components?.url
    }
    
    private func fetchData(from url: URL) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("response: \(response)")
                throw APIError.invalidResponse
            }
            
            return data
        } catch {
            throw APIError.requestFailed(error)
        }
    }
    
    // TMDB Response Structs
    private struct TMDBFindResponse: Codable {
        let movieResults: [TMDBFindMovie]

        enum CodingKeys: String, CodingKey {
            case movieResults = "movie_results"
        }
    }

    private struct TMDBFindMovie: Codable {
        let id: Int
        let title: String
        let overview: String
        let posterPath: String?
        let releaseDate: String?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case overview
            case posterPath = "poster_path"
            case releaseDate = "release_date"
        }
    }
    
    private struct TMDBDetailsResponse: Codable {
        let runtime: Int?
        let backdropPath: String?
        let credits: TMDBCredits?
        
        enum CodingKeys: String, CodingKey {
            case runtime
            case backdropPath = "backdrop_path"
            case credits
        }
    }

    private struct TMDBCredits: Codable {
        let cast: [TMDBCast]
        let crew: [TMDBCrew]
    }

    private struct TMDBCast: Codable {
        let name: String
    }

    private struct TMDBCrew: Codable {
        let name: String
        let job: String
    }
}
