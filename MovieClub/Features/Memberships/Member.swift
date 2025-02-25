//
//  Member.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//
import Foundation
import FirebaseFirestore

struct Member: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var userName: String
    var image: String? = ""
    var selector: Bool? = true
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userName = "username"
        case image
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        userName = try container.decode(String.self, forKey: .userName)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        if let timestamp = try? container.decode(Int.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: TimeInterval(timestamp)) // Convert Firestore Timestamp to Swift Date
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        selector = true
    }
}
