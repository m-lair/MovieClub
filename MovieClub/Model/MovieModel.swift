//
//  MovieModel.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/23/24.
//

import Foundation

@Observable
final class Movie: Identifiable, Codable {
    var id: String?
    var created: Date?
    var title: String
    var poster: String?
    var avgRating: Double?
    var endDate: Date?
    var author: String
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
         endDate: Date?,
         author: String,
         userId: String,
         authorAvi: String,
         comments: [Comment]? = nil,
         plot: String? = nil,
         director: String? = nil,
         releaseYear: String? = nil) {
        self.id = id
        self.created = created
        self.title = title
        self.poster = poster
        self.avgRating = avgRating
        self.endDate = endDate
        self.author = author
        self.userId = userId
        self.authorAvi = authorAvi
        self.comments = comments
        self.plot = plot
        self.director = director
        self.releaseYear = releaseYear
    }
}

// Extend Movie to conform to Hashable
extension Movie: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Movie, rhs: Movie) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}
