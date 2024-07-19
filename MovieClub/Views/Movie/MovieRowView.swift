//
//  MovieRow.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/6/24.
//

import SwiftUI
import Observation


struct MovieRow: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) var dismiss
    let movie: APIMovie
    @State var sheetPresented = false
    @Binding var path: NavigationPath
    var body: some View {
            HStack {
                if let poster = movie.poster, let url = URL(string: poster) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                            
                        }else {
                            ProgressView()
                                .frame(width: 100, height: 100)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text(movie.title)
                            .font(.headline)
                        Text("\(movie.released)")
                            .font(.subheadline)
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 50, height: 75)
                        .overlay(Text("No Image")
                            .foregroundColor(.white)
                            .font(.caption))
                }
                Spacer()
                //gonna change to a navlink to an add sheet or something
                
                Button(action: {
                    sheetPresented.toggle()
                    
                }) {
                    Image(systemName: "plus")
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
            }
            .sheet(isPresented: $sheetPresented, content: {
                NewMovieForm(movie: movie, path: $path)})
            .padding()
        }
    
    }
    
    
    
//}

