//
//  Model.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import Foundation
import Observation
import FirebaseAuth
import UIKit
import FirebaseFirestore
import SwiftUI


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

struct Membership: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var clubId: String
    var clubName: String
    var movieDate: Date?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(clubName)
        hasher.combine(movieDate)
    }
}

struct Member: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var userId: String
    var userName: String
    var userAvi: String
    var selector: Bool = true
    var movieDate: Date?
    var dateAdded: Date?
    
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








