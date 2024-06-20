//
//  FeaturedMovieView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct FeaturedMovieView: View {
    @Environment(DataManager.self) var data: DataManager
    
    @State var movie: Movie?
    var body: some View {
        let _ = print("this is the club \(data.currentClub)")
        VStack(alignment: .leading) {
            if let movie = data.currentClub?.movies?[0] {
                Text(movie.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Selected By: \(movie.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Start date: \(movie.startDate) \nEnd date: \(movie.endDate)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(movie.description)
                    .font(.body)
                    .foregroundColor(.primary)
                let _ = print("movie.poster \(movie.poster)")
                let url = URL(string: movie.poster ?? "")
                let _ = print(url)
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                        
                    }else {
                        ProgressView()
                            .frame(width: 100, height: 100)
                    }
                }
                
            }
        }
        .onAppear(){
            Task{
                print("fetching poster")
                self.movie?.poster = try await data.fetchPoster(title: movie?.title ?? "")
            }
            
        }
    }
        
}
#Preview {
    FeaturedMovieView(movie: MovieClub.TestData[0].movies![0])
    
}
