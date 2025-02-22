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
    @State var navPath: NavigationPath = NavigationPath()
    @Environment(DataManager.self) var data

    var body: some View {
        ScrollView {
            VStack {
                ForEach(notifManager.notifications, id: \.id) { notification in
                    NavigationLink(value: notification) {
                        NotificationItemView(notification: notification)
                    }
                    Divider()
                }
            }
            .navigationDestination(for: Notification.self) { notification in
                switch notification.type {
                case .commented:
                    if let club = data.userClubs.first(where: { $0.id == notification.clubId }) {
                        ClubDetailView(navPath: $navPath, club: club)
                            .navigationTitle(club.name)
                            .navigationBarTitleDisplayMode(.inline)
                    } else {
                        Text("Club not found")
                    }
                    
                default:
                    EmptyView()
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

