//
//  NotifListView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/23/24.
//

import Foundation
import SwiftUI

struct NotificationListView: View {
    let notifications: [Notification] = [
        Notification(id: UUID(), clubName: "FMFC", userName: "marcus", othersCount: nil, message: "liked your comment.", time: "00:00 AM", type: .liked),
        Notification(id: UUID(), clubName: "Horror Club", userName: "robbie", othersCount: 2, message: "liked your comment.", time: "06:30 PM", type: .liked),
        Notification(id: UUID(), clubName: "Marvel Club", userName: "nathan123", othersCount: nil, message: "replied to your comment.", time: "2:00 PM", type: .replied),
        Notification(id: UUID(), clubName: "CLUB", userName: "user1234556", othersCount: nil, message: "collected your movie poster.", time: "12:00 AM", type: .collected),
        Notification(id: UUID(), clubName: "FMFC", userName: "marcus", othersCount: nil, message: "liked your comment.", time: "00:00 AM", type: .liked),
        Notification(id: UUID(), clubName: "Horror Club", userName: "robbie", othersCount: 2, message: "liked your comment.", time: "06:30 PM", type: .liked),
        Notification(id: UUID(), clubName: "Marvel Club", userName: "nathan123", othersCount: nil, message: "replied to your comment.", time: "2:00 PM", type: .replied),
        Notification(id: UUID(), clubName: "CLUB", userName: "user1234556", othersCount: nil, message: "collected your movie poster.", time: "12:00 AM", type: .collected)
        // Add more sample data as needed
    ]

    var body: some View {
        ScrollView {
            VStack {
                ForEach(notifications) { notification in
                    NotificationView(notification: notification)
                    Divider()
                }
            }
        }
    }
}

