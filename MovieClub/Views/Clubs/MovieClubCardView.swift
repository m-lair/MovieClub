//
//  MovieClubCardView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct MovieClubCardView: View {
    let movieClub: MovieClub
    @State private var screenWidth = UIScreen.main.bounds.size.width
   
    var featuredMovie: Movie? {
        // Maybe the club stores an array of movies, or a reference to a “featured” one
        movieClub.movies.first
    }
    
    var body: some View {
        ZStack {
            // Background layer for the card
            VStack {
                // 1) Try to use the club’s featuredMovie’s vertical backdrop
                if let movie = featuredMovie,
                   let verticalBackdrop = movie.apiData?.backdropHorizontal,
                   let backdropUrl = URL(string: verticalBackdrop) {
                    
                    AsyncImage(url: backdropUrl) { phase in
                        switch phase {
                        case .empty:
                            placeholderImage
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: (screenWidth - 20), maxHeight: 185)
                                .clipped()
                                
                                .mask(gradientMask)
                        case .failure:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                }
                // 3) If none of the above, show a final fallback image
                else {
                    placeholderImage
                }
            }
            .frame(width: (screenWidth - 20), height: 185)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(.white, lineWidth: 2)
            )
            .shadow(radius: 8)
            
            // Text layer
            VStack(alignment: .leading) {
                cardText.padding(.horizontal)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: (screenWidth - 20), maxHeight: 185, alignment: .bottomLeading)
        }
    }
    
    // The fallback image used in multiple spots
    var placeholderImage: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: (screenWidth - 20), maxHeight: 185)
            .clipped()
            .mask(gradientMask)
    }
    
    // The gradient mask used to fade out the bottom
    var gradientMask: some View {
        LinearGradient(
            stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: 0.85),
                .init(color: .clear, location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var cardText: some View {
        VStack(alignment: .leading) {
            if !movieClub.name.isEmpty {
                Text(movieClub.name)
                    .font(.title)
                Text("Movies: \(movieClub.numMovies ?? 0)")
                Text("Members: \(movieClub.numMembers ?? 0)")
            }
        }
    }
}
