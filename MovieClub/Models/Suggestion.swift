//
//  Suggestion.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/14/24.
//

import Foundation
import SwiftData

@Model
final class Suggestion: Identifiable, Codable {
    var id: String?
    var title: String
    var userImage: String
    var username: String
    
    init(
        id: String? = nil,
        title: String,
        userImage: String,
        username: String
    ) {
        self.id = id
        self.title = title
        self.userImage = userImage
        self.username = username
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        userImage = try container.decode(String.self, forKey: .userImage)
        username = try container.decode(String.self, forKey: .username)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(userImage, forKey: .userImage)
        try container.encode(username, forKey: .username)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case userImage
        case username
    }
}
