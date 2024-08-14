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
    @Binding var name: String
    @Binding var bio: String
    var body: some View {
        VStack{
            if let user = data.currentUser {
                if editMode?.wrappedValue.isEditing == true {
                    Form {
                        TextField("Name", text: $name, prompt: Text(user.name))
                        TextField("Bio", text: $name)
                    }
                }
                
            }
        }
        .onChange(of: editMode?.wrappedValue) {
            if editMode?.wrappedValue.isEditing == true {
                print("is editing true")
            }
            if editMode?.wrappedValue.isEditing == false {
                var changes: [String] = []
                var attrs = ["name", "bio"]
                if name != data.currentUser?.name && !name.isEmpty{
                    // the field isnt empty and also doesnt equal the current username
                    //update
                    changes.append("name")
                    
                }
            }
        }
        
    }
}
