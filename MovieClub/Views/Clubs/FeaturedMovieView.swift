//
//  FeaturedMovieView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct FeaturedMovieView: View {
    @Environment(DataManager.self) var data: DataManager
    @State var nextUpView = false
    let movie: Movie
    var body: some View {
       // let _ = print("this is the club \(data.currentClub)")
        VStack(alignment: .leading) {
                Text(movie.title)
                    .padding(.vertical)
                    .font(.title2)
                    .fontWeight(.bold)
            Text(movie.releaseYear ?? "")
                .font(.subheadline)
            HStack {
                let url = URL(string: movie.poster ?? "")
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 150)
                        
                    }else {
                        ProgressView()
                            .frame(width: 100, height: 100)
                    }
                }
                Text(movie.plot ?? "")
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    
            }
                .padding(.vertical)
            HStack{
                VStack{
                    Image(systemName: "person")
                    Text(movie.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack{
                    Image(systemName: "calendar")
                    Text("End date: \(movie.startDate.formatted(date: .numeric,  time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
        }

    }
        
}
