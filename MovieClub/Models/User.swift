//
//  UserModel.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/23/24.
//

import Foundation

@Observable
final class User: Identifiable, Decodable {
    var id: String?
    var email: String
    var bio: String?
    var name: String
    var image: String?
    var clubs: [Membership]?
    
    init(
        id: String? = nil,
        email: String,
        bio: String? = nil,
        name: String,
        image: String? = nil,
        clubs: [Membership]? = nil
    ) {
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
        image = try container.decodeIfPresent(String.self, forKey: .image)
        clubs = try container.decodeIfPresent([Membership].self, forKey: .clubs)
        name = try container.decode(String.self, forKey: .name)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case bio
        case name
        case image
        case clubs
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}