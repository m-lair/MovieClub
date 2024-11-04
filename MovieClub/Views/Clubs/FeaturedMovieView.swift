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
        ZStack {
            // Secondary Poster in the Background
            /* AsyncImage(url: URL(string: movie.apiData.secPoster)) { phase in
             switch phase {
             case .success(let image):
             image
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
             case .empty, .failure:
             EmptyView()
             }*/
            
            VStack(alignment: .leading) {
                Spacer()
                
                Text(movie.title)
                    .font(.title)
                    .fontWeight(.heavy) +
                Text("\(movie.releaseYear)")
                    .font(.title)
                
                HStack(alignment: .top) {
                    // Primary Movie Poster
                    AsyncImage(url: URL(string: movie.poster)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 250)
                                .overlay(collected ?
                                         Rectangle().stroke(.yellow, lineWidth: 2) : nil)
                            
                        case .empty, .failure:
                            EmptyView()
                        }
                    }
                    // Details Section
                    VStack(alignment: .leading) {
                        
                        Text("Starring: ")
                            .fontWeight(.bold) +
                        Text(movie.castFormatted)
                            .font(.body)
                        
                        Text("Director: ")
                            .fontWeight(.bold) +
                        Text(movie.director)
                            .font(.body)
                        
                        Text(movie.plot)
                            .font(.body)
                        
                    }
                }
            }
        }
    }
}

