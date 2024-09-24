//
//  NowPlayingView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/20/24.
//

import SwiftUI

struct NowPlayingView: View {
    let movie: Movie
    let comments: [Comment]
    let club: MovieClub
    var body: some View {
        VStack{
            ScrollView {
                FeaturedMovieView(movie: movie)
                CommentsView()
            }
            CommentInputView(movieClub: club, movieId: movie.id ?? "")
                .padding(.horizontal)
        }
    }
}
