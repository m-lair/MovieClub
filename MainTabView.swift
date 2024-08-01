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
        case clubs, discover, profile
    }
    @Environment(DataManager.self) var data: DataManager
    @State private var selection: Tab = .clubs
    var body: some View {
       // let _ = print("main tab user session?\(data.userSession?.uid)")
        TabView(selection: $selection){
            NavigationStack(path: $navigationViewModel.clubsPath){
                HomePageView(userClubs: data.userMovieClubs)
                    }
            .tabItem {
                Label("Clubs", systemImage: "house.fill")
            }
            .tag(Tab.clubs)
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(Tab.discover)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                    
                }
                .tag(Tab.profile)
        }
        .environmentObject(navigationViewModel)
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
      //User tapped on the currently active tab icon => Pop to root/Scroll to top
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
