//
//  MovieClubCardView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//
import UIKit
import SwiftUI

struct MovieClubCardView: View {
    let movieClub: MovieClub
    
    var featuredMovie: Movie? {
        movieClub.movies.first
    }
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.9
            let cardHeight = cardWidth * 0.6

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black)
                    .frame(width: cardWidth, height: cardHeight)
                    .shadow(color: .white.opacity(0.4), radius: 5, x: 0, y: 0)

                VStack {
                    ZStack {
                        if let movie = featuredMovie,
                           let verticalBackdrop = movie.apiData?.backdropHorizontal,
                           let backdropUrl = URL(string: verticalBackdrop) {
                            
                            CachedAsyncImage(url: backdropUrl, placeholder: {
                                // Placeholder view (e.g. black or a spinner)
                                Color.black
                            })
                            .id("\(movieClub.id ?? "")-\(movie.id ?? "")-backdrop") // Unique ID for proper refresh
                            .scaledToFill()
                            .frame(width: cardWidth - 20, height: cardHeight * 0.6)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .opacity(0.8)

                            VStack(alignment: .leading) {
                                Spacer()
                                Text(movieClub.name)
                                    .shadow(color: .black, radius: 2)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 5)

                                // Use the banner color from the model
                                Rectangle()
                                    .fill(movieClub.bannerColorForUI)
                                    .frame(width: cardWidth - 20, height: cardHeight * 0.15)
                                    .overlay(
                                        Text("Now Showing: \(movie.title) (\(movie.yearFormatted))")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                            .padding(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    )
                                    
                            }
                            .padding(.horizontal,5 )
                        } else {
                            VStack(alignment: .leading) {
                                Spacer()
                                HStack {
                                    Text(movieClub.name)
                                        .font(.headline)
                                        .shadow(color: .black, radius: 2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    Spacer()
                                }
                            }
                        }
                    }

                    Spacer()

                    HStack {
                        VStack {
                            Text("Members")
                                .font(.caption)
                            Text("\(movieClub.numMembers ?? 0)")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        VStack {
                            Text("Movies")
                                .font(.caption)
                            Text("\(movieClub.numMovies ?? 0)")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        VStack {
                            Text("Queue")
                                .font(.caption)
                            Text("\(movieClub.suggestions?.count ?? 0)")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.horizontal)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                }
                .frame(width: cardWidth, height: cardHeight)
            }
            .frame(width: geometry.size.width, height: cardHeight)
            .id("card-\(movieClub.id ?? "")-\(movieClub.numMovies ?? 0)-\(featuredMovie?.id ?? "none")")
        }
        .frame(height: UIScreen.main.bounds.width * 0.9 * 0.6)
    }
}
