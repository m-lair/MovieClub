//
//  UserEditView.swift
//  MovieClub
//
//  Created by Marcus Lair on 6/24/24.
//

import SwiftUI
//change editMode to only be used on lists
//will need a dedicated edit/save
//do it like instagram

struct UserEditView: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editMode) private var editMode
    @State var errorMessage: String = ""
    @State var errorShowing: Bool = false
    @State var name: String = ""
    @State var bio: String = ""
    
    var body: some View {
        VStack(spacing: 10){
            if let user = data.currentUser {
                Text(user.bio ?? "")
                    .font(.caption)
                    .frame(width: 200, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray, lineWidth: 1)
                    )
                
                Button {
                    guard let userId = user.id else { return }
                    Task {
                        try await data.deleteUserAccount(userId: userId)
                        data.authCurrentUser = nil
                    }
                } label: {
                    Text("Delete Account")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
        }
        .alert(errorMessage, isPresented: $errorShowing) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func submit() async throws {
        if editMode?.wrappedValue.isEditing == false {
            if name.isEmpty || bio.isEmpty { return }
            guard let userUpdates = data.currentUser else { return }
            do {
                userUpdates.name = name
                userUpdates.bio = bio
                try await data.updateUserDetails(user: userUpdates)
                data.currentUser = userUpdates
                dismiss()
            } catch let error as NSError {
                print(error)
                errorMessage = error.localizedDescription
                errorShowing = true
            }
        }
    }
}
