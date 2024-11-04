import Foundation
import SwiftUI


// MARK: - Base Movie Model (Firestore)
struct Movie: Identifiable, Codable {
    // Firestore stored properties
    var id: String?
    let userId: String
    let imdbId: String
    let startDate: Date
    let endDate: Date
    let userName: String
    
    // Analytics & Social Data
    var likes: Int
    var dislikes: Int
    var numCollections: Int
    var numComments: Int
    
    // API Data
    var apiData: MovieAPIData?
    
    init(
        id: String? = nil,
        userId: String,
        imdbId: String,
        startDate: Date,
        endDate: Date,
        userName: String,
        likes: Int = 0,
        dislikes: Int = 0,
        numCollections: Int = 0,
        numComments: Int = 0,
        apiData: MovieAPIData? = nil
    ) {
        self.id = id
        self.userId = userId
        self.imdbId = imdbId
        self.startDate = startDate
        self.endDate = endDate
        self.userName = userName
        self.likes = likes
        self.dislikes = dislikes
        self.numCollections = numCollections
        self.numComments = numComments
        self.apiData = apiData
    }
}

// MARK: - Movie API Response (Raw API Data)
struct MovieAPIResponse: Codable, Equatable, Hashable {
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        imdbId = try container.decode(String.self, forKey: .imdbId)
        title = try container.decode(String.self, forKey: .title)
        plot = try container.decodeIfPresent(String.self, forKey: .plot) ?? ""
        poster = try container.decodeIfPresent(String.self, forKey: .poster) ?? ""
        year = try container.decode(String.self, forKey: .year)
        runtime = try container.decodeIfPresent(String.self, forKey: .runtime) ?? ""
        director = try container.decode(String.self, forKey: .director)
        actors = try container.decode(String.self, forKey: .actors)
    }
}

// MARK: - Movie API Data (Processed API Data)
struct MovieAPIData: Codable, Equatable, Hashable {
    let title: String
    let plot: String
    let poster: String
    let releaseYear: Int
    let runtime: Int
    let director: String
    let cast: [String]
    
    init(from response: MovieAPIResponse) {
        self.title = response.title
        self.plot = response.plot
        self.poster = response.poster
        self.releaseYear = Int(response.year) ?? 0
        self.runtime = response.runtime.components(separatedBy: " ").first.flatMap { Int($0) } ?? 0
        self.director = response.director
        self.cast = response.actors.components(separatedBy: ", ")
    }
}

// MARK: - Movie Convenience Properties
extension Movie {
    var title: String { apiData?.title ?? "Loading..." }
    var plot: String { apiData?.plot ?? "" }
    var poster: String { apiData?.poster ?? "" }
    var releaseYear: Int { apiData?.releaseYear ?? 0 }
    var runtime: Int { apiData?.runtime ?? 0 }
    var director: String { apiData?.director ?? "" }
    var cast: [String] { apiData?.cast ?? [] }
        
    var castFormatted: String {
        cast.joined(separator: ", ")
    }
        
    var yearFormatted: String {
        String(releaseYear)
    }
}
