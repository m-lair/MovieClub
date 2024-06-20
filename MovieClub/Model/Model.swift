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
    var name: String
    var image: String?
    var password: String
    var clubs: [Membership]?
}
    /*
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case imageData
        case password
    }
     
    
    init(id: String? = nil, name: String, email: String, image: UIImage? = nil, password: String) {
        self.id = id
        self.name = name
        self.email = email
        self.image = image
        self.password = password
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(password, forKey: .password)
        if let imageData = image?.jpegData(compressionQuality: 1.0) {
            try container.encode(imageData, forKey: .imageData)
        }
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        if let imageData = try container.decodeIfPresent(Data.self, forKey: .imageData) {
            image = UIImage(data: imageData)
        } else {
            image = nil
        }
        password = try container.decode(String.self, forKey: .password)
    }*/
    


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
    var numMovies: Int = 0
    var members: [User]?
    var movies: [Movie]?
    
}

struct Movie: Identifiable, Codable{
   @DocumentID var id: String?
    var title: String
    var description: String
    var startDate: Date
    var poster: String?
    var endDate: Date
    var avgRating: Double?
    var rating: [Rating]?
    var author: String
    var comments: [Comment]?
    
}

struct Rating: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
    var value: Double
}

struct Comment: Identifiable, Codable{
    @DocumentID var id: String?
    var image: String?
    var username: String
    var date: Date
    var text: String
    var likes: Int
}


