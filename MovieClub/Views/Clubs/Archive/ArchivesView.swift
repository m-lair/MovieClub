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
    var archivedMovies: [Movie] {
        dataManager.currentClub?.movies.filter { $0.status == "archived" }.reversed() ?? []
    }
    @State private var selectedMovie: Movie? = nil
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(archivedMovies, id: \.self) { movie in
                    ArchiveRowView(movie: movie)
                        .onTapGesture {
                            selectedMovie = movie
                            showSheet = true
                        }
                    Divider()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if let clubId = dataManager.currentClub?.id {
                Task {
                    try await dataManager.fetchFirestoreMovies(clubId: clubId)
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
