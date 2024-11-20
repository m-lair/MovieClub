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
    @State var isLoading: Bool = true
    
    var userClubs: [MovieClub] {
        data.userClubs
    }
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading {
                VStack {
                    Spacer()
                    WaveLoadingView()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if userClubs.isEmpty{
                Text("You have no clubs yet")
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
        .onAppear {
            isLoading = false
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
    }
}

enum Path: Hashable {
    case newClub
}


