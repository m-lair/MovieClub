//
//  HomePageView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/7/24.
//



import SwiftUI


struct HomePageView: View {
    @Environment(DataManager.self) var data: DataManager
    @Binding var navPath: NavigationPath
    
    var userClubs: [MovieClub] {
        data.userClubs
    }
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if userClubs.isEmpty {
                VStack {
                    Spacer()
                    WaveLoadingView()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack {
                        ForEach(userClubs, id: \.self) { movieClub in
                            NavigationLink(value: movieClub) {
                                MovieClubCardView(movieClub: movieClub)
                            }
                        }
                    }
                    .navigationDestination(for: MovieClub.self) { club in
                        ClubDetailView(navPath: $navPath, club: club)
                            .navigationTitle(club.name)
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
            }
        }
        .toolbar {
            NavigationLink(destination: NewClubView(path: $navPath)) {
                Image(systemName: "plus")
            }
        }
        .navigationTitle("Movie Clubs")
        .navigationBarTitleDisplayMode(.inline)
    }
}




