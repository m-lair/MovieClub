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
                .id("backdrop-\(movie.id ?? "unknown")")
                .transition(.opacity)
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
                .cornerRadius(8)
                .overlay(
                    // 1) The border animation
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 4)
                        .fill(collected ? Color.yellow : Color.clear)
                        .mask(
                            Rectangle()
                                .fill(collected ? Color.white : Color.clear)
                                .offset(y: collected ? 0 : 250)
                                .frame(width: 140, height: 200)
                        )
                        .animation(.easeInOut(duration: 0.5), value: collected)
                )
                .frame(width: 130, height: 190)
                .id("poster-\(movie.id ?? "unknown")")
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                
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
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    
                    // Cast
                    HStack(alignment: .top, spacing: 4) {
                        Text("Starring:")
                            .fontWeight(.bold)
                        Text(movie.castFormatted)
                            .lineLimit(2)            // Limit lines
                            .truncationMode(.tail)   // Truncate with "..."
                    }
                    .foregroundColor(.white)
                    .transition(.opacity)
                    
                    // Director
                    HStack(alignment: .top, spacing: 4) {
                        Text("Director:")
                            .fontWeight(.bold)
                        Text(movie.director)
                    }
                    .foregroundColor(.white)
                    .transition(.opacity)
                    
                    // Plot
                    Text(movie.plot)
                        .lineLimit(4)
                        .truncationMode(.tail)
                        .foregroundColor(.white)
                        .transition(.opacity)
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: width, height: 510)
        .animation(.easeInOut, value: movie.id)
    }
}
