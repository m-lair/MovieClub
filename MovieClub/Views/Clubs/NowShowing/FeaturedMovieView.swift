//
//  FeaturedMovieView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

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
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            // If you want it behind the nav bar, uncomment:
                            // .ignoresSafeArea(edges: .top)
                            .frame(width: width, height: 510)
                            .clipped()
                    default:
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: width, height: 510)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: width, height: 510)
            }
            
            // MARK: - Gradient Overlay (optional)
            // (helps readability if the backdrop is bright)
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.6), .clear]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(width: width, height: 510)
            .allowsHitTesting(false)
            
            // MARK: - Foreground Content
            // Poster on the left, text on the right
            HStack(alignment: .top, spacing: 16) {
                
                // Poster
                AsyncImage(url: URL(string: movie.poster)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 130, height: 190)
                            .cornerRadius(8)
                            .overlay(collected ?
                                     Rectangle().stroke(.yellow, lineWidth: 2) : nil)
                    case .empty, .failure:
                        Color.gray
                            .frame(width: 130, height: 190)
                            .cornerRadius(8)
                    }
                }
                
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
