//
//  Suggestion.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/14/24.
//

import Foundation
import SwiftData

final class Suggestion: Identifiable, Codable {
    var id: String?
    var imdbId: String
    var userImage: String
    var userName: String
    var userId: String
    var clubId: String?
    
    init(
        id: String? = nil,
        imdbId: String,
        userId: String,
        userImage: String = "",
        userName: String,
        clubId: String = ""
    ) {
        self.id = id
        self.imdbId = imdbId
        self.userImage = userImage
        self.userName = userName
        self.clubId = clubId
        self.userId = userId
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        imdbId = try container.decode(String.self, forKey: .imdbId)
        userImage = try container.decode(String.self, forKey: .userImage)
        userName = try container.decode(String.self, forKey: .userName)
        userId = try container.decode(String.self, forKey: .userId)
        clubId = try container.decode(String.self, forKey: .clubId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(imdbId, forKey: .imdbId)
        try container.encode(userImage, forKey: .userImage)
        try container.encode(userName, forKey: .userName)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(clubId, forKey: .clubId)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case imdbId
        case userImage
        case userName
        case userId
        case clubId
    }
}

