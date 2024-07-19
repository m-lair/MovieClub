//
//  CommentView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct CommentsView: View {
    @Environment(DataManager.self) private var data: DataManager
    let movie: Movie
    let clubId: String
    @State private var comments: [Comment] = []
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(comments) { comment in
                CommentDetailView(comment: comment)
                
            }
        }
        .task {
            print("in featured Movie")
            print(movie.title)
            self.comments = try! await data.fetchComments(movieClubId: clubId, movieId: movie.id ?? "")
        }
    }
}



