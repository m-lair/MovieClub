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
    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Section
                    HeaderView(movieClub: movieClub)
                    
                    // Tabs
                    MovieClubTabView()
                    
                    // Featured Movie Section
                    
                    FeaturedMovieView(movie: movieClub.movies?.first)
                    
                    // Comments Section
                    let _ = print("check data.comment: \(data.comments)")
                    CommentsView(comments: data.comments)
                    
                    CommentInputView(movieclub: movieClub)
                    
                }
                .padding()
            }
            .navigationTitle(movieClub.name)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear(){
            Task{
                movieClub.movies = await data.fetchMovies(for: movieClub.id ?? "")
                await data.fetchComments(movieClubId: movieClub.id ?? "", movieId: movieClub.movies?.first?.id ?? "")
                            
            }
        }
    }
}

#Preview {
    ClubDetailView(movieClub: MovieClub.TestData[0])
        .environment(DataManager())
}
