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
    var imdbId: String
    var userImage: String
    var username: String
    var clubId: String
    
    init(
        id: String? = nil,
        imdbId: String,
        userImage: String,
        username: String,
        clubId: String
    ) {
        self.id = id
        self.imdbId = imdbId
        self.userImage = userImage
        self.username = username
        self.clubId = clubId
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        imdbId = try container.decode(String.self, forKey: .imdbId)
        userImage = try container.decode(String.self, forKey: .userImage)
        username = try container.decode(String.self, forKey: .username)
        clubId = try container.decode(String.self, forKey: .clubId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(imdbId, forKey: .imdbId)
        try container.encode(userImage, forKey: .userImage)
        try container.encode(username, forKey: .username)
        try container.encode(clubId, forKey: .clubId)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case imdbId
        case userImage
        case username
        case clubId
    }
}

