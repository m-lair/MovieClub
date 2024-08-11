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
        VStack(alignment: .center){
            HStack{
                Text("Selected by: ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading)
                VStack{
                    let url = URL(string: movie.authorAvi)
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                                .frame(width: 30, height: 30)
                            
                        } else {
                            ProgressView()
                                .frame(width: 100, height: 100)
                        }
                    }
                    Text(movie.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack{
                    Image(systemName: "calendar")
                    if let endDate = data.currentClub?.movieEndDate {
                        if let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -(data.currentClub?.timeInterval ?? 1), to: endDate) {
                            Text("\(startDate.formatted(date: .numeric,  time: .omitted)) - \(endDate.formatted(date: .numeric,  time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.trailing)
                        }
                    }
                }
            }
            let url = URL(string: data.poster)
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 250, height: 475)
                    
                } else {
                    ProgressView()
                        .frame(width: 100, height: 100)
                }
            }
            /*Text(movie.plot ?? "")
             .fixedSize(horizontal: false, vertical: true)
             .foregroundColor(.primary)
             .multilineTextAlignment(.leading)
             */
        }

    }
        
}
