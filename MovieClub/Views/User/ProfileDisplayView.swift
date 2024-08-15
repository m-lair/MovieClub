//
//  ProfileDisplayView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/14/24.
//

import SwiftUI

struct ProfileDisplayView: View {
    @Environment(DataManager.self) private  var data: DataManager
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if let user = data.currentUser {
            if editMode?.wrappedValue.isEditing == false {
                Text(user.name)
                    .font(.title)
                Text(user.bio ?? "")
                Spacer()
                UserMembershipsView()
                Spacer()
                Button {
                    data.signOut()
                } label: {
                    Text("Sign Out")
                        .foregroundStyle(Color(.red))
                        .padding()
                }
                .hidden()
            }
        }
    }
}

#Preview {
    ProfileDisplayView()
}
