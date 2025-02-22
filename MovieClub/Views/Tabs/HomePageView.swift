//
//  HomePageView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/7/24.
//

import SwiftUI
import FirebaseAuth


struct HomePageView: View {
    @Environment(DataManager.self) var data: DataManager
    @Binding var navPath: NavigationPath
    @State private var isLoading: Bool = true
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
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                WaveLoadingView()
            } else {
                // Original layout without extra padding/spacing changes
                if userClubs.isEmpty {
                    VStack {
                        Spacer()
                        Text("No clubs Found")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack {
                            ForEach(sortedUserClubs, id: \.id) { movieClub in
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
        .refreshable {
            Task {
                if let userId = Auth.auth().currentUser?.uid {
                    self.userClubs =  await data.fetchUserClubs(forUserId: userId)
                }
            }
        }
        .onAppear {
            Task {
                if let userId = Auth.auth().currentUser?.uid {
                    self.userClubs =  await data.fetchUserClubs(forUserId: userId)
                    isLoading = false
                }
            }
        }
    }
}

enum Path: Hashable {
    case newClub
}
