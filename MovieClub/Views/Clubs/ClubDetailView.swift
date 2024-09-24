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
    @Binding var navPath: NavigationPath
    @State var movieClub: MovieClub
    var movie: Movie {
        return movieClub.movies[0]
    }
    @State var isPresentingEditView = false
    @State var comments: [Comment] = []
    @FocusState private var isCommentFieldFocused: Bool
    var body: some View {
        ZStack{
            BlurredBackgroundView(urlString: movie.poster ?? "")
            VStack {
                HeaderView(movieClub: movieClub)
                SwipeableView(contents: [
                    AnyView(NowPlayingView(movie: movie, comments: comments, club: movieClub)),
                    AnyView(ComingSoonView(club: movieClub))
                    
                ])
                .padding(.horizontal)
            }
            .padding()
            Spacer()
                .task{
                    guard
                        let movieId = movieClub.movies[0].id,
                        let movieClubId = movieClub.id
                    else {
                        print("missing movieId or movieClubId")
                        return
                    }
                    self.comments = await data.fetchComments(movieClubId: movieClubId, movieId: movieId)
                }
        }
        .toolbar{
            if movieClub.ownerId == data.currentUser?.id ?? "" {
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
                            dismiss()
                        }
                    } label: {
                        Label("Leave Club", systemImage: "trash")
                    }
                    .foregroundStyle(.red)
                    
                } label: {
                    Label("Menu", systemImage: "ellipsis")
                }
            } else {
                Menu {
                    Button {
                        Task{
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
            ClubDetailsForm(navPath: $navPath)
        }
    }
}

/*
#Preview {
    ClubDetailView(movieClub: MovieClub.TestData[0])
        .environment(DataManager())
}
*/
