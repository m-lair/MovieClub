//
//  APIMovie.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//
import Foundation

struct APIMovie: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var title: String
    var released: String
    var director: String? = ""
    var poster: String = ""
    var plot: String? = ""
    
    static func == (lhs: APIMovie, rhs: APIMovie) -> Bool {
                return lhs.id == rhs.id && lhs.title == rhs.title
            }

    enum CodingKeys: String, CodingKey {
        case id = "imdbId"
        case title = "Title"
        case released = "Year"
        case director = "Director"
        case poster = "Poster"
        case plot = "Plot"
    }
}
