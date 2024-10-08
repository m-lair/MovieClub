//
//  SwiftUIView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/1/24.
//

import SwiftUI

struct BlurredBackgroundView: View {
    let urlString: String
    
    var body: some View {
        ZStack {
            Color(.black)
            let url = URL(string: urlString)
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaledToFill()
                        .blur(radius: 40) // Adjust the blur radius as needed
                        .overlay(
                            Color.black.opacity(0.3) // Semi-transparent overlay for "glass" effect
                        )
                }// Ensure the background covers the entire screen
            }
        }
    }
}

