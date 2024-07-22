//
//  ScrollViewContent.swift
//  MovieClub
//
//  Created by Marcus Lair on 6/17/24.
//

import SwiftUI

struct ScrollViewContent: View {
    @Environment(DataManager.self) var data: DataManager
    @Binding var path: NavigationPath
    var body: some View {
        LazyVStack(spacing: 20) {
            ForEach(data.userMovieClubs) { movieClub in
                NavigationLink(destination: ClubDetailView(movieClub:movieClub, path: $path) ){
                    MovieClubCardView(movieClub: movieClub)
                }
                .navigationTitle("Clubs")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: NewClubView(path:$path)) {
                            Image(systemName: "plus")
                                .imageScale(.large)
                        }
                    }
                }
            }
        }
    }
}
   

