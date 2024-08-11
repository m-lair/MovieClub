//
//  ProfileView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct ProfileView: View {
    @Environment(DataManager.self) private  var data: DataManager
    @Environment(\.dismiss) private var dismiss
    @State var showEditView = false
    var body: some View {
        if let user = data.currentUser{
            NavigationStack{
                ProfileHeaderView(user: user)
                Spacer()
                Button {
                    data.signOut()
                    
                } label: {
                    Text("Sign Out")
                        .foregroundStyle(Color(.red))
                        .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showEditView = true
                    }) {
                        Text("Edit")
                    }
                }
            }
            .sheet(isPresented: $showEditView) {
                UserEditView()
            }
        }
    }
}


#Preview {
    ProfileView()
        .environment(DataManager())
}
