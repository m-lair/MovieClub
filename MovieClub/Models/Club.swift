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
    var createdAt: Date
    var numMembers: Int? = 1
    var desc: String?
    var ownerName: String
    var timeInterval: Int
    var movieEndDate: Date?
    var ownerId: String
    var isPublic: Bool
    var banner: Data?
    var bannerUrl: String?
    var numMovies: Int? = 0
    var members: [Member]?
    var movies: [Movie]?
    
    init(
        id: String? = nil,
        name: String,
        createdAt: Date = Date(),
        numMembers: Int,
        desc: String? = nil,
        ownerName: String,
        timeInterval: Int,
        ownerId: String,
        isPublic: Bool,
        banner: Data? = nil,
        bannerUrl: String? = nil,
        numMovies: Int = 0,
        members: [Member]? = nil,
        movies: [Movie]? = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.numMembers = numMembers
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
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        numMembers = try container.decode(Int.self, forKey: .numMembers)
        desc = try container.decodeIfPresent(String.self, forKey: .desc)
        ownerName = try container.decode(String.self, forKey: .ownerName)
        timeInterval = try container.decode(Int.self, forKey: .timeInterval)
        movieEndDate = try container.decode(Date.self, forKey: .movieEndDate)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
        bannerUrl = try container.decodeIfPresent(String.self, forKey: .bannerUrl)
        numMovies = try container.decode(Int.self, forKey: .numMovies)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(createdAt.timeIntervalSince1970.hashValue, forKey: .createdAt)  // Convert to timestamp
        try container.encodeIfPresent(numMembers, forKey: .numMembers)
        try container.encodeIfPresent(bannerUrl, forKey: .bannerUrl)
        try container.encodeIfPresent(desc, forKey: .desc)
        try container.encodeIfPresent(ownerId, forKey: .ownerId)
        try container.encodeIfPresent(ownerName, forKey: .ownerName)
        try container.encodeIfPresent(timeInterval, forKey: .timeInterval)
        switch isPublic {
        case true:
            try container.encode("true", forKey: .isPublic)
        case false:
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

