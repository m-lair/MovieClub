//
//  Notification.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/23/24.
//

import Foundation
import FirebaseFirestore
import SwiftUI

struct Notification: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let clubName: String
    let clubId: String
    let userName: String
    let userId: String
    let othersCount: Int?
    let message: String
    let createdAt: Date
    let type: NotificationType
}

enum NotificationType: String, Codable {
    case liked
    case commented
    case replied
    case collected

    var iconName: String {
        switch self {
        case .liked:
            return "heart.fill"
        case .replied:
            return "arrowshape.turn.up.left.fill"
        case .collected:
            return "square.and.arrow.down.fill"
        case .commented:
            return "bubble.left.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .liked:
            return .red
        case .replied:
            return .blue
        case .collected:
            return .yellow
        case .commented:
            return .gray
        }
    }
}
