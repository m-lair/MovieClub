//
//  CommentView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct CommentsView: View {
    @Environment(DataManager.self) private var data: DataManager
    var movie: MovieClub.Movie?
    @State var isLoading = true
    
    var body: some View {
        if isLoading {
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        isLoading = false
                    }
                }
            
        } else {
            VStack(alignment: .leading) {
                ForEach(data.comments) { comment in
                        CommentDetailView(comment: comment)
                        
                    }
                
            }
            .onAppear {
                Task {
                    print("in featured Movie")
                    print(movie?.title)
                    if let clubID = data.currentClub?.id, let movieID = movie?.id {
                        print("movieID: \(movieID)")
                        await data.fetchComments(movieClubId: clubID, movieId: movieID)
                        
                    }
                }
            }
            
        }
    }
}

#Preview {
    CommentsView()
}
