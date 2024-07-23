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
            Spacer()
            Divider()
            if let movie = movies?.first {
                SwipeableView(numberOfPages: 2) {
                    NowPlayingView(movie: movies?.first, comments: comments)
                    RosterView(currentEndDate: movie.endDate)
                }
                CommentInputView(movieClub: movieClub,movieID:movie.id ?? "")
            }else{
                EmptyMovieView()
            }
        }
        Spacer()
        .task{
            data.currentClub = movieClub
            if let id = movieClub.id {
                self.movies = await data.fetchAndMergeMovies(clubId: id)
                if let movie = movies?.first {
                    self.comments = await data.fetchComments(movieClubId: movieClub.id!, movieId: movie.id ?? "")
                }
            }
        }
        .toolbar{
            if movieClub.ownerID == data.currentUser?.id ?? "" {
                Button("Edit") {
                    isPresentingEditView = true
                }
            }
        }
            
        .sheet(isPresented: $isPresentingEditView) {
            EditEmptyView()
        }
    }
}
