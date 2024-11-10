//
//  ProfileDisplayView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/14/24.
//

import SwiftUI

struct ProfileDisplayView: View {
    @Environment(DataManager.self) private  var data
    @Environment(AuthManager.self) private var auth
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) private var dismiss
    
    let tabs: [String] = ["Clubs", "Collection"]
    @State var selectedTabIndex: Int = 0
    var body: some View {
        VStack {
            if let user = data.currentUser {
                if editMode?.wrappedValue.isEditing == false {
                    Text(user.name)
                        .font(.title)
                    Text(user.bio ?? "")
                    
                    ClubTabView(tabs: tabs, selectedTabIndex: $selectedTabIndex)
                    
                    TabView(selection: $selectedTabIndex) {
                        UserMembershipsView()
                            .tag(0)
                        UserCollectionView()
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    Button {
                        auth.signOut()
                    } label: {
                        Text("Sign Out")
                            .foregroundStyle(Color(.red))
                            .padding()
                    }
                    .hidden()
                }
            }
        }
        .toolbar {
            NavigationLink(destination: UserSettingsView()) {
                Image(systemName: "gearshape")
            }
        }
    }
}
