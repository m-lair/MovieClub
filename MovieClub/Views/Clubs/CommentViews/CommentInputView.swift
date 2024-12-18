import SwiftUI
import FirebaseFunctions
import Firebase

struct CommentInputView: View {
    @Environment(DataManager.self) var data: DataManager
    @State var error: String = ""
    @State var errorShowing: Bool = false
    @State private var commentText: String = ""
    
    let movieId: String
    @Binding var replyToComment: Comment?
    @FocusState private var isFocused: Bool
    var onCommentPosted: () -> Void
    
    var textLabel: String {
        if replyToComment != nil {
            return "Leave a Reply \(replyToComment?.userName ?? "")"
        } else {
            return "Leave a Comment"
        }
    }

    var body: some View {
        VStack {
            HStack {
                TextField(textLabel, text: $commentText, axis: .vertical)
                    .padding(5)
                    .lineLimit(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .focused($isFocused)
                
                Button("", systemImage: "arrow.up.circle.fill") {
                    Task {
                        await submitComment()
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
        commentText = ""
        replyToComment = nil
        isFocused = false
        
        do {
            try await data.postComment(clubId: data.clubId, movieId: movieId, comment: newComment)
            // Clear input fields after successful post
            commentText = ""
            replyToComment = nil
            isFocused = false
            onCommentPosted() // Call the callback after successful comment post
            
        } catch {
            errorShowing.toggle()
            self.error = "Failed to post comment: \(error.localizedDescription)"
        }
    }
}
