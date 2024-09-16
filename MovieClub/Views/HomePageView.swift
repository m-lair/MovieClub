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
    var body: some View {
        ZStack{
            Color.gray.ignoresSafeArea()
                .overlay(Color.black.opacity(0.7))
            ScrollView{
                VStack {
                    if data.userMovieClubs.count > 0 {
                        ForEach(data.userMovieClubs) { movieClub in
                            NavigationLink(value: movieClub) {
                                MovieClubCardView(movieClub: movieClub)
                            }
                        }
                    } else {
                        ProgressView()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink(value: "NewClub") {
                            Image(systemName: "plus")
                                .imageScale(.large)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing){
                        Button {
                            
                        } label: {
                            Image(systemName: "bell.fill")
                        }
                    }
                }
                .navigationDestination(for: MovieClub.self) { club in
                    ClubDetailView(navPath: $navPath, movieClub: club)
                        .navigationTitle(club.name)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .navigationDestination(for: String.self) { value in
                    switch value {
                        
                    case "EditMovies":
                        ComingSoonListView()
                        
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




