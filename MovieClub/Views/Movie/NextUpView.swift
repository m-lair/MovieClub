//
//  NextUpView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/9/24.
//

import SwiftUI

struct NextUpView: View {
    @Environment(DataManager.self) var data: DataManager
    let movies: [Movie]
   
    var body: some View {
            ScrollView(.horizontal){
                HStack{
                    ForEach(movies) { movie in
                        let url = URL(string: movie.poster ?? "")
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .padding()
                                
                            }else {
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            }
                        }
                    }
                }
            }
            
    //        NavigationLink(destination: AddMovieView()){
    //            Text("Add Movie")
     //       }
            
        
        
    }
}

