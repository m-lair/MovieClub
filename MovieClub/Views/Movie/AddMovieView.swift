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
    @State var searchBar = true
    @State var selectedMovie: APIMovie?
    var onSave: (APIMovie) -> Void
    var date: Date?
    var index: Int?
    @State var movieList: [APIMovie] = []
    var filteredMovies: [APIMovie] {
        guard !searchText.isEmpty else { return movieList }
        return movieList.filter { $0.title.localizedStandardContains(searchText) }
    }
    var body: some View {
        NavigationStack{
            List(filteredMovies, id: \.self){ movie in
                //  let _ = print("movie: \(movie)")
                MovieRow(movie: movie) { selectedMovie in
                    onSave(selectedMovie)
                }
                // Text("\(movie.title)")
            }
            .searchable(text: $searchText, prompt: "Add Movie")
            .navigationTitle("Add Movies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button{
                        if let selectedMovie {
                            let _ = print("selected Movie \(selectedMovie)")
                            onSave(selectedMovie)
                        }
                    } label: {
                        Text("Save")
                    }
                }
            }
        }
        .onSubmit(of: .search){
            searchMovies()
        }
        
    }
    
    
    
    private func searchMovies() {
        guard !searchText.isEmpty else {
            return
        }
        Task {
            do {
                let apiMovies = try await fetchMovies(from: searchText)
                // print("in search movies")
                // print("movieList: \(movieList)")
                self.movieList = apiMovies
            } catch {
                print("Failed to fetch movies: \(error)")
            }
        }
    }
    
    private func fetchMovies(from searchText: String) async throws -> [APIMovie] {
        // print("in fetch Movies")
        let formattedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchText
        let urlString = "https://omdbapi.com/?s=\(formattedSearchText)&type=movie&apikey=ab92d369"
        //print("urlString \(urlString)")
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Bad server response: \(response)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let apiResponse = try decoder.decode(OMDBSearchResponse.self, from: data)
            //print("data \(apiResponse)")
            return apiResponse.search.map { apiMovie in
                APIMovie(
                    id: apiMovie.id,
                    title: apiMovie.title,
                    released: apiMovie.released,
                    director: apiMovie.director,
                    poster: apiMovie.poster
                    //plot: apiMovie.plot
                )
            }
        } catch {
            print("Failed to decode API response: \(error)")
            throw URLError(.cannotParseResponse)
        }
    }
}


