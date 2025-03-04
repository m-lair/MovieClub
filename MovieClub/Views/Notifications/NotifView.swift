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
            Image(systemName: notification.type.iconName)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(notification.type.iconColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(getNotificationTitle())
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                if let othersCount = notification.othersCount, othersCount > 0 {
                    Text("\(notification.userName) and \(othersCount) others")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .padding(.leading, 2)

            Spacer()

            Text(formattedTime())
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 3)
        }
        .padding(.vertical, 8)
    }
    
    private func getNotificationTitle() -> String {
        switch notification.type {
        case .commented:
            return "New comment"
        case .replied:
            return "New reply"
        case .liked:
            return "New like"
        case .collected:
            return "Movie collected"
        case .suggestion:
            return "New suggestion"
        case .joined:
            return "New member"
        }
    }
    
    private func formattedTime() -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(notification.createdAt) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: notification.createdAt)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: notification.createdAt)
        }
    }
}
