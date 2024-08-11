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

struct User: Identifiable, Codable, Hashable{
    @DocumentID var id: String?
    
    var email: String
    var bio: String? = ""
    var name: String
    var image: String? = ""
    var password: String
    var clubs: [Membership]? = []
    
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
    @DocumentID var id: String?
    var clubID: String
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
    @DocumentID var id: String?
    var userID: String
    var userName: String
    var userAvi: String
    var selector: Bool = true
    var movieDate: Date?
    var dateAdded: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID
        case userName
        case userAvi
        case selector
        case movieDate
        case dateAdded
    }
}

struct Movie: Identifiable, Codable, Hashable{
    @DocumentID var id: String? = ""
    var title: String
    var poster: String? = ""
    var avgRating: Double? = 0.0
    var endDate: Date?
    var author: String = ""
    var authorID: String = ""
    var authorAvi: String = ""
    var comments: [Comment]? = []
    var plot: String? = ""
    var director: String? = ""
    var releaseYear: String? = ""
    
    static func == (lhs: Movie, rhs: Movie) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title
    }
    
    func hash(into hasher: inout Hasher) {
        
    }
    enum CodingKeys: String, CodingKey {
        case id
        case title = "title"
        case plot = "plot"
        case endDate
        case poster = "poster"
        case comments
    }
}

struct Rating: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
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
        case id = "imdbID"
        case title = "Title"
        case released = "Year"
        case director = "Director"
        case poster = "Poster"
        case plot = "Plot"
    }
}

struct Comment: Identifiable, Codable, Equatable, Hashable{
    @DocumentID var id: String?
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
    
    @DocumentID var id: String?
    var title: String
    var poster: String?
    var endDate: Date?
    var avgRating: Double?
    var author: String
    var authorID: String
    var authorAvi: String
    var comments: [Comment]?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(poster)
        hasher.combine(endDate)
        hasher.combine(avgRating)
        hasher.combine(author)
        hasher.combine(authorID)
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
        case authorID
        case authorAvi
        case comments
    }
}

struct MovieClub: Identifiable, Codable, Hashable{
    var id: String?
    var name: String
    var created: Date
    var numMembers: Int
    var description: String? = ""
    var ownerName: String
    var timeInterval: Int
    var movieEndDate: Date
    var ownerID: String
    var isPublic: Bool
    var banner: Data?
    var bannerUrl: String?
    var numMovies: Int = 0
    var members: [Member]?
    var movies: [Movie]?
    
    static func == (lhs: MovieClub, rhs: MovieClub) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(name)
            hasher.combine(created)
            hasher.combine(numMembers)
            hasher.combine(description)
            hasher.combine(ownerName)
            hasher.combine(timeInterval)
            hasher.combine(movieEndDate)
            hasher.combine(ownerID)
            hasher.combine(isPublic)
            hasher.combine(banner)
            hasher.combine(numMovies)
            hasher.combine(members)
            hasher.combine(movies)
        }

}








