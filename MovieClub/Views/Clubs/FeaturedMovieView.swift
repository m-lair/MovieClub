//
//  FeaturedMovieView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct FeaturedMovieView: View {
    @Environment(DataManager.self) var data: DataManager
    
    @State var movie: MovieClub.Movie?
    var body: some View {
       // let _ = print("this is the club \(data.currentClub)")
        VStack(alignment: .leading) {
            if let movie = movie {
                Text(movie.title)
                    .font(.title2)
                    .fontWeight(.bold)
                HStack {
                    let url = URL(string: movie.poster ?? "")
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
                    Text(movie.plot ?? "")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    
                }
                HStack{
                    Image(systemName: "person")
                    Text("Selected By: \(movie.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    Image(systemName: "calendar")
                    Text("End date: \(movie.endDate.formatted())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    
                    
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
