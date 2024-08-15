//
//  CommentDetailView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct CommentDetailView: View {
    @Environment(DataManager.self) private var data
    @State var comment: Comment
    @State var imageUrl: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                let _ = print("comment image: \(comment.image)")
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
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
        .task{
            let path = "/Users/profile_images/\(comment.userID)"
            print("comment.userID \(comment.userID)")
            self.imageUrl = await data.getProfileImage(id: comment.userID, path: path)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
}
