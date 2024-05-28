//
//  MovieRow.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/6/24.
//

import SwiftUI
import Observation

struct MovieRow: View {
    let movie: Movie
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(movie.title)
                    .font(.headline)
                Text("\(movie.date)")
                    .font(.subheadline)
            }
            Spacer()
            Text(String(format: "%.1f", movie.rating))
                .font(.subheadline)
        }
        .padding()
    }
}

