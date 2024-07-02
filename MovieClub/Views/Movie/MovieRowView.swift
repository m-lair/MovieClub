//
//  MovieRow.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/6/24.
//

import SwiftUI
import Observation

struct MovieRow: View {
    let movie: MovieClub.Movie
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(movie.title)
                    .font(.headline)
                Text("\(movie.startDate)")
                    .font(.subheadline)
            }
            Spacer()
            Text(String(format: "%.1f", movie.avgRating ?? 0.0))
                .font(.subheadline)
        }
        .padding()
    }
}

