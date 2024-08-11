//
//  NowPlayingView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/20/24.
//

import SwiftUI

struct NowPlayingView: View {
    let movie: Movie?
    let comments: [Comment]
    let club: MovieClub
    var body: some View {
        VStack{
            ScrollView {
                if let movie {
                    FeaturedMovieView(movie: movie)
                }
                // Comments Section
                CommentsView()
                
            }
            CommentInputView(movieClub: club, movieID: movie?.id ?? "")
                .padding(.horizontal)
        }
    }
}
