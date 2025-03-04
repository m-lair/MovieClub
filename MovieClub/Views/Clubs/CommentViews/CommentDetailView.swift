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
    @State private var isLiked: Bool = false
    @State private var likesCount: Int = 0
    @State private var userImage: String?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Show a generic placeholder avatar for anonymized comments
            if comment.userId == "anonymous-user" {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.gray.opacity(0.1), lineWidth: 1))
            } else {
                NavigationLink(destination: ProfileDisplayView(userId: comment.userId)) {
                    if let imageUrl = userImage, let url = URL(string: imageUrl) {
                        CachedAsyncImage(url: url) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        .shadow(radius: 2)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            .shadow(radius: 2)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // For anonymized comments, don't make the username a navigation link
                    if comment.userId == "anonymous-user" {
                        Text("Deleted")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.gray)
                    } else {
                        NavigationLink(destination: ProfileDisplayView(userId: comment.userId)) {
                            Text(comment.userName)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 5, height: 5)
                    
                    TimelineView(.everyMinute) { context in
                        Text(timeAgoDisplay(referenceDate: context.date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Only show the menu for non-anonymized comments
                    if comment.userId != "anonymous-user" {
                        CommentMenuView(comment: comment)
                    }
                }
                
                if comment.userId == "anonymous-user" {
                    // Special styling for deleted comments
                    Text(comment.text)
                        .font(.body)
                        .lineLimit(10)
                        .foregroundStyle(.gray)
                        .italic()
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
                } else {
                    HStack {
                        Text(comment.text)
                            .font(.body)
                            .lineLimit(10)
                        
                        Spacer()
                        
                        // Only show like button for non-anonymized comments
                        Button {
                                Task {
                                    await toggleLike()
                                }
                        } label: {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(isLiked ? .red : .gray)
                                Text("\(likesCount)")
                                    .foregroundStyle(isLiked ? .red : .gray)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .task {
            if let user = try? await data.fetchProfile(id: comment.userId) {
                userImage = user.image
            }
        }
        .onChange(of: comment.likedBy) {
            updateLikeState()
        }
        .onAppear {
            updateLikeState()
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
    
    private func toggleLike() async {
        guard let currentUserId = data.authCurrentUser?.uid else { return }
        if isLiked {
            isLiked = false
            likesCount -= 1
            do {
                try await data.unlikeComment(commentId: comment.id, userId: currentUserId)
            } catch {
                print("Error unliking comment: \(error.localizedDescription)")
            }
        } else {
            isLiked = true
            likesCount += 1
            do {
                try await data.likeComment(commentId: comment.id, userId: currentUserId)
            } catch {
                print("Error liking comment: \(error)")
            }
        }
    }
    
    private func updateLikeState() {
        guard let currentUserID = data.currentUser?.id else { return }
        isLiked = comment.likedBy.contains(currentUserID)
        likesCount = comment.likes
    }
}
