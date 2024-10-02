//
//  Comment.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/23/24.
//
import Foundation
import SwiftData

@Model
final class Comment: Identifiable, Decodable, Equatable, Hashable{
    var id: String?
    var userId: String
    var image: String? = ""
    var username: String
    var createdAt: Date
    var text: String
    var likes: Int
    
    init(
        id: String? = nil,
        userId: String,
        image: String? = "",
        username: String,
        createdAt: Date,
        text: String,
        likes: Int
    ) {
        self.id = id
        self.userId = userId
        self.image = image
        self.username = username
        self.createdAt = createdAt
        self.text = text
        self.likes = likes
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        username = try container.decode(String.self, forKey: .username)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        text = try container.decode(String.self, forKey: .text)
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case image
        case username
        case createdAt
        case text
        case likes
    }
    
    
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.id == rhs.id && lhs.userId == rhs.userId
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(userId)
        hasher.combine(image)
        hasher.combine(createdAt)
        hasher.combine(text)
        hasher.combine(likes)
     
    }
}
