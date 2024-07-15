//
//  ClubDetailView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct ClubDetailView: View {
    @Environment(DataManager.self) var data: DataManager
    @State var movieClub: MovieClub
    @State var isLoading = true
    @State var isPresentingEditView = false
    var movies: [MovieClub.Movie] {
        if movieClub.movies!.count > 0 {
            return movieClub.movies!
        } else {
            return []
        }
    }
    @FocusState private var isCommentFieldFocused: Bool
    var body: some View {
        VStack{
            if isLoading {
                ProgressView("Loading...")
                    .onAppear {
                        Task {
                            print("in task club detail view")
                            print("movieclubID\(movieClub.id ?? " no id")")
                            if movieClub.id != nil {
                                data.currentClub = movieClub
                                //movieClub.movies =
                                movieClub.movies = await data.fetchAndMergeMovies()
                                print(data.currentClub?.movies)
                                print("###")
                                print(movieClub.movies)
                                // data.currentClub?.movies = await    data.fetchMovies(for: id)
                                if movieClub.movies!.count > 0{
                                    if let title = movieClub.movies?[0].title {
                                        movieClub.movies?[0].poster = try await data.fetchPoster(title: title)
                                        //data.currentClub?.movies?[0].title {
                                        //   data.currentClub?.movies?[0].poster = try await data.fetchPoster(title: title)
                                        
                                    }}
                                print("before is loading")
                                isLoading = false
                            }
                            
                            
                        }
                    }
            } else {
                VStack(spacing: 10) {
                    // Header Section
                    HeaderView(movieClub: movieClub)
                    
                    // Tabs
                    //MovieClubTabView()
                    ScrollView{
                        Divider()
                        // Featured Movie Section
                        FeaturedMovieView(movie: movieClub.movies![0])
                        
                        Divider()
                        
                        // Comments Section
                        if movieClub.movies!.count > 0 {
                            CommentsView(movie: movieClub.movies?[0])
                        }
                    }
                    
                    .padding()
                    .navigationTitle(movieClub.name)
                    
                    Spacer()
                    if movieClub.movies!.count > 0 {
                        CommentInputView(movieClub: movieClub, movieID: movieClub.movies?[0].id ?? "")
                            .focused($isCommentFieldFocused)
                            .onChange(of: isCommentFieldFocused) {
                                withAnimation {
                                    isCommentFieldFocused = true
                                }
                            }
                    }
                }
            }
        }
        .toolbar{
            Button("Edit") {
                isPresentingEditView = true
            }
        }
        .sheet(isPresented: $isPresentingEditView) {
            NavigationStack {
                EditEmptyView()
                    .navigationTitle(movieClub.name)
            }
        }
        
    }
}

    

         

#Preview {
    ClubDetailView(movieClub: MovieClub.TestData[0])
        .environment(DataManager())
}
