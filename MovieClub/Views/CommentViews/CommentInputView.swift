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
    var movieClub: MovieClub
    @State var movieId: String
    
    var body: some View {
        HStack {
            TextField("leave a comment", text: $commentText)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)

            Button("", systemImage: "arrow.up.circle.fill"){
                Task{
                    if commentText != "" && commentText.count > 0 {
                       try await submitComment()
                    } else {
                        print("empty Text")
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .foregroundColor(Color(uiColor: .systemBlue))
            .font(.title)
        }
        .alert(error, isPresented: $errorShowing) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func submitComment() async throws {
        guard
            let userId = data.currentUser?.id,
            let clubId = movieClub.id,
            let userName = data.currentUser?.name
        else {
            errorShowing.toggle()
            self.error = "Could not get user information"
            return
        }
        let newComment = Comment(userId: userId, username: userName, date: Date(), text: commentText, likes: 0)
        //could hand back result objects and contionally navigate based on fails
        do {
            try await data.postComment(movieClubId: clubId, movieId: movieId, comment: newComment)
        } catch DataManager.PostCommentError.encodingFailed {
            errorShowing.toggle()
            self.error = "Could not encode comment"
        } catch DataManager.PostCommentError.invalidResponse {
            errorShowing.toggle()
            self.error = "Invalid response from server"
        } catch {
            errorShowing.toggle()
            self.error = "Unknown error"
        }
    }
}
