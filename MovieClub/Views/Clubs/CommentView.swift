//
//  CommentView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct CommentsView: View {
    @Environment(DataManager.self) private var data: DataManager
    let comments: [Comment]
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(comments) { comment in
                CommentDetailView(comment: comment)
                
            }
        }
    }
}



