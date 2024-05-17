//
//  MovieClubCardView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct MovieClubCardView: View {
    var movieClub: MovieClub
    
    var body: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 25.0)
                .fill(.white)
            VStack() {
                Text(movieClub.name)
                    .font(.title)
                Text("Owner: \(movieClub.ownerName)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Now Playing: \(movieClub.movies![0].title)")
                // You can add more information about the movie club here
            }
           
        }
        .frame(width: 450, height: 250)
        
    }
}

#Preview{
   
    MovieClubCardView(movieClub: MovieClub.TestData[0])
        .environment(DataManager())
}
