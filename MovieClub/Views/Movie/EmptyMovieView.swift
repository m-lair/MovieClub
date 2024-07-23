//
//  EmptyMovieView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/22/24.
//

import SwiftUI

struct EmptyMovieView: View {
    var body: some View {
        Text("No Movies Coming Up Yet...")
        NavigationLink {
            AddMovieView()
        } label: {
            Text("Add One")
        }
    }
}

#Preview {
    EmptyMovieView()
}
