//
//  MovieClubScrollView.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/13/24.
//

import SwiftUI

struct MovieClubScrollView: View {
    @Environment(DataManager.self) var data: DataManager
    var body: some View {
        NavigationStack{
            ScrollView(.vertical) {
                ScrollViewContent()
                
            }
            .navigationBarTitle("Movie Clubs", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NewClubView()) {
                        Image(systemName: "plus")
                            .imageScale(.large)
                    }
                }
            }
        }
    }
}



#Preview {
    MovieClubScrollView()
        .environment(DataManager())
}
