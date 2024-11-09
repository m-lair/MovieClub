//
//  Member.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//
import Foundation

struct Member: Codable, Identifiable, Hashable {
    var id: String
    var userId: String
    var userName: String
    var userAvi: String
    var selector: Bool = true
    var movieDate: Date
    var dateAdded: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case userName
        case userAvi
        case selector
        case movieDate
        case dateAdded
    }
}
