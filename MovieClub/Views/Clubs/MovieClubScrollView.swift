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
        NavigationStack{
            if data.userMovieClubs.isEmpty {
                Text("No movie clubs available")
            } else {
                ScrollView(.vertical) {
                    VStack(spacing: 20) {
                        ForEach(data.userMovieClubs) { movieClub in
                            NavigationLink(destination: ClubDetailView(movieClub: movieClub)) {
                                MovieClubCardView(movieClub: movieClub)
                                
                            }
                        
                            
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    MovieClubScrollView()
        .environment(DataManager())
}
