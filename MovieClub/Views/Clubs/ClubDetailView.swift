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
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading...")
                    .onAppear {
                        Task {
                            print("in task club detail view")
                            
                            if let id = movieClub.id {
                                data.currentClub = movieClub
                                data.currentClub?.movies = await data.fetchMovies(for: id)
                                if let title = data.currentClub?.movies?[0].title {
                                    data.currentClub?.movies?[0].poster = try await data.fetchPoster(title: title)
                                    
                                }
                                print("before is loading")
                                isLoading = false
                            }
                            
                        }
                    }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Section
                    HeaderView(movieClub: movieClub)
                    
                    // Tabs
                    MovieClubTabView()
                    
                    // Featured Movie Section
                    FeaturedMovieView(movie: movieClub.movies?.first)
                    
                    // Comments Section
                    CommentsView(comments: data.comments)
                    
                    CommentInputView(movieclub: movieClub)
                }
                .padding()
                .navigationTitle(movieClub.name)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
#Preview {
    ClubDetailView(movieClub: MovieClub.TestData[0])
        .environment(DataManager())
}
