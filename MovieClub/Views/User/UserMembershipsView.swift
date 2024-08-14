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
        List{
            Section {
                ForEach(data.userMovieClubs) { club in
                    HStack{
                        Text(club.name)
                        Text(club.description ?? "")
                    }
                }
            } header: {
                Text("Movie Clubs")
            }
        }
    }
}


