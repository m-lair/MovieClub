//
//  FirstMovieView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/28/24.
//

import SwiftUI

struct FirstMovieView: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) var dismiss
    var club: MovieClub?
    var body: some View {
        VStack{
            Text("Choose Your First Movie!")
            MoviePosterButtonView()
            Spacer()
            if let club = data.currentClub{
                Button {
                    Task {
                        await data.createMovieClub(movieClub: club)
                    }
                } label: {
                    Text("Submit")
                }
                .padding(.bottom)
            }
        }
    }
}
