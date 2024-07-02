//
//  MovieDetailView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/6/24.
//

import SwiftUI


struct MovieDetailView: View {
    // add view to edit
    var movie: MovieClub.Movie
    var body: some View {
        VStack {
            Text(movie.title)
                .font(.title)
            Text("\(movie.startDate)")
                .font(.subheadline)
            Text("Rating: \(String(format: "%.1f", movie.avgRating ?? 0.0))")
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .navigationTitle(movie.title)
    }
}
