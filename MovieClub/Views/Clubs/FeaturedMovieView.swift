//
//  FeaturedMovieView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct FeaturedMovieView: View {
    var movie: Movie?

    var body: some View {
        VStack(alignment: .leading) {
            if let movie = movie {
                Text(movie.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Selected By: \(movie.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Start date: \(movie.startDate) \nEnd date: \(movie.endDate)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(movie.description)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Image(systemName: "film") // Placeholder for movie image
                    .resizable()
                    .frame(height: 200)
                    .scaledToFit()
                    .cornerRadius(8)
            }
        }
    }
}
#Preview {
    FeaturedMovieView()
}
