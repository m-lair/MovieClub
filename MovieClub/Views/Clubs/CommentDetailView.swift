//
//  CommentDetailView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct CommentDetailView: View {
    var comment: MovieClub.Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                
                AsyncImage(url: URL(string: comment.image ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    case .empty:
                        Image(systemName: "person.crop.circle.fill") // Placeholder for profile image
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    case .failure(_):
                        Image(systemName: "person.crop.circle.fill") // Placeholder for profile image
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    @unknown default:
                        Image(systemName: "person.crop.circle.fill") // Placeholder for profile image
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    }
                }
                
                VStack(alignment: .leading) {
                    Text(comment.username)
                        .font(.headline)
                    Text(comment.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(comment.text)
                .font(.body)
            
            HStack {
                Text("\(comment.likes) likes")
                Spacer()
            
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    CommentDetailView(comment: MovieClub.Comment(username: "username", date: Date(), text: "hate this", likes: 10))
}
