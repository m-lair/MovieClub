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
        VStack(alignment: .leading, spacing: 8) {
            Text(movieClub.name)
                .font(.title)
            Text("Owner: \(movieClub.ownerName)")
                .font(.subheadline)
                .foregroundColor(.gray)
            // You can add more information about the movie club here
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
}


