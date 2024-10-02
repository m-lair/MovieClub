//
//  Membership.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//
import Foundation
import SwiftData

@Model
final class Membership: Decodable, Identifiable, Hashable, Equatable {
    var id: String?
    var clubId: String
    var clubName: String
    
    init(id: String? = nil,
         clubId: String,
         clubName: String
    ) {
        self.id = id
        self.clubId = clubId
        self.clubName = clubName
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        clubId = try container.decode(String.self, forKey: .clubId)
        clubName = try container.decode(String.self, forKey: .clubName)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case clubId
        case clubName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(clubName)
    }
    
    func isEqual(to other: Membership) -> Bool {
        self.id == other.id
    }
}
