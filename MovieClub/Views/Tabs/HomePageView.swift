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
        data.userClubs.sorted {
            guard let date1 = $0.createdAt, let date2 = $1.createdAt else { return false }
            return date1 > date2
        }
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
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: Path.newClub) {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: Path.self) { route in
            switch route {
            case .newClub:
                NewClubView(path: $navPath)
            }
        }
        .navigationTitle("Movie Clubs")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear() {
            Task {
                await data.fetchUserClubs()
            }
        }
        .refreshable {
            Task {
                await data.fetchUserClubs()
            }
        }
    }
}

enum Path: Hashable {
    case newClub
}


