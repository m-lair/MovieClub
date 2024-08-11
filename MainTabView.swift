//
//  MainTabView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/14/24.
//

import SwiftUI


struct MainTabView: View {
    enum Tab {
        case clubsPath, discoverPath, profilePath
    }
    //fixing navigation to be observable
    @Environment(DataManager.self) var data: DataManager
    @State private var selection: Tab = .clubsPath
    @State var navPath = NavigationPath()
    var body: some View {
        TabView(selection: $selection){
            Group {
                NavigationStack(path: $navPath){
                    HomePageView(navPath: $navPath, userClubs: data.userMovieClubs)
                }
                .tabItem {
                    Label("", systemImage: "house.fill")
                        .padding(.top)
                }
                .background(Color.gray)
                .background(ignoresSafeAreaEdges: .all)
                .tag(Tab.clubsPath)
                
                NavigationStack(path: $navPath){
                    DiscoverView()
                }
                .tabItem {
                    Label("", systemImage: "magnifyingglass")
                        .padding(.top)
                }
                .tag(Tab.discoverPath)
                NavigationStack(path: $navPath){
                    ProfileView()
                }
                .tabItem {
                    Label("", systemImage: "person.fill")
                        .padding(.top)
                    
                }
                .tag(Tab.profilePath)
            }
            .toolbarBackground(.gray, for: .navigationBar)
            .toolbarBackground(.black, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            
        }
        .onAppear {
            Task {
                await data.fetchUser()
            }
        }
    }
}
    
extension MainTabView {
 private func tabSelection() -> Binding<Tab> {
    Binding { //this is the get block
     self.selection
    } set: { tappedTab in
     if tappedTab == self.selection {
         self.navPath = NavigationPath()
     }
     //Set the tab to the tabbed tab
     self.selection = tappedTab
    }
 }
}

#Preview {
    MainTabView()
        .environment(DataManager())
}
