//
//  MovieCardView.swift
//  MovieClub
//
//  Created by Marcus Lair on 2/12/25.
//

import SwiftUI
import Foundation

struct MovieCardView: View {
    let movieData: MovieAPIData
    
    @State private var dragOffset = CGSize.zero
    @State private var isRotating = false
    
    var body: some View {
        ZStack {
            // Base card with animated gradient border
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.8))
               
            // Poster image layer
            VStack {
                let posterURL = URL(string: "https://image.tmdb.org/t/p/w500\(movieData.poster)")
                AsyncImage(url: posterURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    ProgressView()
                        .frame(width: 140, height: 200)
                }
            }
        }
    }
}
