//
//  HomeView.swift
//  MovieClub
//
//  Created by Marcus Lair on 2/1/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(DataManager.self) var dataManager
    @State private var previouslyLoggedIn: Bool = false
    
    var body: some View {
        Group {
            if dataManager.currentUser != nil {
                MainTabView()
                  /*  .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)),removal: .opacity.combined(with: .move(edge: .leading))))
                    .onAppear {
                        previouslyLoggedIn = true
                    }*/
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            Task {
                try await dataManager.fetchUser()
            }
        }
    }
}
