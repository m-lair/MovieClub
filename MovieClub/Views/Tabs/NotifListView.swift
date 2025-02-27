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
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack {
                ForEach(notifManager.notifications, id: \.id) { notification in
                    NavigationLink(value: notification) {
                        NotificationItemView(notification: notification)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    try await notifManager.deleteNotification(notification)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    Divider()
                }
            }
            .navigationDestination(for: Notification.self) { notification in
                switch notification.type {
                case .commented, .collected, .liked, .replied:
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
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
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

