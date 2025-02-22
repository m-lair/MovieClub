//
//  ProfileDisplayView.swift
//  MovieClub
//
//  Created by Marcus Lair on 8/14/24.
//

import SwiftUI
import FirebaseAuth

struct ProfileDisplayView: View {
    @Environment(DataManager.self) private var data
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) private var dismiss
    let user: User?
    let tabs: [String] = ["Clubs", "Collection"]
    
    @State var selectedTabIndex: Int = 0
    
    var body: some View {
        VStack {
            if let user, !isEditing {
                // Basic Info
                Text(user.name)
                    .font(.title)
                Text(user.bio ?? "")
                
                // Custom tab bar
                ClubTabView(tabs: tabs, selectedTabIndex: $selectedTabIndex)
                    .frame(maxHeight: 30)
                // Actual pages
                TabView(selection: $selectedTabIndex) {
                    UserMembershipsView(userId: user.id)
                        .tag(0)
                    UserCollectionView(userId: user.id)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .navigationTitle("Profile")
        .toolbar {
            if user?.id == Auth.auth().currentUser?.uid {
                ToolbarItem(placement: .topBarTrailing){
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        // Remove bottom safe area if desired
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
    }
}
