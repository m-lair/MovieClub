//
//  AddMovieView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/3/24.
//

import SwiftUI

struct AddMovieView: View {
    @Environment(DataManager.self) var data: DataManager
    @Environment(\.dismiss) private var dismiss
    @State var searchText = ""
    @State var movieList: [MovieClub.Movie] = []
    var filteredMovies: [MovieClub.Movie] {
        if searchText.isEmpty {
            movieList
        } else {
            movieList.filter { $0.title.localizedStandardContains(searchText)}
        }
    }
    var body: some View {
        VStack{
            //search bar results view
            List(filteredMovies){movie in
                MovieRow(movie: movie)
                    .onTapGesture {
                        
                    }
            }
            .searchable(text: $searchText)
        }
    
    }
    
}


#Preview {
    AddMovieView()
}
