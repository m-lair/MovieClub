//
//  MainTabView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/14/24.
//

import SwiftUI

class NavigationViewModel: ObservableObject {
    @Published var clubsPath = NavigationPath()
    @Published var discoverPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    
    func resetClubsPath() {
        clubsPath = NavigationPath()
    }
    
    func resetDiscoverPath() {
        discoverPath = NavigationPath()
    }
    
    func resetProfilePath() {
        profilePath = NavigationPath()
    }
}

struct MainTabView: View {
    @StateObject private var navigationViewModel = NavigationViewModel()
    enum Tab {
        case clubsPath, discoverPath, profilePath
    }
    @Environment(DataManager.self) var data: DataManager
    @State private var selection: Tab = .clubsPath
    var body: some View {
        TabView(selection: $selection){
            Group {
                NavigationStack(path: $navigationViewModel.clubsPath){
                    HomePageView(userClubs: data.userMovieClubs)
                        
                }
                .tabItem {
                    Label("", systemImage: "house.fill")
                }
                .background(Color.gray)
                .background(ignoresSafeAreaEdges: .all)
                
                .tag(Tab.clubsPath)
                NavigationStack(path: $navigationViewModel.discoverPath){
                    DiscoverView()
                }
                .tabItem {
                    Label("", systemImage: "magnifyingglass")
                }
                .tag(Tab.discoverPath)
                NavigationStack(path: $navigationViewModel.profilePath){
                    ProfileView()
                }
                .tabItem {
                    Label("", systemImage: "person.fill")
                    
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
