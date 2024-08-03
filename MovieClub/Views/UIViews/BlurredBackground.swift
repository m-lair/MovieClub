//
//  SwiftUIView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/1/24.
//

import SwiftUI

struct BlurredBackgroundView: View {
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
            
            Image("matrixPoster") // Replace with your image name
                .resizable()
                .scaledToFill()
                .blur(radius: 40) // Adjust the blur radius as needed
                .overlay(
                    Color.black.opacity(0.3) // Semi-transparent overlay for "glass" effect
                )
                .ignoresSafeArea() // Ensure the background covers the entire screen
        }
    }
}
#Preview {
    BlurredBackgroundView()
}
