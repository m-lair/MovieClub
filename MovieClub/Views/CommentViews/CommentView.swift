//
//  CommentView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct CommentsView: View {
    @Environment(DataManager.self) private var data: DataManager
    var body: some View {
        LazyVStack(alignment: .leading) {
            let _ = print("commments \(data.comments.count)")
            ForEach(data.comments) { comment in
                CommentDetailView(comment: comment)
                
            }
        }
        .onAppear {
            Task {
                try data.listenForComments()
            }
        }
    }
}



