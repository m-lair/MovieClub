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

struct User: Identifiable, Codable{
    @DocumentID var id: String?
    
    var email: String
    var bio: String?
    var name: String
    var image: String?
    var password: String
    var clubs: [Membership]?
    
    
    struct Membership: Codable {
        @DocumentID var id: String?
        var clubID: String
    }
}

struct OMDBSearchResponse: Codable {
    let search: [MovieClub.APIMovie]
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
}

struct MovieClub: Identifiable, Codable {
   @DocumentID var id: String?
    var name: String
    var created: Date
    var numMembers: Int
    var description: String? = ""
    var ownerName: String
    var ownerID: String
    var isPublic: Bool
    var poster: String?
    var numMovies: Int = 0
    var members: [User]?
    var movies: [Movie]?
    
    
    struct Movie: Identifiable, Codable, Equatable{
        @DocumentID var id: String?
        var title: String
        var startDate: Date
        var poster: String?
        var endDate: Date
        var avgRating: Double?
        var author: String
        var comments: [Comment]?
        var plot: String?
        var director: String?
        var releaseYear: String?
        
        static func == (lhs: Movie, rhs: Movie) -> Bool {
                    return lhs.id == rhs.id && lhs.title == rhs.title
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
        
        struct Comment: Identifiable, Codable{
            @DocumentID var id: String?
            var image: String?
            var username: String
            var date: Date
            var text: String
            var likes: Int
        }
        
        struct Rating: Identifiable, Codable {
            @DocumentID var id: String?
            var userID: String
            var value: Double
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
    struct APIMovie: Codable, Equatable, Hashable, Identifiable {
        var id: String
        var title: String
        var released: String
        var director: String?
        var poster: String?
        var plot: String?
        
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

        
        
       
    
    
    
    
    
    
    
    
}







