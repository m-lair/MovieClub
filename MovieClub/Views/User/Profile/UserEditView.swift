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
        VStack{
            if let user = data.currentUser {
                if editMode?.wrappedValue.isEditing == true {
                    Form {
                        TextField("Name", text: $name, prompt: Text(user.name))
                        TextField("Bio", text: $bio, prompt: Text(user.bio ?? "No bio yet"))
                    }
                }
            }
        }
        .onChange(of: editMode?.wrappedValue) {
            Task{
               try await submit()
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
