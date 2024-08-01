//
//  HomePageView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/7/24.
//



import SwiftUI


struct HomePageView: View {
    @Environment(DataManager.self) var data: DataManager
    let userClubs: [MovieClub]
    var body: some View {
       // NavigationStack(path: $path) {
            ScrollView{
                //let _ = print("in homepageview \(path)")
                //let _ = print("userclubs: \(userClubs)")
                VStack {
                    if userClubs.count > 0 {
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
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(value: "NewClub") {
                            Image(systemName: "plus")
                                .imageScale(.large)
                        }
                    }
                }
                .navigationDestination(for: MovieClub.self) { club in
                    ClubDetailView(movieClub: club)
                        .navigationTitle(club.name)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .navigationDestination(for: String.self) { value in
                    switch value {
                    
                    case "EditMovies":
                        ComingSoonEditView(userID: data.currentUser!.id!)
                    
                    case "NewClub":
                        NewClubView()
                    
                    case "CreateForm":
                        ClubDetailsForm()
                    default: ProgressView()
                    }
                    
                }
            }
            .navigationTitle("Movie Clubs")
        }
    }
//}



