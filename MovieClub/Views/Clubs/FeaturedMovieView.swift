//
//  FeaturedMovieView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct FeaturedMovieView: View {
    @Environment(DataManager.self) var data: DataManager
    let movieTitle: String
    let details: String
    let primaryPoster: Image
    let secondaryPoster: Image
    let releaseYear: String
    let collected: Bool
    
    
    @State private var width = UIScreen.main.bounds.width
    @State private var showFullDetails = false
    
    var body: some View {
        ZStack {
            // Secondary Poster in the Background
            secondaryPoster
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width + 2, height: 510, alignment: .center)
                .opacity(0.7)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.black, .clear]),
                        startPoint: .bottom,
                        endPoint: .top
                        )
                    )
                
            VStack(alignment: .leading) {
                Spacer()
                
                Text(movieTitle)
                    .font(.title)
                    .fontWeight(.heavy) +
                Text(" (\(releaseYear))")
                    .font(.title)
                
                HStack(alignment: .top) {
                    // Primary Movie Poster
                    primaryPoster
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 250)
                        .overlay(collected ?
                                 Rectangle().stroke(.yellow, lineWidth: 2) : nil)
                    
                      
                    
                    // Details Section
                    VStack(alignment: .leading) {
                        Text("Starring: ")
                            .fontWeight(.bold)
                        Text("Director: ")
                            .fontWeight(.bold)
                            .padding(.bottom)
                        
                        Text(details)
                            .font(.body)
                        
                    }
                }
            }
        }
    }
}
