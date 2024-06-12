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
    var movieclub: MovieClub
    var body: some View {
        VStack {
            Spacer()
            ZStack(alignment: .bottom) {
                TextField("leave a comment", text: $commentText, axis: .vertical)
                    .padding(.trailing, 25)
                    .padding(9)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(lineWidth: 1.0)
                            .foregroundStyle(Color(uiColor: .clear))
                            .background(Color.gray.opacity(0.1)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                            )
                    )
                    .ignoresSafeArea()
                HStack(alignment: .bottom) {
                    Spacer()
                    Button("", systemImage: "arrow.up.circle.fill"){
                        submitComment()
                    }
                    .foregroundColor(Color(uiColor: .systemBlue))
                    .font(.title)
                    .padding(.trailing, 3)
                }.padding(.bottom, 5)
            }
        }.padding()
        
    }
    
    
    @MainActor private func submitComment() {
        guard let profileImage = data.currentUser?.image else {
            print("no profile image")
            return
        }
        let newComment = Comment(id: nil, image: profileImage, username: data.currentUser?.name ?? "Anonymous", date: Date(), text: commentText, likes: 0)
        
        Task {
            await data.postComment(comment: newComment, movieClub: movieclub)
            commentText = ""
            
        }
    }
}


#Preview {
    CommentInputView(movieclub: MovieClub.TestData[0])
}
