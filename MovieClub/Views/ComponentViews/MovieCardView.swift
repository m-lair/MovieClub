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
                        .frame(width: 140, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    ProgressView()
                        .frame(width: 140, height: 200)
                }
            }
            .padding()
        }
        .frame(width: 170, height: 320)
        // 3D rotation effects
        .rotation3DEffect(
            .degrees(Double(dragOffset.width) / 8),
            axis: (x: 0, y: 1, z: 0),
            anchor: .center,
            perspective: 0.4
        )
        .rotation3DEffect(
            .degrees(-Double(dragOffset.height) / 12),
            axis: (x: 1, y: 0, z: 0),
            anchor: .center,
            perspective: 0.4
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { _ in
                    withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.6)) {
                        dragOffset = .zero
                    }
                }
        )
    }
}
