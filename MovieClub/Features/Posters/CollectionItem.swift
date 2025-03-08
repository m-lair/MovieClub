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
    var revealDate: Date?
    var likes: Int?
    var dislikes: Int?
    var collections: Int?
    
    init(
        movieId: String? = nil,
        imdbId: String,
        clubId: String,
        clubName: String,
        colorStr: String,
        posterUrl: String = "",
        collectedDate: Date? = nil,
        revealDate: Date? = nil,
        likes: Int = 0,
        dislikes: Int = 0,
        collections: Int = 0
    ) {
        self.movieId = movieId
        self.imdbId = imdbId
        self.clubId = clubId
        self.clubName = clubName
        self.posterUrl = posterUrl
        self.collectedDate = collectedDate
        self.revealDate = revealDate
        self.colorStr = colorStr
        self.likes = likes
        self.dislikes = dislikes
        self.collections = collections
    }

    enum CodingKeys: String, CodingKey {
        case movieId = "id"
        case colorStr
        case imdbId
        case clubId
        case clubName
        case posterUrl
        case collectedDate
        case revealDate
    }
    
    var color: Color {
        switch colorStr {
        case "neutral":
            return Color(red: 0.6, green: 0.6, blue: 0.6) // Medium gray
        case "negative":
            return Color(red: 0.8, green: 0.2, blue: 0.2) // Deep red
        case "mixed":
            return Color(red: 0.9, green: 0.6, blue: 0.2) // Orange
        case "balanced":
            return Color(red: 0.9, green: 0.8, blue: 0.2) // Yellow
        case "positive":
            return Color(red: 0.2, green: 0.7, blue: 0.3) // Green
        case "verygood":
            return Color(red: 0.2, green: 0.5, blue: 0.8) // Blue
        case "excellent":
            return Color(red: 0.5, green: 0.2, blue: 0.8) // Purple
        // Keep backward compatibility with old color strings
        default: return Color(red: 0.2, green: 0.2, blue: 0.2) // Dark gray for unknown
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CollectionItem, rhs: CollectionItem) -> Bool {
        lhs.id == rhs.id
    }
}
