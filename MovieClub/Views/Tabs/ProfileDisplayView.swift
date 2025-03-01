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
    
    // If userId is nil, we'll use the current user
    var userId: String?
    
    // Use a computed property to get the correct user
    private var displayUser: User? {
        if let userId = userId {
            return user // Show the fetched user for the specified userId
        } else {
            return data.currentUser // Show the current user if no userId specified
        }
    }
    
    @State private var user: User?
    let tabs: [String] = ["Clubs", "Collection"]
    @State var selectedTabIndex: Int = 0

    var body: some View {
        VStack {
            if let displayUser = displayUser {
                if let imageUrl = displayUser.image, let url = URL(string: imageUrl) {
                    CachedAsyncImage(url: url) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
                    .id(imageUrl) // Use the URL string as the ID
                } else {
                    // Placeholder when no image is available
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                }
                Text(displayUser.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                // Custom tab bar
                ClubTabView(tabs: tabs, selectedTabIndex: $selectedTabIndex)
                    .frame(maxHeight: 30)
                // Actual pages
                TabView(selection: $selectedTabIndex) {
                    UserMembershipsView(userId: displayUser.id)
                        .tag(0)
                    UserCollectionView(userId: displayUser.id)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .navigationTitle("Profile")
        .toolbar {
            if displayUser?.id == Auth.auth().currentUser?.uid {
                ToolbarItem(placement: .topBarTrailing){
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .task {
            if let userId = userId {
                user = try? await data.fetchProfile(id: userId)
            }
        }
        .refreshable {
            if let userId = userId {
                user = try? await data.fetchProfile(id: userId)
            } else {
                await data.refreshUserProfile()
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}
