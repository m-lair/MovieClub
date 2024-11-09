//
//  CommentInputView.swift
//  MovieClub
//
//  Created by Marcus Lair on 6/10/24.
//

import SwiftUI
import FirebaseFunctions
import Firebase

struct CommentInputView: View {
    @Environment(DataManager.self) var data: DataManager
    @State var error: String = ""
    @State var errorShowing: Bool = false
    @State private var commentText: String = ""
    
   
    //var movieClub: MovieClub
    let movieId: String
    @Binding var replyToComment: Comment?
    @FocusState private var isFocused: Bool
    var textLabel: String {
        if replyToComment != nil {
            return "Leave a Reply \(replyToComment?.userId)"
        } else {
            return "Leave a Comment"
        }
    }

    var body: some View {
        
        
        VStack {
            HStack {
                TextField(textLabel, text: $commentText)
                    .frame(maxHeight: 9)
                    .padding()
                    .overlay(
                        Capsule().stroke(Color.white, lineWidth: 1) // Capsule border
                    )
                    .lineLimit(5, reservesSpace: true)
                    .focused($isFocused)
                    .padding(2)
                
                Button("", systemImage: "arrow.up.circle.fill") {
                    Task {
                        await submitComment()
                        commentText = ""
                        replyToComment = nil
                        isFocused = false
                    }
                }
                .foregroundColor(Color(uiColor: .systemBlue))
                .font(.title)
            }
            
        }
        .padding(.bottom)
        .background(.clear)
        .alert(error, isPresented: $errorShowing) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            if replyToComment != nil {
                isFocused = true
            }
        }
    }
    
    private func submitComment() async {
        guard let userId = data.currentUser?.id else {
            errorShowing.toggle()
            self.error = "Could not get user ID"
            return
        }
        
        let replyToCommentID = replyToComment?.id
        
        let newComment = Comment(
            id: UUID().uuidString,
            userId: userId,
            userName: data.currentUser?.name ?? "Anonymous",
            createdAt: Date(),
            text: commentText,
            likes: 0,
            parentId: replyToCommentID
        )
        
        do {
            try await data.postComment(clubId: data.clubId, movieId: movieId, comment: newComment)
            // Clear input fields after successful post
            
            commentText = ""
            replyToComment = nil
            isFocused = false
            
        } catch {
            errorShowing.toggle()
            self.error = "Failed to post comment: \(error.localizedDescription)"
        }
    }

}
