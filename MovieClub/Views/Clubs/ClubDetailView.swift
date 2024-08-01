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
    @Environment(\.dismiss) var dismiss
    let movieClub: MovieClub
    @State var isPresentingEditView = false
    @State var movie: Movie?
    @State var rosterUsers: [User] = []
    @State var comments: [Comment] = []
    @FocusState private var isCommentFieldFocused: Bool
    var body: some View {
        VStack {
            // Header Section
            HeaderView(movieClub: movieClub)
            Spacer()
            Divider()
            if let movie {
                SwipeableView(numberOfPages: 2) {
                    NowPlayingView(movie: movie, comments: comments)
                    ComingSoonView()
                }
                CommentInputView(movieClub: movieClub, movieID: movie.id ?? "")
            }else{
                EmptyMovieView()
            }
        }
        Spacer()
        .task{
            if let currId = data.currentClub?.id, let newId = movieClub.id{
                //do nothing but this will be a caching system eventually
            }
            data.currentClub = movieClub
            do {
                if let id = movieClub.id {
                    self.movie = try await data.fetchAndMergeMovieData(club: movieClub)
                    if let movie = movie {
                        self.comments = await data.fetchComments(movieClubId: movieClub.id!, movieId: movie.id ?? "")
                    }
                }
            }catch{
                print(error)
            }
        }
        .toolbar{
            if movieClub.ownerID == data.currentUser?.id ?? "" {
                Menu {
                    Button {
                        // Do Nothing
                    } label: {
                        Label("Report A Problem", systemImage: "exclamationmark.octagon")
                    }
                    Button {
                        isPresentingEditView = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        Task{
                            await data.leaveClub(club: movieClub)
                            dismiss()
                        }
                    } label: {
                        Label("Leave Club", systemImage: "trash")
                    }
                    .foregroundStyle(.red)
                    
                } label: {
                    Label("Menu", systemImage: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $isPresentingEditView) {
            ClubDetailsForm()
        }
    }
}
