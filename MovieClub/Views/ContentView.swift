//
//  ContentView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import SwiftUI


struct ContentView: View {
    @Environment(DataManager.self) var data: DataManager
    var body: some View {
        if data.userSession != nil {
            TabView {
                HomePageView()
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
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}
