//
//  HomeView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import SwiftUI

struct HomeView: View {
    @Environment(DataManager.self) var dataManager
    @State private var previouslyLoggedIn: Bool = false
    
    var body: some View {
        ZStack {
            if let user = dataManager.currentUser {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                    .onAppear {
                        previouslyLoggedIn = true
                    }
            } else {
                LoginView()
                    .transition(.asymmetric(
                        insertion: previouslyLoggedIn ? 
                            .opacity.combined(with: .move(edge: .leading)) : 
                            .opacity,
                        removal: .opacity.combined(with: .move(edge: .trailing))
                    ))
                    .onAppear {
                        previouslyLoggedIn = false
                    }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: dataManager.currentUser != nil)
    }
}
