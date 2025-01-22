//
//  Notification.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/23/24.
//

import Foundation
import SwiftUI

struct Notification: Identifiable {
    let id: UUID
    let clubName: String
    let userName: String
    let othersCount: Int?
    let message: String
    let time: String
    let type: NotificationType
}


enum NotificationType {
    case liked
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
        }
    }
}
