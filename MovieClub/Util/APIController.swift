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
    
    func fetchMovieDetails(_ movieId: String) async throws -> MovieAPIData {
        let endpoint = "/movie/\(movieId)"
        guard let url = buildURL(endpoint: endpoint) else {
            throw APIError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        
        do {
            return try JSONDecoder().decode(MovieAPIData.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
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
    
    // MARK: - Private Helpers
    private func buildURL(endpoint: String, queryItems: [String: String] = [:]) -> URL? {
        var components = URLComponents(string: baseURL + endpoint)
        var items = [URLQueryItem(name: "api_key", value: apiKey)]
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
                throw APIError.invalidResponse
            }
            
            return data
        } catch {
            throw APIError.requestFailed(error)
        }
    }
}
