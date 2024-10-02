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
    @State private var changes: [String: String] = [:]
    @State var name: String = ""
    @State var bio: String = ""
    var body: some View {
        VStack{
            if let user = data.currentUser {
                if editMode?.wrappedValue.isEditing == true {
                    Form {
                        TextField("Name", text: $name, prompt: Text(user.name))
                            .onChange(of: name) {
                                   changes["name"] = name
                               }
                        TextField("Bio", text: $bio)
                            .onChange(of: bio) {
                                   changes["bio"] = bio
                               }
                    }
                }
            }
        }
        .onChange(of: editMode?.wrappedValue) {
            Task{
                if editMode?.wrappedValue.isEditing == true {
                    print("is editing true")
                }
                if editMode?.wrappedValue.isEditing == false {
                    if !changes.isEmpty {
                        do {
                            print("in try update")
                            try await data.updateUserDetails(changes: changes)
                        }catch{
                            print(error)
                        }
                    }
                    
                }
            }
            
        }
        
    }
}
