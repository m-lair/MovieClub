//
//  Comment.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/23/24.
//
import Foundation
import SwiftData

@Model
final class Comment: Identifiable, Codable, Hashable, Equatable {
    var id: String?
    var userId: String
    var image: String? = ""
    var userName: String
    var createdAt: Date
    var text: String
    var likes: Int
    
    init(
        id: String? = nil,
        userId: String,
        image: String? = "",
        userName: String,
        createdAt: Date,
        text: String,
        likes: Int
    ) {
        self.id = id
        self.userId = userId
        self.image = image
        self.userName = userName
        self.createdAt = createdAt
        self.text = text
        self.likes = likes
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        userName = try container.decode(String.self, forKey: .userName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        text = try container.decode(String.self, forKey: .text)
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encode(userName, forKey: .image)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case image
        case userName
        case createdAt
        case text
        case likes
    }
}
