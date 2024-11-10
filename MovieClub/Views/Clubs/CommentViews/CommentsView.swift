//
//  CommentView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct CommentsView: View {
    @Environment(DataManager.self) private var data: DataManager
    
    var onReply: (Comment) -> Void
    var comments: [CommentNode] { data.comments }
    
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
                    
                    ForEach(comments) { commentNode in
                        CommentRow(commentNode: commentNode, onReply: onReply)
                    }
                    
                }
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
            _ = try await data.fetchComments(clubId: data.clubId, movieId: data.movieId)
        } catch {
            print("Error fetching comments: \(error)")
        }
    }
}

struct CommentRow: View {
    var commentNode: CommentNode
    var onReply: (Comment) -> Void
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Display the main comment
            CommentDetailView(comment: commentNode.comment, onReply: onReply)
            
            // Check if there are replies
            if !commentNode.replies.isEmpty {
                // Expand/Collapse Button
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(isExpanded ? "Hide Replies" : "Show Replies (\(commentNode.replies.count))")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.blue)
                    }
                    .padding(.leading, 30)
                }
                
                // Replies Section
                if isExpanded {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(commentNode.replies, id: \.id) { replyNode in
                            HStack(alignment: .top, spacing: 0) {
                                // Thread line container with enhanced styling
                                VStack(alignment: .center, spacing: 0) {
                                    // Vertical line
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                        .padding(.leading, 9)
                                }
                                .frame(width: 20)
                                
                                // Child comment
                                CommentRow(commentNode: replyNode, onReply: onReply)
                            }
                        }
                    }
                    .padding(.leading, 20) // Indent replies for hierarchy
                }
            }
        }
    }
}
