//
//  FeaturedMovieView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct FeaturedMovieView: View {
    @Environment(DataManager.self) var data: DataManager
    let collected: Bool
    let movie: Movie
    
    @State private var width = UIScreen.main.bounds.width
    @State private var showFullDetails = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // MARK: - Background Image (Vertical Backdrop)
            if let verticalBackdrop = movie.apiData?.backdropVertical,
               let url = URL(string: verticalBackdrop) {
                CachedAsyncImage(url: url, placeholder: {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: width, height: 510)
                })
                .scaledToFill()
                .frame(width: width, height: 510)
                .clipped()
            }
            
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(1.0), .clear]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(width: width, height: 510)
            .allowsHitTesting(false)
            
            // MARK: - Foreground Content
            // Poster on the left, text on the right
            HStack(alignment: .top, spacing: 16) {
                
                // Poster
                CachedAsyncImage(url: URL(string: movie.poster), placeholder:  {
                    Color.gray
                        .frame(width: 130, height: 190)
                        .cornerRadius(8)
                })
                .aspectRatio(contentMode: .fit)
                .frame(width: 130, height: 190)
                .cornerRadius(8)
                .overlay(collected ?
                         Rectangle().stroke(.yellow, lineWidth: 2) : nil)
                
                // Text Stack
                VStack(alignment: .leading, spacing: 8) {
                    
                    // Title + Year
                    (Text(movie.title)
                        .font(.title)
                        .fontWeight(.heavy)
                     + Text(" (\(movie.yearFormatted))")
                        .font(.title)
                    )
                    .foregroundColor(.white)
                    
                    // Cast
                    HStack(alignment: .top, spacing: 4) {
                        Text("Starring:")
                            .fontWeight(.bold)
                        Text(movie.castFormatted)
                            .lineLimit(2)            // Limit lines
                            .truncationMode(.tail)   // Truncate with "..."
                    }
                    .foregroundColor(.white)
                    
                    // Director
                    HStack(alignment: .top, spacing: 4) {
                        Text("Director:")
                            .fontWeight(.bold)
                        Text(movie.director)
                    }
                    .foregroundColor(.white)
                    
                    // Plot
                    Text(movie.plot)
                        .font(.callout)
                        .lineLimit(4)
                        .truncationMode(.tail)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: width, height: 510)
    }
}
