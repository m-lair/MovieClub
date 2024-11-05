//
//  CreateSuggestion.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/15/24.
//

import SwiftUI

extension DataManager {
    
}

struct CreateSuggestionView: View {
    @Environment(DataManager.self) var data
    @Environment(\.dismiss) var dismiss
    
    @State var search: String = ""
    @FocusState var isSearching: Bool
    @State var searchResults: [MovieSearchResult] = []
    @State var suggestions: [Suggestion] = []
    @State var isShowingSuggestions = false
    
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
                      try await searchMovies()
                    }
                }
            
            if isSearching {
               
            } else {
                List(searchResults, id: \.id) { movie in
                    Button{
                        Task {
                            try await submitSuggestion(imdbId: movie.id)
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


    func searchMovies() async throws {
        guard !search.isEmpty else {
            searchResults = []
            return
        }
        
        // Debounce search
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Check if search text hasn't changed
        guard search == search else { return }
        
        do {
            searchResults = try await data.searchMovies(query: search)
        } catch {
            // do nothing
        }
    }
    
    func submitSuggestion(imdbId: String) async throws {
        guard
            let clubId = data.currentClub?.id,
            let username = data.currentUser?.name,
            let userId = data.currentUser?.id
        else {
            errorMessage = "invalid user data"
            errorShowing = true
            return
        }
        let newSuggestion = Suggestion(imdbId: imdbId, userId: userId, userImage: "image", userName: username, clubId: clubId)
        let _ = try await data.createSuggestion(suggestion: newSuggestion)
        data.currentClub?.suggestions?.append(newSuggestion)
        dismiss()
    }
}
