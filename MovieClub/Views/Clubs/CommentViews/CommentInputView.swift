import SwiftUI
import FirebaseFunctions
import Firebase

struct CommentInputView: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State var error: String = ""
    @State var errorShowing: Bool = false
    @State private var commentText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showSuccessIndicator: Bool = false
    @State private var showCheckmark: Bool = false
    
    let movieId: String
    @Binding var replyToComment: Comment?
    @FocusState private var isFocused: Bool
    var onCommentPosted: () -> Void
    
    // Character limit
    private let maxCharacterCount: Int = 500
    
    var textLabel: String {
        if let comment = replyToComment {
            return "Reply to \(comment.userName)"
        } else {
            return "Leave a comment"
        }
    }
    
    private var isCommentValid: Bool {
        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedText.isEmpty && trimmedText.count <= maxCharacterCount
    }
    
    private var submitButtonLabel: String {
        isSubmitting ? "Posting..." : "Post"
    }
    
    private var characterCount: Int {
        commentText.count
    }
    
    private var characterCountColor: Color {
        if characterCount > maxCharacterCount {
            return .red
        } else if characterCount > maxCharacterCount * 0 {
            return .gray
        } else {
            return .gray
        }
    }
    
    // Haptic feedback manager
    private let feedbackGenerator = UINotificationFeedbackGenerator()

    var body: some View {
        VStack(spacing: 8) {
            if replyToComment != nil {
                HStack {
                    Text("Replying to \(replyToComment?.userName ?? "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            replyToComment = nil
                            commentText = ""
                        }
                        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                        impactGenerator.impactOccurred()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 5)
            }
            
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField(textLabel, text: $commentText, axis: .vertical)
                        .padding(10)
                        .lineLimit(5)
                        .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        .focused($isFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            if isCommentValid && !isSubmitting {
                                Task {
                                    await submitComment()
                                }
                            }
                        }
                        .padding(.leading, 2)
                    
                    // Character count indicator
                    HStack {
                        Spacer()
                        Text("\(characterCount)/\(maxCharacterCount)")
                            .font(.caption2)
                            .foregroundStyle(characterCountColor)
                            .padding(.trailing, 4)
                    }
                }
                
                Button {
                    feedbackGenerator.prepare()
                    Task {
                        await submitComment()
                    }
                } label: {
                    ZStack {
                        if showCheckmark {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.green)
                        } else if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title)
                        }
                    }
                    .frame(width: 30, height: 30)
                }
                .padding(.top, 4)
                
                .foregroundStyle(
                    isCommentValid 
                    ? LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .disabled(!isCommentValid || isSubmitting || showCheckmark)
                .accessibilityLabel(submitButtonLabel)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 2)
        }
        .background(.clear)
        .alert(error, isPresented: $errorShowing) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            if replyToComment != nil {
                isFocused = true
            }
            feedbackGenerator.prepare()
        }
    }
    
    private func submitComment() async {
        guard isCommentValid else { 
            if characterCount > maxCharacterCount {
                errorShowing = true
                error = "Comment exceeds maximum character limit of \(maxCharacterCount)"
                feedbackGenerator.notificationOccurred(.error)
            }
            return 
        }
        
        guard let userId = data.currentUser?.id else {
            errorShowing.toggle()
            self.error = "Could not get user ID"
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        
        isSubmitting = true
        
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
            
            // Show checkmark animation
            isSubmitting = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showCheckmark = true
            }
            
            feedbackGenerator.notificationOccurred(.success)
            
            // Clear input fields after successful post
            commentText = ""
            replyToComment = nil
            isFocused = false
            onCommentPosted() // Call the callback after successful comment post
            
            // Add a delay before hiding the checkmark
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay
            
            withAnimation {
                showCheckmark = false
            }
            
            
        } catch {
            isSubmitting = false
            errorShowing.toggle()
            self.error = "Failed to post comment: \(error.localizedDescription)"
            feedbackGenerator.notificationOccurred(.error)
        }
    }
}
