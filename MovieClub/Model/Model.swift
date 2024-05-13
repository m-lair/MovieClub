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
    
}

struct MovieClub {
   @DocumentID var id: String?
    var name: String
    var owner: String
    var members: [User]
    var movies: [Movie]
}

struct Movie: Identifiable, Codable{
   @DocumentID var id: String?
    var title: String
    var date: Date
    var rating: Double
    var author: String
    
}
