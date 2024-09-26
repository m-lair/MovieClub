//
//  Membership.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//
import Foundation

struct Membership: Codable, Identifiable, Hashable {
    var id: String?
    var clubId: String
    var clubName: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(clubName)
    }
}
