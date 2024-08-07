//
//  ContentView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import SwiftUI


struct ContentView: View {
    @Environment(DataManager.self) var data: DataManager
    @State private var isLoading = true
    var body: some View {
        Group{
            if isLoading {
                ProgressView()
            }else{
                if data.userSession != nil {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
        }
        .onAppear{
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
        .environment(DataManager())
}
