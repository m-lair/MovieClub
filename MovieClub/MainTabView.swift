//
//  MainTabView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import SwiftUI


struct MainTabView: View {
    enum Tab {
        case clubsPath,
             discoverPath,
             notificationsPath,
             profilePath
    }
    @Environment(DataManager.self) var data
    @State private var selection: Tab = .clubsPath
    @State var clubsPath = NavigationPath()
    @State var discoverPath = NavigationPath()
    @State var notificationsPath = NavigationPath()
    @State var profilePath = NavigationPath()
    @State private var isLoading = true
    
    var body: some View {
        TabView(selection: tabSelection()){
            Group {
                NavigationStack(path: $clubsPath){
                    HomePageView(navPath: $clubsPath)
                }
                .tabItem {
                    Label("", systemImage: "house.fill")
                        .padding(.top)
                        .fontWeight(.bold)
                }
                .background(ignoresSafeAreaEdges: .all)
                .tag(Tab.clubsPath)
                
                NavigationStack(path: $discoverPath){
                    DiscoverView()
                }
                .tabItem {
                    Label("", systemImage: "magnifyingglass")
                        .padding(.top)
                }
                .tag(Tab.discoverPath)
                
                NavigationStack(path: $notificationsPath){
                    NotificationListView()
                }
                .tabItem {
                    Label("", systemImage: "bell.fill")
                        .padding(.top)
                }
                .tag(Tab.notificationsPath)
                
                NavigationStack(path: $profilePath){
                    ProfileView()
                }
                .tabItem {
                    Label("", systemImage: "person.circle")
                        .padding(.top)
                    
                }
                .tag(Tab.profilePath)
            }
            .toolbarBackground(.gray, for: .navigationBar)
            .background(.black.opacity(0.1))
            .toolbarBackground(.visible, for: .tabBar)
        }
    }
}

//this is working better but double tap still wont send you home
//need a way to set navPath base on the Tab.
//if tapped == self.selected, rest that Stack
extension MainTabView {
    private func tabSelection() -> Binding<Tab> {
        Binding { //this is the get block
            self.selection
        } set: { tappedTab in
            if tappedTab == self.selection {
                // Reset the navigation stack for the current tab
                switch tappedTab {
                case .clubsPath:
                    self.clubsPath = NavigationPath()
                case .discoverPath:
                    self.discoverPath = NavigationPath()
                case .notificationsPath:
                    self.notificationsPath = NavigationPath()
                case .profilePath:
                    self.profilePath = NavigationPath()
                }
            }
            // Set the tab to the selected tab
            self.selection = tappedTab
        }
    }
}
