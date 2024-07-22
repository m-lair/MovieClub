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
    
    struct Membership: Codable, Hashable {
        @DocumentID var id: String?
        var clubID: String
        
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

struct Membership: Codable {
    @DocumentID var id: String?
    var clubID: String
    var selector: Bool = false
    var queue: [FirestoreMovie]?
    var rosterDate: Date?
}

struct Movie: Identifiable, Codable, Hashable{
    var id: String? = ""
    var title: String
    var startDate: Date
    var poster: String? = ""
    var endDate: Date
    var avgRating: Double? = 0.0
    var author: String
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
        case title = "Title"
        case plot = "Plot"
        case startDate
        case poster = "Poster"
        case endDate
        case author
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
    var poster: String? = ""
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

struct Comment: Identifiable, Codable{
    @DocumentID var id: String?
    var image: String? = ""
    var username: String
    var date: Date
    var text: String
    var likes: Int
}

struct FirestoreMovie: Identifiable, Codable {
    @DocumentID var id: String?
     var title: String
     var startDate: Date
     var poster: String?
     var endDate: Date
     var avgRating: Double?
     var author: String
     var comments: [Comment]?
}

struct MovieClub: Identifiable, Codable, Hashable{
    
   @DocumentID var id: String?
    var name: String
    var created: Date
    var numMembers: Int
    var description: String? = ""
    var ownerName: String
    var ownerID: String
    var isPublic: Bool
    var banner: String? = ""
    var numMovies: Int = 0
    var roster: [String]?
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
            hasher.combine(ownerID)
            hasher.combine(isPublic)
            hasher.combine(banner)
            hasher.combine(numMovies)
            hasher.combine(roster)
            hasher.combine(movies)
        }

}








