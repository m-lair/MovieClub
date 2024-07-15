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
    @State var movieList: [MovieClub.APIMovie] = []
    var filteredMovies: [MovieClub.APIMovie] {
        if searchText.isEmpty {
            return movieList
        } else {
           return movieList.filter { $0.title.localizedStandardContains(searchText)}
        }
    }
    var body: some View {
        NavigationStack{
            VStack{
                //search bar results view
                List(filteredMovies){movie in
                    MovieRow(movie: movie)
                        
                }
                .searchable(text: $searchText)
            }
            .onSubmit(of: .search) {
                searchMovies()
            }
        }
    }
    private func searchMovies() {
        guard !searchText.isEmpty else {
            return
        }
        Task {
            do {
                let apiMovies = try await fetchMovies(from: searchText)
                self.movieList = apiMovies
            } catch {
                print("Failed to fetch movies: \(error)")
            }
        }
    }
    
    private func fetchMovies(from searchText: String) async throws -> [MovieClub.APIMovie] {
        let formattedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchText
        let urlString = "https://omdbapi.com/?s=\(formattedSearchText)&type=movie&apikey=ab92d369"
        print("urlString \(urlString)")
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
            print("data \(data.debugDescription)")
            return apiResponse.search.map { apiMovie in
                MovieClub.APIMovie(
                    id: apiMovie.id,
                    title: apiMovie.title,
                    released: apiMovie.released,
                    director: apiMovie.director, poster: apiMovie.poster
                  //  plot: apiMovie.plot
                )
            }
        } catch {
            print("Failed to decode API response: \(error)")
            throw URLError(.cannotParseResponse)
        }
    }
}

    



#Preview {
    AddMovieView()
}
