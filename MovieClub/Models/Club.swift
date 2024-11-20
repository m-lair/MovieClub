//
//  ClubModel.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/23/24.
//

import Foundation

final class MovieClub: Identifiable, Codable, Hashable, Equatable {
    var id: String?
    var name: String
    var createdAt: Date?
    var numMembers: Int?
    var desc: String?
    var ownerName: String
    var timeInterval: Int
    var movieEndDate: Date?
    var ownerId: String
    var isPublic: Bool
    var numMovies: Int?
    var members: [Member]?
    var suggestions: [Suggestion]?
    var movies: [Movie]
    
    init(
        id: String? = nil,
        name: String,
        createdAt: Date = Date(),
        desc: String? = nil,
        ownerName: String,
        timeInterval: Int,
        ownerId: String,
        isPublic: Bool,
        numMovies: Int = 0,
        members: [Member]? = [],
        suggestions: [Suggestion]? = [],
        movies: [Movie] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.desc = desc
        self.ownerName = ownerName
        self.timeInterval = timeInterval
        self.ownerId = ownerId
        self.isPublic = isPublic
        self.numMovies = numMovies
        self.members = members
        self.suggestions = suggestions
        self.movies = movies
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        numMembers = try container.decodeIfPresent(Int.self, forKey: .numMembers)
        desc = try container.decodeIfPresent(String.self, forKey: .desc)
        ownerName = try container.decode(String.self, forKey: .ownerName)
        timeInterval = try container.decode(Int.self, forKey: .timeInterval)
        movieEndDate = try container.decodeIfPresent(Date.self, forKey: .movieEndDate)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        numMovies = try container.decodeIfPresent(Int.self, forKey: .numMovies)
        movies = []
        
        if let timestamp = try? container.decode(Int.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: TimeInterval(timestamp)) // Convert Firestore Timestamp to Swift Date
        }
        
        if let str = try? container.decode(String.self, forKey: .isPublic) {
            isPublic = str.lowercased() == "true"
        } else {
            isPublic = false
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(timeInterval, forKey: .timeInterval)
        try container.encode(ownerName, forKey: .ownerName)
        try container.encode(desc, forKey: .desc)
        try container.encode(ownerId, forKey: .ownerId)
        switch isPublic {
        case true:
            try container.encode("true", forKey: .isPublic)
        case false :
            try container.encode("false", forKey: .isPublic)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt
        case numMembers
        case desc = "description"
        case ownerName
        case timeInterval
        case movieEndDate
        case ownerId
        case isPublic
        case numMovies
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MovieClub, rhs: MovieClub) -> Bool {
        lhs.id == rhs.id
    }
}

