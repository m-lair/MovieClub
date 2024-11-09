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
        ZStack{
            Color.black.ignoresSafeArea()
                .overlay(Color.black.opacity(0.7))
            if !userClubs.isEmpty {
                ScrollView{
                    VStack {
                        ForEach(userClubs, id: \.self) { movieClub in
                            NavigationLink(value: movieClub) {
                                MovieClubCardView(movieClub: movieClub)
                                
                            }
                        }
                        .navigationDestination(for: MovieClub.self) { club in
                            ClubDetailView(navPath: $navPath, club: club)
                                .navigationTitle(club.name)
                                .navigationBarTitleDisplayMode(.inline)
                        }
                        .navigationDestination(for: String.self) { value in
                            switch value {
                                
                            case "NewClub":
                                NewClubView()
                                
                            case "CreateForm":
                                ClubDetailsForm(navPath: $navPath)
                            default: ProgressView()
                            }
                            
                        }
                    }
                }
                .navigationTitle("Movie Clubs")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack {
                    WaveLoadingView()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(value: "NewClub") {
                    Image(systemName: "plus")
                        .imageScale(.large)
                }
            }
        }
    }
}



