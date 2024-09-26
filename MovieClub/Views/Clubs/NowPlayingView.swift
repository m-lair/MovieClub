//
//  NowPlayingView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/20/24.
//

import SwiftUI

struct NowPlayingView: View {
    @Environment(DataManager.self) private var data: DataManager
    let movie: Movie
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
