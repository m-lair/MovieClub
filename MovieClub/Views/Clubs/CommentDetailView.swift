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
                    CircularImageView(userID: comment.userID, size: 20)
                }
                Text(comment.text)
                    .font(.body)
            }
            .task{
                let path = "/Users/profile_images/\(comment.userID)"
                //print("comment.userID \(comment.userID)")
                self.imageUrl = await data.getProfileImage(userID: comment.userID)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}
