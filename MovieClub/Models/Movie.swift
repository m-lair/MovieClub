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
    var created: Date?
    var title: String
    var poster: String?
    var avgRating: Double?
    var endDate: Date
    var userName: String
    var startDate: Date
    var userId: String
    var authorAvi: String
    var comments: [Comment]?
    var plot: String?
    var director: String?
    var releaseYear: String?

    init(id: String? = nil,
         created: Date? = nil,
         title: String,
         poster: String? = nil,
         avgRating: Double? = nil,
         startDate: Date,
         endDate: Date,
         userName: String,
         userId: String,
         authorAvi: String,
         comments: [Comment]? = nil,
         plot: String? = nil,
         director: String? = nil,
         releaseYear: String? = nil
    ) {
        self.id = id
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
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        created = try container.decodeIfPresent(Date.self, forKey: .created)
        title = try container.decode(String.self, forKey: .title)
        poster = try container.decodeIfPresent(String.self, forKey: .poster)
        avgRating = try container.decodeIfPresent(Double.self, forKey: .avgRating)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        userName = try container.decode(String.self, forKey: .userName)
        userId = try container.decode(String.self, forKey: .userId)
        authorAvi = try container.decode(String.self, forKey: .authorAvi)
        
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case created
        case title
        case poster
        case avgRating
        case endDate
        case startDate
        case userName
        case userId
        case authorAvi
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Movie, rhs: Movie) -> Bool {
       return lhs.id == rhs.id && lhs.title == rhs.title
    }
    
}
