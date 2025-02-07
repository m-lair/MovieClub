//
//  HomeView.swift
//  MovieClub
//
//  Created by Marcus Lair on 2/1/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(DataManager.self) var dataManager
    
    var body: some View {
        if let user = dataManager.currentUser {
            MainTabView()
        } else {
            LoginView()
        }
    }
}
