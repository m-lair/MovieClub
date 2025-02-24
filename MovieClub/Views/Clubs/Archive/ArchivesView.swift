//
//  ArchivesView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/24/24.
//

import SwiftUI

struct ArchivesView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var showSheet: Bool = false
    // Only archived movies
    @State var archivedMovies: [Movie] = []
    @State private var selectedMovie: Movie? = nil
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(archivedMovies, id: \.id) { movie in
                    ArchiveRowView(movie: movie)
                        .onTapGesture {
                            selectedMovie = movie
                        }
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.easeInOut, value: archivedMovies)
        }
        .ignoresSafeArea()
        .onAppear {
            if let clubId = dataManager.currentClub?.id {
                Task {
                    let moviesSnapshot = try await dataManager.movieClubCollection()
                        .document(clubId)
                        .collection("movies")
                        .order(by: "endDate", descending: true)
                        .whereField("status", isEqualTo: "archived")
                        .getDocuments()
                    
                    for document in moviesSnapshot.documents {
                        let baseMovie = try document.data(as: Movie.self)
                        baseMovie.id = document.documentID
                        
                        // Fetch and attach API data to the movie
                        if let apiMovieData = try await dataManager.fetchMovieAPIData(for: baseMovie.imdbId) {
                            baseMovie.apiData = apiMovieData
                        }
                        
                        archivedMovies.append(baseMovie)
                    }
                }
            }
        }
        .sheet(item: $selectedMovie) { movie in
            // A separate view for displaying the comments read-only
            CommentsSheetView(movie: movie, onReply: handleReply(_:))
        }
    }
    
    // MARK: - Helper Methods
    private func handleReply(_ comment: Comment) {
        print("do nothing")
    }
}
