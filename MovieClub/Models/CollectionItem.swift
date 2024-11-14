//
//  CollectionItem.swift
//  MovieClub
//
//  Created by Marcus Lair on 11/13/24.
//

import Foundation
import SwiftUICore

final class CollectionItem: Identifiable, Codable, Hashable, Equatable {
    var id: String?
    var colorStr: String
    var imdbId: String
    var clubId: String
    var clubName: String
    var posterUrl: String
    
    init(
        id: String? = nil,
        imdbId: String,
        clubId: String,
        clubName: String,
        colorStr: String,
        posterUrl: String = ""
    ) {
        self.id = id
        self.imdbId = imdbId
        self.clubId = clubId
        self.clubName = clubName
        self.posterUrl = posterUrl
        self.colorStr = colorStr
    }

    enum CodingKeys: String, CodingKey {
        case id
        case colorStr
        case imdbId
        case clubId
        case clubName
        case posterUrl
    }
    
    var color: Color {
        switch colorStr {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        default: return .black
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CollectionItem, rhs: CollectionItem) -> Bool {
        lhs.id == rhs.id
    }
}
