//
//  CreateSuggestion.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/15/24.
//

import SwiftUI

struct CreateSuggestionView: View {
    @Environment(DataManager.self) var data
    @Environment(\.dismiss) var dismiss
    
    @State var search: String = ""
    @FocusState var isSearching: Bool
    @State var searchResults: [APIMovie] = []
    @State var suggestions: [Suggestion] = []
    @State var isShowingSuggestions = false
    @State var imdbId: String? = ""
    
    
    @State var errorMessage: String = ""
    @State var errorShowing: Bool = false
    
    var body: some View {
        VStack {
            Text("Create Suggestion")
                .font(.title)
                .padding()
            
            TextField("Search for a movie", text: $search)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isSearching)
                .onChange(of: search) {
                    Task {
                       try await searchMovies(query: search)
                    }
                }
            
            if isSearching {
                ProgressView()
                    .padding()
            } else {
                List(searchResults, id: \.imdbId) { movie in
                    Button{
                        Task {
                            try await submitSuggestion()
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(movie.title)
                                .font(.headline)
                            Text(movie.year)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(errorMessage, isPresented: $errorShowing) {
            Button("OK", role: .cancel) { }
        }
    }
    
    struct SearchResponse: Decodable {
        let search: [APIMovie]
        let totalResults: String
        let response: String
        
        enum CodingKeys: String, CodingKey {
            case search = "Search"
            case totalResults
            case response = "Response"
        }
    }

    func searchMovies(query: String) async throws -> [APIMovie] {
        guard !query.isEmpty else { return [] }
        
        let formattedQuery = query.replacingOccurrences(of: " ", with: "+")
        let urlString = "https://omdbapi.com/?s=\(formattedQuery)&apikey=ab92d369"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("Bad server response: \(response)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        do {
            let searchResponse = try decoder.decode(SearchResponse.self, from: data)
            return searchResponse.search
        } catch {
            print("Failed to decode search response: \(error)")
            throw URLError(.cannotParseResponse)
        }
    }
    
    func submitSuggestion() async throws {
        guard
            let clubId = data.currentClub?.id,
            let username = data.currentUser?.name,
            let imdbId
        else {
            errorMessage = "invalid user data"
            errorShowing = true
            return
        }
        let newSuggestion = Suggestion(imdbId: imdbId, userImage: "image", username: username, clubId: clubId)
        
        let _ = try await data.createSuggestion(suggestion: newSuggestion)
        dismiss()
    }
}
