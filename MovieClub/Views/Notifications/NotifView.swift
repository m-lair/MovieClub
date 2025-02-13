//
//  NotifView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/23/24.
//

import Foundation
import SwiftUI


struct NotificationItemView: View {
    let notification: Notification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            NotificationImageView(type: notification.type)

            VStack(alignment: .leading, spacing: 4) {
                Text(buildNotificationText())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(notification.createdAt .formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            Button {
                // Handle more action (e.g., dismiss or show options)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(.clear)
        .cornerRadius(10)
        .padding(.horizontal, 2)
        .navigationTitle("Notifications")
    }

    func buildNotificationText() -> String {
        if let othersCount = notification.othersCount {
            return "[\(notification.clubName)] \(notification.userName) and \(othersCount) others \(notification.message)"
        } else {
            return "[\(notification.clubName)] \(notification.message)"
        }
    }
}
