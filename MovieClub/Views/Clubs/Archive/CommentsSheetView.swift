//
//  CommentsSheetView.swift
//  MovieClub
//
//  Created by Marcus Lair on 2/10/25.
//

import SwiftUI

struct CommentsSheetView: View {
    let movie: Movie
    @Environment(\.dismiss) var dismiss
    @Environment(DataManager.self) private var dataManager
    private var comments: [CommentNode] { dataManager.comments }
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    var onReply: (Comment) -> Void
    
    var body: some View {
        NavigationStack {
           
            VStack {
                if isLoading {
                    ProgressView("Loading comments...")
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else if comments.isEmpty {
                    Text("No comments found for \(movie.title)")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(comments, id: \.id) { comment in
                                CommentRow(commentNode: comment, onReply: onReply)
                                Divider()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitle("Comments", displayMode: .inline)
            // Add a dismiss button if you want
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    if let movieId = movie.id {
                        
                        dataManager.listenToComments(movieId: movieId)
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

