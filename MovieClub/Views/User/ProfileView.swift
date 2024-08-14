//
//  ProfileView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct ProfileView: View {
    @Environment(DataManager.self) private  var data: DataManager
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) private var dismiss
    @State private var edit = false
    @State private var name = ""
    @State private var bio = ""
    var body: some View {
        if let user = data.currentUser{
            VStack{
                AviSelector()
                UserEditView(name: $name, bio: $bio)
                ProfileDisplayView()
            }
            //save data after edit
            .toolbar {
                ToolbarItem {
                    EditButton()
                   /* Button {
                        edit.toggle()
                    } label: {
                        switch edit {
                        case true:
                            Text("Save")
                        case false:
                            Text("Edit")
                        }
                    }*/
                }
                
            }
            .navigationTitle("Profile")
        }
    }
    private func saveUser() {
       
    }
}


#Preview {
    ProfileView()
        .environment(DataManager())
}
