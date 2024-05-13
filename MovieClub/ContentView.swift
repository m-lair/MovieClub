//
//  ContentView.swift
//  Movie Club
//
//  Created by Marcus Lair on 5/6/24.
//

import SwiftUI
import Observation

struct ContentView: View {
    @Environment(DataManager.self) private var data
    var body: some View {
        if data.userSession != nil {
            let _ = print("User session not null \(data.userSession)")
            HomePageView(movies: data.movies)
            
        } else {
            let _ = print("before login view")
            LoginView()
           
        }
    }
    }


#Preview {
    ContentView()
}
