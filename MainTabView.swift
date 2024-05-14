//
//  MainTabView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/14/24.
//

import SwiftUI

struct MainTabView: View {
    @Environment(DataManager.self) var data: DataManager
    
    var body: some View {
        TabView {
            HomePageView(userClubs: data.userMovieClubs)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                    
                }
        }
    }
}

#Preview {
    MainTabView()
}
