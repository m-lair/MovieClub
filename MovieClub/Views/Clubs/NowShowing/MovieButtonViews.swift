//
//  MovieButtonViews.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/27/24.
//

import SwiftUI

struct CollectButton: View {
    @Binding var collected: Bool
    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .frame(width: 85, height: 30)
                .clipShape(.capsule)
                .foregroundStyle(collected ? .yellow : .white)
            Text("Collect")
                .fontWeight(.bold)
                .foregroundStyle(.black)
        }
    }
}

struct ReviewThumbs: View {
    @Environment(DataManager.self) var data
    @Binding var liked: Bool
    @Binding var disliked: Bool
    var body: some View {
        HStack {
            Button {
                let wasLiked = liked
                liked.toggle()
                
                if liked {
                    disliked = false
                    Task {
                        do {
                            try await likeMovie()
                        } catch {
                            // Revert on failure
                            liked = wasLiked
                            print("Failed to like movie: \(error)")
                        }
                    }
                }
            } label: {
                Image(systemName: "hand.thumbsup.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(liked ? .green : .white)
            }
            
            Button {
                let wasDisliked = disliked
                disliked.toggle()
                
                if disliked {
                    liked = false
                    Task {
                        do {
                            try await dislikeMovie()
                        } catch {
                            // Revert on failure
                            disliked = wasDisliked
                            print("Failed to dislike movie: \(error)")
                        }
                    }
                }
            } label: {
                Image(systemName: "hand.thumbsdown.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(disliked ? .red : .white)
            }
        }
    }
    
    func likeMovie() async throws {
        try await data.handleMovieReaction(isLike: true)
    }

    func dislikeMovie() async throws {
        try await data.handleMovieReaction(isLike: false)
    }
}


