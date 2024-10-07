//
//  ClubModel.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/23/24.
//

import Foundation
import SwiftData

@Model
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
    var banner: Data?
    var bannerUrl: String?
    var numMovies: Int?
    var members: [Member]?
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
        banner: Data? = nil,
        bannerUrl: String? = "no-image",
        numMovies: Int = 0,
        members: [Member]? = [],
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
        self.banner = banner
        self.bannerUrl = bannerUrl
        self.numMovies = numMovies
        self.members = members
        self.movies = movies
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        numMembers = try container.decode(Int.self, forKey: .numMembers)
        desc = try container.decodeIfPresent(String.self, forKey: .desc)
        ownerName = try container.decode(String.self, forKey: .ownerName)
        timeInterval = try container.decode(Int.self, forKey: .timeInterval)
        movieEndDate = try container.decodeIfPresent(Date.self, forKey: .movieEndDate)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        bannerUrl = try container.decodeIfPresent(String.self, forKey: .bannerUrl)
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
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(timeInterval, forKey: .timeInterval)
        try container.encode(bannerUrl, forKey: .bannerUrl)
        try container.encode(ownerName, forKey: .ownerName)
        try container.encode(desc, forKey: .desc)
        
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
        case banner
        case bannerUrl
        case numMovies
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MovieClub, rhs: MovieClub) -> Bool {
        lhs.id == rhs.id
    }
}

