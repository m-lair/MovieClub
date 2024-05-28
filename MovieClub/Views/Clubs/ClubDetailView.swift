//
//  ClubDetailView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct ClubDetailView: View {
    var movieClub: MovieClub
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(movieClub.name)
                .font(.title)
            Text("Owner: \(movieClub.ownerName)")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(movieClub.isPublic ? "Public Club" : "Private Club")
                .font(.subheadline)
                .foregroundColor(movieClub.isPublic ? .green : .red)
            // Add more detailed information about the movie club here
        }
        .padding()
        .navigationBarTitle("Club Detail")
    }
}
