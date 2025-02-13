//
//  CollectionItem.swift
//  MovieClub
//
//  Created by Marcus Lair on 11/13/24.
//

import Foundation
import SwiftUICore

final class CollectionItem: Identifiable, Codable, Hashable, Equatable {
    var movieId: String?
    var colorStr: String
    var imdbId: String
    var clubId: String
    var clubName: String
    var posterUrl: String
    var collectedDate: Date?
    
    init(
        movieId: String? = nil,
        imdbId: String,
        clubId: String,
        clubName: String,
        colorStr: String,
        posterUrl: String = "",
        collectedDate: Date? = nil
    ) {
        self.movieId = movieId
        self.imdbId = imdbId
        self.clubId = clubId
        self.clubName = clubName
        self.posterUrl = posterUrl
        self.collectedDate = collectedDate
        self.colorStr = colorStr
    }

    enum CodingKeys: String, CodingKey {
        case movieId = "id"
        case colorStr
        case imdbId
        case clubId
        case clubName
        case posterUrl
        case collectedDate
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
