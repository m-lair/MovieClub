import Foundation
import SwiftUI
import Observation


// MARK: - Base Movie Model (Firestore)
@Observable
final class Movie: Identifiable, Codable, Equatable, Hashable {
    // Firestore stored properties
    var id: String?
    let userId: String
    let imdbId: String
    let startDate: Date
    let endDate: Date
    let userName: String
    let status: String
    var likedBy: [String] = []
    var dislikedBy: [String] = []
    var collectedBy: [String] = []
    var movieClubId: String
    
    // Analytics & Social Data
    var likes: Int
    var dislikes: Int
    var numCollected: Int
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
        status: String,
        likes: Int = 0,
        dislikes: Int = 0,
        numCollected: Int = 0,
        numComments: Int = 0,
        likedBy: [String] = [],
        dislikedBy: [String] = [],
        collectedBy: [String] = [],
        movieClubId: String = "",
        apiData: MovieAPIData? = nil
    ) {
        self.id = id
        self.userId = userId
        self.imdbId = imdbId
        self.startDate = startDate
        self.endDate = endDate
        self.userName = userName
        self.likes = likes
        self.likedBy = likedBy
        self.dislikes = dislikes
        self.dislikedBy = dislikedBy
        self.numCollected = numCollected
        self.collectedBy = collectedBy
        self.movieClubId = movieClubId
        self.numComments = numComments
        self.apiData = apiData
        self.status = status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        imdbId = try container.decode(String.self, forKey: .imdbId)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        userName = try container.decode(String.self, forKey: .userName)
        likes = try container.decode(Int.self, forKey: .likes)
        dislikes = try container.decode(Int.self, forKey: .dislikes)
        likedBy = try container.decode([String].self, forKey: .likedBy)
        dislikedBy = try container.decode([String].self, forKey: .dislikedBy)
        numCollected = try container.decode(Int.self, forKey: .numCollected)
        collectedBy = try container.decode([String].self, forKey: .collectedBy)
        numComments = try container.decode(Int.self, forKey: .numComments)
        status = try container.decode(String.self, forKey: .status)

        movieClubId = try container.decodeIfPresent(String.self, forKey: .movieClubId) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(userName, forKey: .userName)
        try container.encode(imdbId, forKey: .imdbId)
        try container.encode(likes, forKey: .likes)
        try container.encode(likedBy, forKey: .likedBy)
        try container.encode(dislikes, forKey: .dislikes)
        
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case startDate
        case endDate
        case userName
        case imdbId
        case likes
        case likedBy
        case dislikes
        case dislikedBy
        case numCollected
        case collectedBy
        case movieClubId
        case numComments
        case status
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Movie, rhs: Movie) -> Bool {
        lhs.id == rhs.id
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
