//
//  Model.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import Foundation
import Observation
import FirebaseAuth
import UIKit
import FirebaseFirestore

@Observable
class User: Identifiable, Codable, Hashable {
    var id: String?
    var email: String
    var bio: String?
    var name: String
    var image: String?
    var clubs: [Membership]?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case bio
        case name
        case image
        case clubs
    }
    
    init(id: String? = nil, email: String, bio: String? = nil, name: String, image: String? = nil, clubs: [Membership]? = nil) {
        self.id = id
        self.email = email
        self.bio = bio
        self.name = name
        self.image = image
        self.clubs = clubs
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        name = try container.decode(String.self, forKey: .name)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        clubs = try container.decodeIfPresent([Membership].self, forKey: .clubs)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(clubs, forKey: .clubs)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

struct OMDBSearchResponse: Codable {
    let search: [APIMovie]
    let totalResults: String
    let response: String
    
    enum CodingKeys: String, CodingKey {
        case search = "Search"
        case totalResults
        case response = "Response"
    }
}

struct Membership: Codable, Identifiable, Hashable {
    @DocumentId var id: String?
    var clubId: String
    var clubName: String
    var queue: [FirestoreMovie]
    var movieDate: Date?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(clubName)
        hasher.combine(queue)
        hasher.combine(movieDate)
     
    }

}

struct Member: Codable, Identifiable, Hashable {
    @DocumentId var id: String?
    var userId: String
    var userName: String
    var userAvi: String
    var selector: Bool = true
    var movieDate: Date?
    var dateAdded: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case userName
        case userAvi
        case selector
        case movieDate
        case dateAdded
    }
}

@Observable
class Movie: Identifiable, Codable {
    var id: String?
    var created: Date?
    var title: String
    var poster: String?
    var avgRating: Double?
    var endDate: Date?
    var author: String
    var authorId: String
    var authorAvi: String
    var comments: [Comment]?
    var plot: String?
    var director: String?
    var releaseYear: String?

    enum CodingKeys: String, CodingKey {
        case id
        case created
        case title
        case poster
        case avgRating
        case endDate
        case author
        case authorId
        case authorAvi
        case comments
        case plot
        case director
        case releaseYear
    }

    init(id: String? = nil,
         created: Date? = nil,
         title: String,
         poster: String? = nil,
         avgRating: Double? = nil,
         endDate: Date?,
         author: String,
         authorId: String,
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
        self.authorId = authorId
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
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        author = try container.decode(String.self, forKey: .author)
        authorId = try container.decode(String.self, forKey: .authorId)
        authorAvi = try container.decode(String.self, forKey: .authorAvi)
        comments = try container.decodeIfPresent([Comment].self, forKey: .comments)
        plot = try container.decodeIfPresent(String.self, forKey: .plot)
        director = try container.decodeIfPresent(String.self, forKey: .director)
        releaseYear = try container.decodeIfPresent(String.self, forKey: .releaseYear)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(created, forKey: .created)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(poster, forKey: .poster)
        try container.encodeIfPresent(avgRating, forKey: .avgRating)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encode(author, forKey: .author)
        try container.encode(authorId, forKey: .authorId)
        try container.encode(authorAvi, forKey: .authorAvi)
        try container.encodeIfPresent(comments, forKey: .comments)
        try container.encodeIfPresent(plot, forKey: .plot)
        try container.encodeIfPresent(director, forKey: .director)
        try container.encodeIfPresent(releaseYear, forKey: .releaseYear)
    }
}

// Extend Movie to conform to Hashable
extension Movie: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
    }
    
    static func == (lhs: Movie, rhs: Movie) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}

struct Rating: Identifiable, Codable {
    @DocumentId var id: String?
    var userId: String
    var value: Double
}

struct APIMovie: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var title: String
    var released: String
    var director: String? = ""
    var poster: String = ""
    var plot: String? = ""
    
    static func == (lhs: APIMovie, rhs: APIMovie) -> Bool {
                return lhs.id == rhs.id && lhs.title == rhs.title
            }

    enum CodingKeys: String, CodingKey {
        case id = "imdbId"
        case title = "Title"
        case released = "Year"
        case director = "Director"
        case poster = "Poster"
        case plot = "Plot"
    }
}

struct Comment: Identifiable, Codable, Equatable, Hashable{
    @DocumentId var id: String?
    var userId: String
    var image: String? = ""
    var username: String
    var date: Date
    var text: String
    var likes: Int
    
    static func == (lhs: Comment, rhs: Comment) -> Bool {
                return lhs.id == rhs.id && lhs.username == rhs.username
            }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(userId)
        hasher.combine(image)
        hasher.combine(date)
        hasher.combine(text)
        hasher.combine(likes)
     
    }
}

struct FirestoreMovie: Identifiable, Codable, Equatable, Hashable {
    
    static func == (lhs: FirestoreMovie, rhs: FirestoreMovie) -> Bool{
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.author == rhs.author &&
        lhs.comments == rhs.comments
    }
    
    @DocumentId var id: String?
    var title: String
    var poster: String?
    var endDate: Date?
    var avgRating: Double?
    var author: String
    var authorId: String
    var authorAvi: String
    var comments: [Comment]?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(poster)
        hasher.combine(endDate)
        hasher.combine(avgRating)
        hasher.combine(author)
        hasher.combine(authorId)
        hasher.combine(authorAvi)
        hasher.combine(comments)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case poster
        case endDate
        case avgRating
        case author
        case authorId
        case authorAvi
        case comments
    }
}

@Observable
class MovieClub: Identifiable, Codable {
    var id: String?
    var name: String
    var created: Date
    var numMembers: Int
    var description: String?
    var ownerName: String
    var timeInterval: Int
    var movieEndDate: Date
    var ownerId: String
    var isPublic: Bool
    var banner: Data?
    var bannerUrl: String?
    var numMovies: Int
    var members: [Member]?
    var movies: [Movie]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case created
        case numMembers
        case description
        case ownerName
        case timeInterval
        case movieEndDate
        case ownerId
        case isPublic
        case banner
        case bannerUrl
        case numMovies
        case members
        case movies
    }

    init(id: String? = nil,
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
         movies: [Movie]? = nil) {
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

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        created = try container.decode(Date.self, forKey: .created)
        numMembers = try container.decode(Int.self, forKey: .numMembers)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        ownerName = try container.decode(String.self, forKey: .ownerName)
        timeInterval = try container.decode(Int.self, forKey: .timeInterval)
        movieEndDate = try container.decode(Date.self, forKey: .movieEndDate)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
        banner = try container.decodeIfPresent(Data.self, forKey: .banner)
        bannerUrl = try container.decodeIfPresent(String.self, forKey: .bannerUrl)
        numMovies = try container.decode(Int.self, forKey: .numMovies)
        members = try container.decodeIfPresent([Member].self, forKey: .members)
        movies = try container.decodeIfPresent([Movie].self, forKey: .movies)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(created, forKey: .created)
        try container.encode(numMembers, forKey: .numMembers)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(ownerName, forKey: .ownerName)
        try container.encode(timeInterval, forKey: .timeInterval)
        try container.encode(movieEndDate, forKey: .movieEndDate)
        try container.encode(ownerId, forKey: .ownerId)
        try container.encode(isPublic, forKey: .isPublic)
        try container.encodeIfPresent(banner, forKey: .banner)
        try container.encodeIfPresent(bannerUrl, forKey: .bannerUrl)
        try container.encode(numMovies, forKey: .numMovies)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(movies, forKey: .movies)
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







