//
//  Comment.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/23/24.
//
import Foundation
import Observation

@Observable
final class Comment: Identifiable, Codable, Hashable, Equatable {
    var id: String
    var userId: String
    var image: String? = ""
    var userName: String
    var createdAt: Date
    var text: String
    var likes: Int
    var parentId: String?
    var likedBy: [String] = []
    
    init(
        id: String,
        userId: String,
        image: String? = "",
        userName: String,
        createdAt: Date,
        text: String,
        likes: Int,
        parentId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.image = image
        self.userName = userName
        self.createdAt = createdAt
        self.text = text
        self.likes = likes
        self.parentId = parentId
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = ""
        userId = try container.decode(String.self, forKey: .userId)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        userName = try container.decode(String.self, forKey: .userName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        text = try container.decode(String.self, forKey: .text)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        likedBy = try container.decodeIfPresent([String].self, forKey: .likedBy) ?? []

        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encode(userName, forKey: .image)
        try container.encode(parentId, forKey: .parentId)
    }
    
    func hash(into hasher: inout Hasher) {
             hasher.combine(id)
         }

         static func == (lhs: Comment, rhs: Comment) -> Bool {
             lhs.id == rhs.id
         }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case image
        case userName
        case createdAt
        case text
        case likes
        case parentId
        case likedBy
    }
}

@Observable
class CommentNode: Identifiable, Equatable {
    static func == (lhs: CommentNode, rhs: CommentNode) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String
    var comment: Comment
    var replies: [CommentNode] = []
    
    init(comment: Comment) {
        self.id = comment.id
        self.comment = comment
    }
}
