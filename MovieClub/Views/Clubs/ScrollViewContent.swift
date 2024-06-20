//
//  ScrollViewContent.swift
//  MovieClub
//
//  Created by Marcus Lair on 6/17/24.
//

import SwiftUI

struct ScrollViewContent: View {
    @Environment(DataManager.self) var data: DataManager
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 20) {
                ForEach(data.userMovieClubs) { movieClub in
                    NavigationLink(destination: ClubDetailView(movieClub: movieClub),
                                   label: {
                        MovieClubCardView(movieClub: movieClub)
                    })
                }
            }
        }
    }
}
   


#Preview {
    ScrollViewContent()
        .environment(DataManager())
}
