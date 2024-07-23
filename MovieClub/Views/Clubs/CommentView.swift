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
        VStack(alignment: .leading) {
            ForEach(data.comments) { comment in
                CommentDetailView(comment: comment)
                
            }
        }
    }
}



