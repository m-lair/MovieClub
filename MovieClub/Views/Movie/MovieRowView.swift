//
//  MovieRow.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/6/24.
//

import SwiftUI
import Observation
import FirebaseFirestore


struct MovieRow: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) var dismiss
    @State var movie: APIMovie
    var onSave: (APIMovie) -> Void
    
    var body: some View {
        HStack {
            if movie.poster != "" {
            let url = URL(string: movie.poster)
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
            Button {
                    onSave(movie)
                    dismiss()
                   // let _ = print("in task in movie row \(movie)")
                    //await addMovie(apiMovie: movie)
            } label: {
                Image(systemName: "plus")
                    .padding()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    //check to see if the club exists and then create it if not
}
    
    
    
//}

