//
//  CommentDetailView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct CommentDetailView: View {
    @Environment(DataManager.self) private var data
    let comment: Comment
    @State var imageUrl: String = ""
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    CircularImageView(userId: comment.userId, size: 20)
                    
                    Text(comment.userName)
                        .font(.headline)
                        .fontWeight(.semibold) 
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 5, height: 5)
                    
                    TimelineView(.everyMinute) { context in
                        Text(timeAgoDisplay(referenceDate: context.date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Text(comment.text)
                    .font(.body)
                    .lineLimit(0)
                    .padding(.leading, 30)
            }
            
            .task{
                do {
                    self.imageUrl = try await data.getProfileImage(userId: comment.userId) ?? ""
                } catch {
                    print(error)
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    func timeAgoDisplay(referenceDate: Date) -> String {
            let secondsAgo = Int(referenceDate.timeIntervalSince(comment.createdAt))
            
            let minute = 60
            let hour = 60 * minute
            let day = 24 * hour
            let week = 7 * day
            let month = 4 * week // Approximate month as 4 weeks
            let year = 12 * month // Approximate year as 12 months

            let quotient: Int
            let unit: String

            if secondsAgo < 0 {
                return "Just now"
            } else if secondsAgo < minute {
                quotient = secondsAgo
                unit = "s"
            } else if secondsAgo < hour {
                quotient = secondsAgo / minute
                unit = "m"
            } else if secondsAgo < day {
                quotient = secondsAgo / hour
                unit = "hr"
            } else if secondsAgo < week {
                quotient = secondsAgo / day
                unit = "d"
            } else if secondsAgo < month {
                quotient = secondsAgo / week
                unit = "w"
            } else if secondsAgo < year {
                quotient = secondsAgo / month
                unit = "mo"
            } else {
                quotient = secondsAgo / year
                unit = "yr"
            }

            return "\(quotient)\(unit) ago"
        }
}
