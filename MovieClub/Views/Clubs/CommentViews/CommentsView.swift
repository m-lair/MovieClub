//
//  CommentView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct CommentsView: View {
    @Environment(DataManager.self) private var data: DataManager
    
    var comments: [Comment] { data.comments }
    
    @State var isLoading: Bool = false
    @State private var error: Error?
    
    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if comments.isEmpty {
                    VStack {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text ("No comments yet")
                        }
                    }
                } else {
                    ForEach(comments, id: \.id) { comment in
                        CommentDetailView(comment: comment)
                        Divider()
                    }
                }
            }
            .onDisappear {
                data.comments = []
            }
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") {
                error = nil
            }
            Button("Retry") {
                Task {
                    await refreshComments()
                }
            }
        } message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        }
        .task {
            setupCommentListener()
        }
        .onDisappear {
            data.comments = []
            data.commentsListener?.remove()
            data.commentsListener = nil
        }
    }
    
    private func setupCommentListener() {
        data.listenToComments(movieId: data.movieId)
    }
    
    private func refreshComments() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("clubId: \(data.clubId), movieId: \(data.movieId)")
            _ = try await data.fetchComments(clubId: data.clubId, movieId: data.movieId)
        } catch {
            print("Error fetching comments: \(error)")
        }
    }
}



