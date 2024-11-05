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
            Color.gray.ignoresSafeArea()
                .overlay(Color.black.opacity(0.7))
            ScrollView{
                VStack {
                    if !userClubs.isEmpty {
                        ForEach(userClubs, id: \.self) { movieClub in
                            NavigationLink(value: movieClub) {
                                MovieClubCardView(movieClub: movieClub)
                            }
                            .task {
                                data.currentClub = await data.fetchMovieClub(clubId: movieClub.id ?? "")
                            }
                        }
                    } else {
                        Text("\(userClubs.count) clubs found")
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
    }
}




