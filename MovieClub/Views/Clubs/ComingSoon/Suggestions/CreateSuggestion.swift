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
    @State var searchResults: [MovieAPIData] = []
    
    @State var errorMessage: String = ""
    @State var errorShowing: Bool = false
    
    var body: some View {
        NavigationStack {
            content
                .alert(errorMessage, isPresented: $errorShowing) {
                    Button("OK", role: .cancel) {}
                }
                .toolbar {
                    // For a "Cancel" or "Close" button, if desired
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Extracted Subviews/Properties
extension CreateSuggestionView {
    
    /// The entire "body" contents, broken out for clarity
    @ViewBuilder
    private var content: some View {
        ZStack {
            backgroundGradient
            mainVStack
        }
    }
    
    /// The background gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [.gray.opacity(0.2), .red.opacity(0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    /// The primary VStack with title, search field, and list
    @ViewBuilder
    private var mainVStack: some View {
        VStack {
            Text("Create Suggestion")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.top, 16)
            
            searchTextField
            
            if !searchResults.isEmpty {
                resultsList
            } else {
                Spacer()
                Text("Type above to search for a movie...")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.bottom, 16)
    }
    
    /// The search field
    private var searchTextField: some View {
        TextField("Search for a movie", text: $search)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(lineWidth: 3)
            )
            .padding(.horizontal)
            .focused($isSearching)
            .onChange(of: search) {
                Task {
                    try await searchMovies()
                }
            }
    }
    
    /// The list of search results
    private var resultsList: some View {
        List(searchResults, id: \.id) { movie in
            Button {
                Task {
                    try await submitSuggestion(imdbId: movie.id)
                }
            } label: {
                HStack(alignment: .top, spacing: 16) {
                    // Poster thumbnail
                    AsyncImage(url: URL(string: movie.poster)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 90)
                                .cornerRadius(6)
                        default:
                            Color.gray
                                .frame(width: 60, height: 90)
                                .cornerRadius(6)
                        }
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(movie.title)
                            .font(.headline)
                        
                        Text(String(movie.releaseYear))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Optional short snippet of plot
                        if !movie.plot.isEmpty {
                            Text(movie.plot)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }
}

// MARK: - Networking/Logic
extension CreateSuggestionView {
    func searchMovies() async throws {
        guard !search.isEmpty else {
            searchResults = []
            return
        }
        
        // Optional "debounce"
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        guard !search.isEmpty else { return }
        
        do {
            searchResults = try await data.fetchTMDBMovies(query: search)
        } catch {
            errorMessage = "Something went wrong: \(error.localizedDescription)"
            errorShowing = true
        }
    }
    
    func submitSuggestion(imdbId: String) async throws {
        guard
            let clubId = data.currentClub?.id,
            let username = data.currentUser?.name,
            let userId = data.currentUser?.id
        else {
            errorMessage = "Invalid user data"
            errorShowing = true
            return
        }
        
        let newSuggestion = Suggestion(
            imdbId: imdbId,
            userId: userId,
            userImage: "image",
            userName: username,
            clubId: clubId
        )
        
        let _ = try await data.createSuggestion(suggestion: newSuggestion)
        dismiss()
    }
}
