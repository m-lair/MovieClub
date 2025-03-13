//
//  CommentView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/28/24.
//

import SwiftUI

struct FlattenedComment: Identifiable {
    let node: CommentNode
    let level: Int
    var id: String { node.id }
}

struct CommentsView: View {
    @Environment(DataManager.self) private var data: DataManager
    
    var onReply: (Comment) -> Void
    var comments: [CommentNode] { data.comments }
    
    @State private var expandedNodes = Set<String>()
    @State var isLoading: Bool = false
    @State private var error: Error?
    
    // Track the current movie ID to detect changes
    @State private var currentMovieId: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let flatList = flattenComments(comments, level: 0, expandedNodes: expandedNodes)
                
                if flatList.isEmpty {
                    Text(isLoading ? "Loading..." : "No comments yet")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    // 2) Render the flattened list
                    ForEach(flatList) { item in
                        CommentRow(
                            node: item.node,
                            level: item.level,
                            isExpanded: expandedNodes.contains(item.node.id),
                            onToggle: toggleExpand,
                            onReply: onReply
                        )
                        .transition(.opacity)
                        Divider()
                            .mask(LinearGradient(colors: [.clear.opacity(0.5), .white, .clear.opacity(0.5)], startPoint: .leading, endPoint: .trailing))
                    }
                }
            }
            .animation(.easeInOut, value: comments)
        }
        .task {
            if currentMovieId != data.movieId {
                setupCommentListener()
                currentMovieId = data.movieId
            }
        }
        .onChange(of: data.movieId) { oldId, newId in
            if oldId != newId && newId != "" {
                // Only reset expanded nodes if we're switching to a different movie
                if !comments.isEmpty {
                    expandedNodes.removeAll()
                }
                
                // Only set up a new listener if the movie ID has changed
                if currentMovieId != newId {
                    setupCommentListener()
                    currentMovieId = newId
                }
            }
        }
        .onChange(of: comments) {
            if expandedNodes.isEmpty && !comments.isEmpty {
                expandedNodes = collectExpandedNodes(nodes: comments, maxDepth: 3)
            }
        }
        .id("comments-\(data.movieId)")
    }
    
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
            // Collapse: remove this node and all its descendants
            removeDescendants(for: nodeId, in: comments)
        } else {
            expandedNodes.insert(nodeId)
        }
    }

    private func removeDescendants(for nodeId: String, in nodes: [CommentNode]) {
        // First, remove the node itself
        expandedNodes.remove(nodeId)
        // Then find the node in the tree and remove its children recursively
        for node in nodes {
            if node.id == nodeId {
                for child in node.replies {
                    removeDescendants(for: child.id, in: child.replies)
                }
            } else {
                removeDescendants(for: nodeId, in: node.replies)
            }
        }
    }
    
    /// Recursively collect IDs for all nodes at or below `maxDepth`
    private func collectExpandedNodes(
        nodes: [CommentNode],
        maxDepth: Int,
        currentDepth: Int = 0
    ) -> Set<String> {
        var expanded = Set<String>()
        for node in nodes {
            // If we haven't reached maxDepth yet, mark this comment as expanded
            if currentDepth < maxDepth {
                expanded.insert(node.id)
                // Recurse to children and add their IDs too (they'll appear expanded)
                let childIDs = collectExpandedNodes(
                    nodes: node.replies,
                    maxDepth: maxDepth,
                    currentDepth: currentDepth + 1
                )
                expanded.formUnion(childIDs)
            }
            // If currentDepth == maxDepth, we do NOT expand further
            // so children remain collapsed by default.
        }
        return expanded
    }
    
    private func setupCommentListener() {
        data.listenToComments(movieId: data.movieId)
    }
}

struct CommentRow: View {
    let colors: [Color] = [.blue, .green, .yellow, .orange, .red]
    let node: CommentNode
    let level: Int
    let isExpanded: Bool
    let onToggle: (String) -> Void
    let onReply: (Comment) -> Void
    
    var canReply: Bool = true
    
    private var isAnonymized: Bool {
        node.comment.userId == "anonymous-user"
    }
    
    var body: some View {
        HStack(alignment: .top) {
            // Decorative vertical line to indicate nesting (only for nested replies)
            if level > 0 {
                RoundedRectangle(cornerRadius: 4)
                    .fill(colors[level % colors.count].opacity(0.5))
                    .mask(LinearGradient(colors: [.clear, colors[level % colors.count].opacity(0.5)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 2)
            }
            
            VStack(alignment: .leading) {
                CommentDetailView(comment: node.comment)
                    .padding(.leading, CGFloat(level * 4))
                
                HStack {
                    // Only show reply button for non-anonymized comments
                    if canReply && !isAnonymized {
                        Button {
                            onReply(node.comment)
                        } label: {
                            Label("reply", systemImage: "arrow.turn.down.right")
                        }
                    }
                    if !node.replies.isEmpty {
                        Button {
                            withAnimation {
                                onToggle(node.id)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "Hide Replies" : "Show Replies (\(node.replies.count))")
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 4)
                            .background(
                                Capsule()
                                    .stroke(Color.accentColor, lineWidth: 1)
                            )
                        }
                        .padding(.leading, 4)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(.vertical, 3)
        .padding(.leading, CGFloat(level * 16))
        
    }
}
