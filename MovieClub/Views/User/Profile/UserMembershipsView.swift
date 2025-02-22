//
//  UserMembershipsView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/13/24.
//

import SwiftUI

struct UserMembershipsView: View {
    @Environment(DataManager.self) private var data
    let userId: String?
    @State var userClubs: [MovieClub] = []
    var sortedUserClubs: [MovieClub] {
        userClubs.sorted { club1, club2 in
            if let date1 = club1.createdAt, let date2 = club2.createdAt {
                return date1 < date2
            }
            return club1.createdAt != nil
        }
    }
    var body: some View {
        ScrollView {
            ForEach(sortedUserClubs, id: \.id) { movieClub in
                MovieClubCardView(movieClub: movieClub)
                    .padding(.top, 4)
            }
        }
        .scrollIndicators(.hidden)
        .task {
            Task {
                if let userId = userId {
                    print("userId \(userId)")
                    self.userClubs = await data.fetchUserClubs(forUserId: userId)
                }
            }
        }
    }
}


