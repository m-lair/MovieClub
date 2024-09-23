//
//  ClubModel.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/23/24.
//

import Foundation

@Observable
final class MovieClub: Identifiable, Codable {
    var id: String?
    var name: String
    var created: Date
    var numMembers: Int? = 1
    var description: String?
    var ownerName: String
    var timeInterval: Int
    var movieEndDate: Date
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
        created: Date = Date(),
        numMembers: Int,
        description: String? = nil,
        ownerName: String,
        timeInterval: Int,
        movieEndDate: Date,
        ownerId: String,
        isPublic: Bool,
        banner: Data? = nil,
        bannerUrl: String? = nil,
        numMovies: Int = 0,
        members: [Member]? = nil,
        movies: [Movie]? = nil
    ) {
        self.id = id
        self.name = name
        self.created = created
        self.numMembers = numMembers
        self.description = description
        self.ownerName = ownerName
        self.timeInterval = timeInterval
        self.movieEndDate = movieEndDate
        self.ownerId = ownerId
        self.isPublic = isPublic
        self.banner = banner
        self.bannerUrl = bannerUrl
        self.numMovies = numMovies
        self.members = members
        self.movies = movies
    }
}

// Extend MovieClub to conform to Hashable
extension MovieClub: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MovieClub, rhs: MovieClub) -> Bool {
        lhs.id == rhs.id
    }
}

