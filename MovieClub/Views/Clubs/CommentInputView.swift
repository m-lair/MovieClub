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
    @State private var commentText: String = ""
    var movieClub: MovieClub
    @State var movieID: String
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
    }
    
    private func submitComment() async throws {
        guard
            let userID = data.currentUser?.id,
            let clubID = movieClub.id,
            let userName = data.currentUser?.name,
            let imageURL = data.currentUser?.image
        else { return }
        
        let functions = Functions.functions()
        let result = try await functions.httpsCallable("postComment").call([
            "userID": userID,
            "userName": userName,
            "imageURL": imageURL,
            "clubID": clubID,
            "text": commentText
        ])
    }
}
