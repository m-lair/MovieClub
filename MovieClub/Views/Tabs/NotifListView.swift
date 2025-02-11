//
//  NotifListView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/23/24.
//

import Foundation
import SwiftUI

struct NotificationListView: View {
    @Environment(NotificationManager.self) var notifManager

    var body: some View {
        ScrollView {
            VStack {
                ForEach(notifManager.notifications, id: \.id) { notification in
                    NotificationItemView(notification: notification)
                    Divider()
                }
                
            }
        }
        .refreshable {
            await notifManager.fetchUserNotifications()
        }
        .navigationTitle("Notifications")
        .task {
            await notifManager.fetchUserNotifications()
        }
    }
}

