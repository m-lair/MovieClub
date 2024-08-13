//
//  ProfileHeaderView.swift
//  MovieClub
//
//  Created by Marcus Lair on 6/24/24.
//

import SwiftUI

struct ProfileHeaderView: View {
    @Environment(\.editMode) private var editMode
    let user: User
    @State private var name = ""
    @State private var bio = ""
    
    var body: some View {
        Form {
            if editMode?.wrappedValue.isEditing == true {
                TextField("Name", text: $name)
                TextField("Bio", text: $bio)
                
            } else {
                Text(user.name)
                Text(user.bio ?? "")
                
            }
        }
        .animation(nil, value: editMode?.wrappedValue)
        .toolbar { // Assumes embedding this view in a NavigationView.
            EditButton()
        }
    }
}
   
#Preview {
    ProfileHeaderView(user: User(email: "Test@gmail", bio: "the bio", name: "hodor", password: ""))
}
