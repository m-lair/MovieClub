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


