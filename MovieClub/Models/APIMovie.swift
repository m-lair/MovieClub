//
//  APIMovie.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//
import Foundation

struct APIMovie: Codable, Equatable, Hashable {
    
    // MARK: - API Response Types
    let imdbId: String
    let title: String
    let plot: String
    let poster: String
    let year: String
    let runtime: String
    let secPoster: String
    let director: String
    let actors: String
    
    init(
        imdbId: String,
        title: String,
        plot: String,
        poster: String,
        year: String,
        runtime: String,
        secPoster: String,
        director: String,
        actors: String
    ) {
        self.imdbId = imdbId
        self.title = title
        self.plot = plot
        self.poster = poster
        self.year = year
        self.runtime = runtime
        self.secPoster = secPoster
        self.director = director
        self.actors = actors
    }
    
    init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imdbId = try container.decode(String.self, forKey: .imdbId)
        title = try container.decode(String.self, forKey: .title)
        plot = try container.decodeIfPresent(String.self, forKey: .plot) ?? ""
        runtime = try container.decodeIfPresent(String.self, forKey: .runtime) ?? ""
        secPoster = try container.decodeIfPresent(String.self, forKey: .secPoster) ?? ""
        poster = try container.decodeIfPresent(String.self, forKey: .poster) ?? ""
        year = try container.decode(String.self, forKey: .year)
        director = try container.decode(String.self, forKey: .director)
        actors = try container.decode(String.self, forKey: .actors)
    }
    
    enum CodingKeys: String, CodingKey {
        case imdbId = "imdbID"
        case title = "Title"
        case plot = "Plot"
        case poster = "Poster"
        case year = "Year"
        case runtime = "Runtime"
        case director = "Director"
        case actors = "Actors"
        case secPoster = "SecPoster"
    }
}

