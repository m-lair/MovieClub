//
//  OMDBSearchResponse.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//
import Foundation

struct OMDBSearchResponse: Codable {
    let search: [APIMovie]
    let totalResults: String
    let response: String
    
    enum CodingKeys: String, CodingKey {
        case search = "Search"
        case totalResults
        case response = "Response"
    }
}
