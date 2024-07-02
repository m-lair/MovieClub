//
//  ProfileView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct ProfileView: View {
    @Environment(DataManager.self) private  var data: DataManager
    @State var showEditView = false
    var body: some View {
        NavigationStack{
            ProfileHeaderView(user: data.currentUser!)
            Spacer()
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
