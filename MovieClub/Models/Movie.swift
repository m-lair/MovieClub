//
//  MovieModel.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/23/24.
//

import Foundation
import SwiftData

@Model
final class Movie: Identifiable, Decodable, Equatable {
    var id: String?
    var imdbId: String
    var created: Date?
    var title: String
    var poster: String?
    var secPoster: String
    var avgRating: Double?
    var actors: [String]?
    var endDate: Date
    var userName: String
    var startDate: Date
    var userId: String
    var authorAvi: String
    var runtime: String?
    var comments: [Comment]?
    var plot: String
    var director: String?
    var releaseYear: String?

    init(id: String? = nil,
         imdbId: String,
         created: Date? = nil,
         title: String,
         poster: String? = nil,
         secPoster: String,
         avgRating: Double? = nil,
         startDate: Date,
         endDate: Date,
         userName: String,
         userId: String,
         authorAvi: String,
         comments: [Comment]? = nil,
         plot: String = "nil",
         director: String? = nil,
         releaseYear: String? = nil,
         runtime: String?,
         actors: [String]? = []
    ) {
        self.id = id
        self.imdbId = imdbId
        self.created = created
        self.title = title
        self.poster = poster
        self.avgRating = avgRating
        self.startDate = startDate
        self.endDate = endDate
        self.userName = userName
        self.userId = userId
        self.authorAvi = authorAvi
        self.comments = comments
        self.plot = plot
        self.director = director
        self.releaseYear = releaseYear
        self.runtime = runtime
        self.secPoster = secPoster
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        imdbId = try container.decode(String.self, forKey: .imdbId)
        created = try container.decodeIfPresent(Date.self, forKey: .created)
        title = try container.decode(String.self, forKey: .title)
        poster = try container.decodeIfPresent(String.self, forKey: .poster)
        avgRating = try container.decodeIfPresent(Double.self, forKey: .avgRating)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        userName = try container.decode(String.self, forKey: .userName)
        userId = try container.decode(String.self, forKey: .userId)
        authorAvi = try container.decode(String.self, forKey: .authorAvi)
        runtime = try container.decodeIfPresent(String.self, forKey: .runtime)
        secPoster = try container.decodeIfPresent(String.self, forKey: .secPoster) ?? ""
        actors = try container.decodeIfPresent([String].self, forKey: .actors) ?? []
        plot = try container.decodeIfPresent(String.self, forKey: .plot) ?? ""
        
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case imdbId
        case created
        case title
        case poster
        case avgRating
        case endDate
        case startDate
        case userName
        case userId
        case authorAvi
        case runtime
        case secPoster
        case actors
        case plot
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Movie, rhs: Movie) -> Bool {
       return lhs.id == rhs.id && lhs.title == rhs.title
    }
    
}
