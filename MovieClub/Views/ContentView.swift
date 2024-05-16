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
            MainTabView()
        } else {
            LoginView()
        }
    }
}

    

#Preview {
    ContentView()
}
