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
        VStack{
            AviSelector()
            ProfileDisplayView()
            Button {
                data.signOut()
            } label: {
                Rectangle()
                    .foregroundColor(.red)
                    .frame(width: 100, height: 30)
                    .padding()
                    .overlay(content: { Text("Sign Out") })
            }
        }
        .navigationTitle("Profile")
    }
}


#Preview {
    ProfileView()
        .environment(DataManager())
}
