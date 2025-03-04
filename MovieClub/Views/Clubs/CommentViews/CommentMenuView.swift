//
//  CommentMenuView.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/25/24.
//

import SwiftUI

struct CommentMenuView: View {
    @Environment(DataManager.self) private var data
    let comment: Comment
    @State private var showReportSheet = false
    @State private var reportReason = ""
    @State private var isProcessing = false
    @State private var showDeleteConfirmation = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private var isCommentOwner: Bool {
        guard let currentUserId = data.currentUser?.id else { return false }
        return comment.userId == currentUserId
    }
    
    var body: some View {
        Menu {
            if isCommentOwner {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Remove Comment", systemImage: "trash")
                }
            } else {
                Button {
                    showReportSheet = true
                } label: {
                    Label("Report Comment", systemImage: "flag")
                }
            }
        } label: {
            if isProcessing {
                ProgressView()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.gray)
                    .padding(8)
                    .contentShape(Rectangle())
            }
        }
        .disabled(isProcessing)
        .confirmationDialog(
            "Remove Comment",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                Task {
                    await anonymizeComment()
                }
            }
            .disabled(isProcessing)
            
            Button("Cancel", role: .cancel) {}
                .disabled(isProcessing)
        } message: {
            Text("This will anonymize your comment. The comment will remain in the thread but your name and profile will be removed.")
        }
        .sheet(isPresented: $showReportSheet) {
            reportView
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private var reportView: some View {
        NavigationStack {
            Form {
                Section(header: Text("Report Reason")) {
                    TextField("Reason for reporting", text: $reportReason, axis: .vertical)
                        .lineLimit(5...)
                        .disabled(isProcessing)
                }
                
                Section {
                    if isProcessing {
                        HStack {
                            Spacer()
                            ProgressView("Submitting report...")
                            Spacer()
                        }
                    } else {
                        Button("Submit Report") {
                            Task {
                                await reportComment()
                            }
                        }
                        .disabled(reportReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                    }
                }
            }
            .navigationTitle("Report Comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showReportSheet = false
                    }
                    .disabled(isProcessing)
                }
            }
            .interactiveDismissDisabled(isProcessing)
        }
        .presentationDetents([.medium])
    }
    
    private func anonymizeComment() async {
        isProcessing = true
        
        // Immediately update the UI for better feedback
        // Store original values in case we need to revert
        let originalUserId = comment.userId
        let originalUserName = comment.userName
        let originalText = comment.text
        let originalImage = comment.image
        let originalLikes = comment.likes
        let originalLikedBy = comment.likedBy
        
        // Update the comment locally for immediate feedback
        comment.userId = "anonymous-user"
        comment.userName = "Deleted User"
        comment.text = "[This comment has been deleted by the user]"
        comment.image = nil
        comment.likes = 0
        comment.likedBy = []
        
        do {
            let result = try await data.anonymizeComment(commentId: comment.id)
            
            isProcessing = false
            
            if let alreadyAnonymized = result["alreadyAnonymized"] as? Bool, alreadyAnonymized {
                alertTitle = "Already Anonymized"
                alertMessage = "This comment was already anonymized."
            } else {
                alertTitle = "Success"
                alertMessage = "Your comment has been anonymized."
                
                // Refresh the comments to update the UI
                // This will trigger the filter to remove anonymized comments without replies
                data.refreshComments()
            }
            
            showAlert = true
        } catch {
            isProcessing = false
            
            // Revert the local changes if the server operation failed
            comment.userId = originalUserId
            comment.userName = originalUserName
            comment.text = originalText
            comment.image = originalImage
            comment.likes = originalLikes
            comment.likedBy = originalLikedBy
            
            alertTitle = "Error"
            alertMessage = "Failed to anonymize comment: \(error.localizedDescription)"
            showAlert = true
            print("Error anonymizing comment: \(error)")
        }
    }
    
    private func reportComment() async {
        isProcessing = true
        
        do {
            let result = try await data.reportComment(commentId: comment.id, reason: reportReason)
            
            isProcessing = false
            showReportSheet = false
            
            if let alreadyReported = result["alreadyReported"] as? Bool, alreadyReported {
                alertTitle = "Already Reported"
                alertMessage = "You have already reported this comment."
            } else {
                alertTitle = "Report Submitted"
                alertMessage = "Thank you for your report. We'll review it shortly."
            }
            
            showAlert = true
        } catch let error as NSError {
            isProcessing = false
            
            // Handle specific error cases
            if error.domain == "FirebaseFunctions" && error.code == 3 {
                alertTitle = "Cannot Report"
                alertMessage = "You cannot report your own comment."
            } else {
                alertTitle = "Error"
                alertMessage = "Failed to submit report: \(error.localizedDescription)"
            }
            
            showAlert = true
            print("Error reporting comment: \(error)")
        }
    }
} 