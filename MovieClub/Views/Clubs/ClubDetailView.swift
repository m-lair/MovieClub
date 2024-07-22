//
//  ClubDetailView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI
import FirebaseFirestore

struct ClubDetailView: View {
    @Environment(DataManager.self) var data: DataManager
    let movieClub: MovieClub
    @State var isPresentingEditView = false
    @State var movies: [Movie]?
    @State var rosterUsers: [User] = []
    @Binding var path: NavigationPath
    @State var comments: [Comment] = []
    @FocusState private var isCommentFieldFocused: Bool
    var body: some View {
        VStack {
            // Header Section
            HeaderView(movieClub: movieClub)
                
                
            Divider()
            if let movie = movies?[0] {
                SwipeableView(numberOfPages: 2) {
                    NowPlayingView(movie: movies?.first, comments: comments)
                    RosterView(currentEndDate: movie.endDate)
                    
                }
            }
            
        }
        .task{
            data.currentClub = movieClub
            if let id = movieClub.id {
                self.movies = await data.fetchAndMergeMovies(clubId: id)
                self.comments = await data.fetchComments(movieClubId: movieClub.id!, movieId: self.movies?[0].id ?? "")
            }
        }
        .toolbar{
            Button("Edit") {
                isPresentingEditView = true
            }
        }
        .sheet(isPresented: $isPresentingEditView) {
            EditEmptyView()
        }
    }
}
