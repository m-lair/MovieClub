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
    var created: Date
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
        created: Date = Date(),
        desc: String? = nil,
        ownerName: String,
        timeInterval: Int,
        ownerId: String,
        isPublic: Bool,
        banner: Data? = nil,
        bannerUrl: String? = nil,
        numMovies: Int = 0,
        members: [Member]? = nil,
        movies: [Movie] = []
    ) {
        self.id = id
        self.name = name
        self.created = created
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
        created = try container.decode(Date.self, forKey: .created)
        numMembers = try container.decode(Int.self, forKey: .numMembers)
        desc = try container.decodeIfPresent(String.self, forKey: .desc)
        ownerName = try container.decode(String.self, forKey: .ownerName)
        timeInterval = try container.decode(Int.self, forKey: .timeInterval)
        movieEndDate = try container.decode(Date.self, forKey: .movieEndDate)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
        bannerUrl = try container.decodeIfPresent(String.self, forKey: .bannerUrl)
        numMovies = try container.decode(Int.self, forKey: .numMovies)
        movies = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(created, forKey: .created)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case created
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

