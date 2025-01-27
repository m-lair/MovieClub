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
        
        // We'll decode into a small wrapper for "results" array of TMDBFindMovie
        struct SearchResponse: Codable {
            let results: [TMDBFindMovie]
        }
        
        do {
            let response = try JSONDecoder().decode(SearchResponse.self, from: data)
            
            // Now map each TMDBFindMovie to your existing MovieAPIData
            return response.results.map { tmdb in
                let posterURL = "https://image.tmdb.org/t/p/w500\(tmdb.posterPath ?? "")"
                let releaseYear = parseYear(from: tmdb.releaseDate)
                return MovieAPIData(
                    imdbId: String(tmdb.id),     // TMDB numeric ID
                    title: tmdb.title,
                    plot: tmdb.overview,
                    poster: posterURL,
                    releaseYear: releaseYear,
                    runtime: 0,
                    director: "Unknown",
                    cast: []
                )
            }
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
        let endpoint = "/movie/\(tmdbId)"
        guard let url = buildURL(endpoint: endpoint, queryItems: [
            "append_to_response": "credits"
        ]) else {
            throw APIError.invalidURL
        }

        let data = try await fetchData(from: url)
        let details = try JSONDecoder().decode(TMDBDetailsResponse.self, from: data)

        // Director / Cast
        let directorName = details.credits?.crew.first(where: { $0.job == "Director" })?.name ?? "Unknown"
        let castNames = details.credits?.cast.map { $0.name } ?? []

        // Base backdrops from the main movie details
        let horizontalBackdrop = details.backdropPath.map {
            "https://image.tmdb.org/t/p/w1280\($0)"
        }
        var verticalBackdrop = details.backdropPath.map {
            "https://image.tmdb.org/t/p/w780\($0)"
        }
        
        // If there's a collection, see if that same part has a different backdrop
        if let collection = details.belongsToCollection {
            // fetch the full collection
            let collectionDetails = try await fetchCollectionDetails(collectionId: collection.id)

                // Step B: also fetch the images for the entire collection
                let collectionImages = try await fetchCollectionImages(collectionId: collection.id)

                // Step C: pick some unique backdrop that’s different from the main movie’s
                // For example, maybe you just pick the first backdrop that isn't the same path
            if let mainBackdropPath = details.backdropPath {
                if let differentBackdrop = collectionImages.backdrops.first(where: { $0.filePath != mainBackdropPath }) {
                    let altBackdropURL = "https://image.tmdb.org/t/p/w780\(differentBackdrop.filePath)"
                    verticalBackdrop = altBackdropURL
                    print("Using unique vertical backdrop from collection images: \(altBackdropURL)")
                }
            }
        }

        let updatedData = MovieAPIData(
            imdbId: baseData.imdbId,
            title: baseData.title,
            plot: baseData.plot,
            poster: baseData.poster,
            releaseYear: baseData.releaseYear,
            runtime: details.runtime ?? 0,
            director: directorName,
            cast: castNames,
            backdropHorizontal: horizontalBackdrop,
            backdropVertical: verticalBackdrop
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
    
    private func fetchCollectionDetails(collectionId: Int) async throws -> TMDBCollectionDetail {
        let endpoint = "/collection/\(collectionId)"
        guard let url = buildURL(endpoint: endpoint) else {
            throw APIError.invalidURL
        }

        let data = try await fetchData(from: url)
        let collectionResponse = try JSONDecoder().decode(TMDBCollectionDetail.self, from: data)
        return collectionResponse
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
        let backdropPath: String?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case overview
            case posterPath = "poster_path"
            case releaseDate = "release_date"
            case backdropPath = "backdrop_path"
        }
    }
    
    // This struct represents the full JSON you get from /collection/{collectionId}.
    private struct TMDBCollectionDetail: Codable {
        let id: Int
        let name: String
        let overview: String?
        let posterPath: String?
        let backdropPath: String?
        let parts: [TMDBFindMovie]

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case overview
            case posterPath = "poster_path"
            case backdropPath = "backdrop_path"
            case parts
        }
    }
    
    private struct TMDBDetailsResponse: Codable {
        let runtime: Int?
        let backdropPath: String?
        let credits: TMDBCredits?
        let belongsToCollection: TMDBCollection?
        
        enum CodingKeys: String, CodingKey {
            case runtime
            case backdropPath = "backdrop_path"
            case credits
            case belongsToCollection = "belongs_to_collection"
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
    
    private struct TMDBCollection: Codable {
        let id: Int
        let name: String
        let posterPath: String?
        let backdropPath: String?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case posterPath = "poster_path"
            case backdropPath = "backdrop_path"
        }
    }
    
    private struct TMDBCollectionImages: Codable {
        let id: Int
        let backdrops: [TMDBImage]
        let posters: [TMDBImage]
    }

    private struct TMDBImage: Codable {
        let filePath: String
        let aspectRatio: Double?
        let height: Int?
        let width: Int?
        
        enum CodingKeys: String, CodingKey {
            case filePath = "file_path"
            case aspectRatio = "aspect_ratio"
            case height
            case width
        }
    }
    
    private func fetchCollectionImages(collectionId: Int) async throws -> TMDBCollectionImages {
        let endpoint = "/collection/\(collectionId)/images"
        guard let url = buildURL(endpoint: endpoint) else {
            throw APIError.invalidURL
        }

        let data = try await fetchData(from: url)
        let images = try JSONDecoder().decode(TMDBCollectionImages.self, from: data)
        return images
    }
}
