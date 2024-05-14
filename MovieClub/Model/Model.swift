//
//  Model.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import Foundation
import Observation
import FirebaseAuth
import FirebaseFirestore

struct User: Identifiable, Codable{
   @DocumentID var id: String?
    var email: String
    var name: String
    var password: String
    var clubs: [Membership]?
    
}

struct Membership: Codable {
    @DocumentID var id: String?
    var clubID: String
}

struct MovieClub: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var ownerName: String
    var ownerID: String
    var isPublic: Bool
    var members: [User]?
    var movies: [Movie]?
}

struct Movie: Identifiable, Codable{
   @DocumentID var id: String?
    var title: String
    var date: Date
    var rating: Double
    var author: String
    
}

struct Review {
    var rating: Int // Can also be enum
    var userID: String
    var username: String
    var text: String
    var date: Date
    
}


