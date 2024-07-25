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
    var body: some View {
        ScrollView {
            if let movie {
                FeaturedMovieView(movie: movie)
            }
            // Comments Section
            CommentsView()
        }
    }
}
