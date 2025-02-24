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
    @Environment(DataManager.self) private var dataManager: DataManager
    
    var onReply: (Comment) -> Void
    var comments: [CommentNode] { dataManager.comments }
    
    @State private var expandedNodes = Set<String>()
    @State var isLoading: Bool = false
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    let flatList = flattenComments(comments, level: 0, expandedNodes: expandedNodes)
                    
                    if flatList.isEmpty {
                        Text(isLoading ? "Loading..." : "No comments yet")
                    } else {
                        // 2) Render the flattened list
                        ForEach(flatList) { item in
                            CommentRow(
                                node: item.node,
                                level: item.level,
                                isExpanded: expandedNodes.contains(item.node.id),
                                onToggle: toggleExpand,
                                onReply: onReply,
                                canReply: false
                            )
                            Divider()
                                .mask(LinearGradient(colors: [.clear.opacity(0.5), .black, .clear.opacity(0.5)], startPoint: .leading, endPoint: .trailing))
                            .padding(.horizontal)
                        }
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
    // 3) The flatten function includes replies *only* if expanded
    private func flattenComments(
        _ nodes: [CommentNode],
        level: Int,
        expandedNodes: Set<String>
    ) -> [FlattenedComment] {
        var result = [FlattenedComment]()
        for node in nodes {
            result.append(FlattenedComment(node: node, level: level))
            // If parent is expanded, include its children
            if expandedNodes.contains(node.id) {
                result.append(contentsOf: flattenComments(node.replies, level: level + 1, expandedNodes: expandedNodes))
            }
        }
        return result
    }
    
    private func toggleExpand(_ nodeId: String) {
        if expandedNodes.contains(nodeId) {
            expandedNodes.remove(nodeId)
        } else {
            expandedNodes.insert(nodeId)
        }
    }
    
    private func setupCommentListener() {
        if let movieId = movie.id {
            dataManager.listenToComments(movieId: movieId)
        }
    }
}

