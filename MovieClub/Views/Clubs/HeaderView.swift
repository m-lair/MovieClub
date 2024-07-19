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
        VStack(alignment: .leading) {
            HStack {
                
           /*     Image(systemName: "person.crop.circle.fill") // Placeholder image
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
                
                VStack(alignment: .leading) {
                    Text(movieClub.name)
                        .font(.title)
                        .fontWeight(.bold)
            
                    
                }*/
            }
            Section{
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
}

#Preview {
    HeaderView(movieClub: MovieClub.TestData[0])
}
