//
//  ProfileDisplayView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/14/24.
//

import SwiftUI

struct ProfileDisplayView: View {
    @Environment(DataManager.self) private var data
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) private var dismiss
    
    let tabs: [String] = ["Clubs", "Collection"]
    @State var selectedTabIndex: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                if let user = data.currentUser, !isEditing {
                    // Basic Info
                    Text(user.name)
                        .font(.title)
                    Text(user.bio ?? "")
                    
                    // Custom tab bar
                    ClubTabView(tabs: tabs, selectedTabIndex: $selectedTabIndex)
                        .frame(maxHeight: 30)
                    // Actual pages
                    TabView(selection: $selectedTabIndex) {
                        UserMembershipsView()
                            .tag(0)
                        UserCollectionView()
                            .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Sign Out (hidden?)
                    Button {
                        data.signOut()
                    } label: {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                    .hidden()
                }
            }
            .padding()
            .navigationTitle("Profile")
            .toolbar {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                }
            }
            // Remove bottom safe area if desired
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }
}
