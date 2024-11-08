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
    @State var movieId: String
    
    var body: some View {
        HStack {
            TextField("Leave a Comment", text: $commentText)
                .frame(maxHeight: 9)
                .padding()
                .overlay(
                 Capsule().stroke(Color.white, lineWidth: 1) // Capsule border
                )
                .lineLimit(5, reservesSpace: true)
                .padding(2)
               
            Button("", systemImage: "arrow.up.circle.fill") {
                Task{
                    if commentText != "" && commentText.count > 0 {
                        try await submitComment()
                        commentText = ""
                    } else {
                        print("empty Text")
                    }
                }
            }
            .foregroundColor(Color(uiColor: .systemBlue))
            .font(.title)
        }
        .padding(.bottom)
        .background(.clear)
        .alert(error, isPresented: $errorShowing) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func submitComment() async throws {
        guard
            let userId = data.currentUser?.id
        else {
            errorShowing.toggle()
            self.error = "Could not get all comment information"
            return
        }
        let newComment = Comment(id: UUID().uuidString, userId: userId, userName: "duhmarcus", createdAt: Date(), text: commentText, likes: 0)
        //could hand back result objects and contionally navigate based on fails
        do {
            try await data.postComment(clubId: data.clubId, movieId: movieId, comment: newComment)
        } catch DataManager.CommentError.invalidData {
            errorShowing.toggle()
            self.error = "Could not encode comment"
        } catch DataManager.CommentError.networkError {
            errorShowing.toggle()
            self.error = "Invalid response from server"
        } catch {
            errorShowing.toggle()
            self.error = "Unknown error"
        }
    }
}
