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
    
    var body: some View {
        ZStack {
            // Background layer for the card, with placeholder image or blurred actual image
            VStack {
                if let url = movieClub.bannerUrl, let imageUrl = URL(string: url) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            // Placeholder while loading
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: (screenWidth - 20), maxHeight: 185)
                                .clipped()
                                .blur(radius: 1.5)
                                .mask(LinearGradient(
                                    stops: [
                                        .init(color: .white, location: 0),
                                        .init(color: .white, location: 0.85),
                                        .init(color: .clear, location: 1.0),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                        case .success(let image):
                            // Loaded image
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: (screenWidth - 20), maxHeight: 185)
                                .clipped()
                                .blur(radius: 1.5)
                                .mask(LinearGradient(
                                    stops: [
                                        .init(color: .white, location: 0),
                                        .init(color: .white, location: 0.85),
                                        .init(color: .clear, location: 1.0),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: (screenWidth - 20), maxHeight: 185)
                                .clipped()
                                .blur(radius: 1.5)
                                .mask(LinearGradient(
                                    stops: [
                                        .init(color: .white, location: 0),
                                        .init(color: .white, location: 0.85),
                                        .init(color: .clear, location: 1.0),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                        @unknown default:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: (screenWidth - 20), maxHeight: 185)
                                .clipped()
                                .blur(radius: 1.5)
                                .mask(LinearGradient(
                                    stops: [
                                        .init(color: .white, location: 0),
                                        .init(color: .white, location: 0.85),
                                        .init(color: .clear, location: 1.0),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                        }
                    }
                } else {
                    // Fallback if no banner URL
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: (screenWidth - 20), maxHeight: 185)
                        .clipped()
                        .blur(radius: 1.5)
                        .mask(LinearGradient(
                            stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white, location: 0.85),
                                .init(color: .clear, location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
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
