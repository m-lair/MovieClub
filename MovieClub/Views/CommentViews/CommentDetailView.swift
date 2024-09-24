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
                VStack{
                    CircularImageView(userId: comment.userId, size: 20)
                }
                Text(comment.text)
                    .font(.body)
            }
            .task{
                let path = "/Users/profile_images/\(comment.userId)"
                //print("comment.userId \(comment.userId)")
                self.imageUrl = await data.getProfileImage(userId: comment.userId)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}
