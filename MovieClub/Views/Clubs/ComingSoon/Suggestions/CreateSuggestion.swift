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
    @State var isSubmitting: Bool = false

    
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
                .overlay {
                    if isSubmitting {
                        submittingOverlay
                    }
                }
        }
    }
    
    private var submittingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                
                Text("Submitting suggestion...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
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
            gradient: Gradient(colors: [.black, .black, .blue.opacity(0.3)]),
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
                    .foregroundStyle(.secondary)
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
                    .foregroundStyle(.secondary.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    )
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
                MovieResultRow(movie: movie)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical, 4)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
    }
    
    /// Individual movie result row with enhanced design
    private struct MovieResultRow: View {
        let movie: MovieAPIData
        
        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                // Poster thumbnail with shadow and better scaling
                AsyncImage(url: URL(string: movie.poster)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 4)
                    case .failure:
                        Image(systemName: "film")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                            .frame(width: 80, height: 120)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 120)
                            .overlay {
                                ProgressView()
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Enhanced movie info with more details
                VStack(alignment: .leading, spacing: 6) {
                    Text(movie.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text(String(movie.releaseYear))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if movie.runtime > 0 {
                            Text("•")
                                .foregroundStyle(.secondary)
                            
                            Text("\(movie.runtime) min")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if !movie.director.isEmpty && movie.director != "Unknown" {
                        Text("Director: \(movie.director)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !movie.cast.isEmpty {
                        Text("Cast: \(movie.cast.prefix(3).joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Plot with better formatting
                    if !movie.plot.isEmpty {
                        Text(movie.plot)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 2)
            )
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Networking/Logic
extension CreateSuggestionView {
    func searchMovies() async throws {
        guard !search.isEmpty else {
            searchResults = []
            return
        }
        
        // Set searching state
        isSearching = true
        defer { isSearching = false }
        
        // Optional "debounce"
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        guard !search.isEmpty else { return }
        
        do {
            // Fetch movies with enhanced details
            let results = try await data.fetchTMDBMovies(query: search)
            
            // For each movie, try to fetch additional details
            var enhancedResults: [MovieAPIData] = []
            
            for movie in results.prefix(10) { // Limit to first 10 for performance
                if let details = try? await data.tmdb.fetchMovieDetails(movie.id) {
                    enhancedResults.append(details)
                } else {
                    enhancedResults.append(movie)
                }
            }
            
            searchResults = enhancedResults
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
        
        // Set submitting state
        isSubmitting = true
        
        do {
            let newSuggestion = Suggestion(
                imdbId: imdbId,
                userId: userId,
                userImage: "image",
                userName: username,
                clubId: clubId
            )
            
            let _ = try await data.createSuggestion(suggestion: newSuggestion)
            dismiss()
        } catch {
            isSubmitting = false
            errorMessage = "Failed to submit suggestion: \(error.localizedDescription)"
            errorShowing = true
        }
    }
}
