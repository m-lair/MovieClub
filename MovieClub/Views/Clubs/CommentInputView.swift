//
//  CommentInputView.swift
//  MovieClub
//
//  Created by Marcus Lair on 6/10/24.
//

import SwiftUI

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
                        if commentText != "" && commentText.count > 0{
                        await submitComment()
                            data.comments =  await data.fetchComments(movieClubId: movieClub.id ?? "", movieId: movieID)
                        } else {
                            print("empty Text")
                        }
                        
                    }
                }
                .foregroundColor(Color(uiColor: .systemBlue))
                .font(.title)
            }
    }
    
    private func submitComment() async {
        guard let profileImage = await data.currentUser?.image else {
            print("no profile image")
            return
        }
        print("movie club ...")
       
        let newComment = await Comment(id: nil, userID: data.currentUser?.id ?? "", image: profileImage, username: data.currentUser?.name ?? "Anonymous", date: Date(), text: commentText, likes: 0)
        
        Task {
            print(newComment)
            await data.postComment(comment: newComment, movieClubID: movieClub.id ?? "", movieID: movieID)
            commentText = ""
            
            
            
        }
    }
}


#Preview {
    CommentInputView(movieClub: MovieClub.TestData[0], movieID: "")
}
