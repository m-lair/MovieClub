//
//  ClubDetailView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct ClubDetailView: View {
    @Environment(DataManager.self) var data: DataManager
    let movieClub: MovieClub
    @State var isPresentingEditView = false
    @State var movies: [Movie]?
    @Binding var path: NavigationPath
    @FocusState private var isCommentFieldFocused: Bool
    var body: some View {
        VStack(spacing: 10) {
            ScrollView{
            // Header Section
            HeaderView(movieClub: movieClub)
            
            //MovieClubTabView()
            Divider()
            if let movies {
                    FeaturedMovieView(movie: movies[0])
                HStack{
                    Button {
                        //prev Movie
                    } label: {
                        Text("Previos Movie")
                    }
                    
                    NavigationLink {
                        AddMovieView(path: $path)
                    } label: {
                        Text("Add Movie")
                    }
                    
                    Button {
                        //next Movie
                    } label: {
                        Text("Previos Movie")
                    }
                }
                Divider()
                    // Comments Section
                    CommentsView(movie: movies[0], clubId: movieClub.id ?? "")
                }
                
            }
            let _ = print("movies.movies: \(movies)")
            if let movie = movies?[0].id{
                CommentInputView(movieClub: movieClub, movieID: movie)
                    .focused($isCommentFieldFocused)
                    .onChange(of: isCommentFieldFocused) {
                        withAnimation {
                            isCommentFieldFocused = true
                        }
                    }
            }
        }
        .task{
            data.currentClub = movieClub
            if let id = movieClub.id {
                self.movies = try! await data.fetchAndMergeMovies(clubId: id)
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
