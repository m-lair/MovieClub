//
//  Announcement.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/29/24.
//

import Foundation
import SwiftUI

struct Announcement: Identifiable {
    let id: UUID
    let title: String
    let body: String
    let date: Date
    let likes: Int
    let userName: String
}
