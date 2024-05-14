//
//  MovieClubScrollView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct MovieClubScrollView: View {
    @Environment(DataManager.self) var data: DataManager
    var body: some View {
        let userClubs = data.userMovieClubs
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                ForEach(userClubs) { movieClub in
                    NavigationLink(destination: ClubDetailView(movieClub: movieClub)) {
                        MovieClubCardView(movieClub: movieClub)
                            .frame(width: 300) // Specify card width
                    }
                }
            }
            .padding()
        }
        .frame(height: 200) // Specify scroll view height
        
        }
    }


