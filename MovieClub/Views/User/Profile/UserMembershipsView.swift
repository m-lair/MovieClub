//
//  UserMembershipsView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/13/24.
//

import SwiftUI

struct UserMembershipsView: View {
    @Environment(DataManager.self) private var data
    var body: some View {
        Section(header: Text("My Movie Clubs")){
            VStack{
                ScrollView(.horizontal) {
                    HStack{
                        ForEach(data.userClubs) { club in
                            VStack{
                                Text(club.name)
                                    .font(.title3)
                                if let url = URL(string: club.movies?[0].poster ?? "") {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 175)
                                                .cornerRadius(15) // Rounded corners
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .stroke(Color.white, lineWidth: 4) // White border
                                                )
                                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .font(.title)
    }
}


