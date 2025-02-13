//
//  UserMembershipsView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/13/24.
//

import SwiftUI

struct UserMembershipsView: View {
    @Environment(DataManager.self) private var data
    var userClubs: [MovieClub] {
        data.userClubs.sorted {
            guard let date1 = $0.createdAt, let date2 = $1.createdAt else { return false }
            return date1 < date2
        }
    }
    @State var clubsPath = NavigationPath()
    var body: some View {
        ScrollView {
            ForEach(userClubs, id: \.self) { movieClub in
                MovieClubCardView(movieClub: movieClub)
                    .padding(.top, 4)
            }
        }
        .scrollIndicators(.hidden)
    }
}


