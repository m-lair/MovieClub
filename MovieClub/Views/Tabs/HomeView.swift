//
//  HomeView.swift
//  MovieClub
//
//  Created by Marcus Lair on 2/1/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(DataManager.self) var dataManager
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                WaveLoadingView()
            } else if dataManager.currentUser != nil {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            Task {
                // Replace this with your actual async logic for checking the user state
                try await dataManager.fetchUser()
                isLoading = false
            }
        }
    }
}
