//
//  HeaderView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct HeaderView: View {
    var movieClub: MovieClub
    
    var body: some View {
        Section {
            Text(movieClub.description ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 20) {
                InfoView(imageName: "person.3", count: movieClub.numMembers, label: "Members")
                InfoView(imageName: "film", count: movieClub.numMovies, label: "Movies")
            }
        }
    }
}



#Preview {
    HeaderView(movieClub: MovieClub.TestData[0])
}