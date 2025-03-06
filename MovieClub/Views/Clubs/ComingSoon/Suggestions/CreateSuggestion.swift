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
    @State private var isSearchLoading: Bool = false
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            content
                .alert(errorMessage, isPresented: $errorShowing) {
                    Button("OK", role: .cancel) {}
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .overlay {
                    if isSubmitting {
                        submittingOverlay
                    }
                }
                .onDisappear {
                    // Cancel any pending tasks when view disappears
                    searchTask?.cancel()
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
            searchResultsContent
        }
        .padding(.bottom, 16)
    }
    
    /// The search field
    private var searchTextField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search for a movie", text: $search)
                .submitLabel(.search)
                .focused($isSearching)
                .onChange(of: search) {
                    debounceSearch()
                }
                .onSubmit {
                    searchWithImmediateFeedback()
                }
            
            if !search.isEmpty {
                Button {
                    search = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: !search.isEmpty)
            }
        }
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
    }
    
    /// Content view for search results or appropriate placeholder
    @ViewBuilder
    private var searchResultsContent: some View {
        if !searchResults.isEmpty {
            resultsList
        } else if isSearchLoading {
            Spacer()
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("Searching...")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        } else if !search.isEmpty && searchResults.isEmpty && !isSearchLoading {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "film.stack")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No movies found")
                    .font(.headline)
                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        } else {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
                Text("Search for a movie to suggest")
                    .font(.headline)
            }
            Spacer()
        }
    }
    
    /// The list of search results
    private var resultsList: some View {
        List(searchResults, id: \.id) { movie in
            Button {
                submitSuggestionForMovie(movie)
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
    /// Debounces the search to prevent excessive API calls
    private func debounceSearch() {
        // Cancel any pending search
        searchTask?.cancel()
        
        // If search is empty, clear results immediately
        if search.isEmpty {
            searchResults = []
            isSearchLoading = false
            return
        }
        
        isSearchLoading = true
        searchTask = Task {
            do {
                // Use Swift 6 style sleep with Duration
                try await Task.sleep(for: .milliseconds(500))
                
                // Check if task was cancelled during wait
                if !Task.isCancelled {
                    try await performSearch()
                }
            } catch is CancellationError {
                // Task was cancelled, no action needed
            } catch {
                // Some other error occurred
                handleSearchError(error)
            }
        }
    }
    
    /// Handle search errors on the main actor
    private func handleSearchError(_ error: Error) {
        errorMessage = "Search error: \(error.localizedDescription)"
        errorShowing = true
        isSearchLoading = false
    }
    
    /// Immediately execute search with feedback (for submit button)
    private func searchWithImmediateFeedback() {
        Task {
            do {
                try await performSearch(immediate: true)
            } catch {
                handleSearchError(error)
            }
        }
    }
    
    /// Submit suggestion for a selected movie
    private func submitSuggestionForMovie(_ movie: MovieAPIData) {
        Task {
            do {
                try await submitSuggestion(imdbId: movie.id)
            } catch {
                handleSubmissionError(error)
            }
        }
    }
    
    private func handleSubmissionError(_ error: Error) {
        let displayError = error as? SuggestionError ?? SuggestionError.submissionFailed(error)
        errorMessage = displayError.errorDescription ?? error.localizedDescription
        errorShowing = true
        isSubmitting = false
    }
    
    /// Core search implementation with structured concurrency
    private func performSearch(immediate: Bool = false) async throws {
        guard !search.isEmpty else {
            searchResults = []
            isSearchLoading = false
            return
        }
        
        // Skip additional delay for immediate searches
        if !immediate {
            try await Task.sleep(for: .milliseconds(300))
        }
        
        guard !search.isEmpty, !Task.isCancelled else { return }
        
        isSearchLoading = true
        
        
        do {
            // Fetch movies with enhanced details
            let results = try await data.fetchTMDBMovies(query: search)
            try await fetchDetailedMovies(from: results)
        } catch {
            isSearchLoading = false
            throw error
        }
    }
    
    /// Fetch detailed information for movies using task groups
    private func fetchDetailedMovies(from results: [MovieAPIData]) async throws {
        // Early return if task is cancelled
        if Task.isCancelled { return }
        
        // Limit results for performance
        let limitedResults = results.prefix(10).map { $0 }
        
        // Use TaskGroup for parallel movie detail fetching
        try await withThrowingTaskGroup(of: MovieAPIData.self) { group in
            for movie in limitedResults {
                group.addTask {
                    if Task.isCancelled { return movie }
                    
                    // Try to get detailed info, fall back to basic info
                    if let details = try? await self.data.tmdb.fetchMovieDetails(movie.id) {
                        return details
                    } else {
                        return movie
                    }
                }
            }
            
            // Collect results as they complete
            var enhancedResults: [MovieAPIData] = []
            enhancedResults.reserveCapacity(limitedResults.count)
            
            for try await movieData in group {
                enhancedResults.append(movieData)
                
                if enhancedResults.count == limitedResults.count {
                    break
                }
            }
            
            // Check if cancelled before updating UI
            if !Task.isCancelled {
                // Create a dictionary to preserve original order
                let originalIndexMap = Dictionary(uniqueKeysWithValues:
                                                    limitedResults.enumerated().map { ($0.element.id, $0.offset) }
                )
                
                // Sort results to match original order
                let sortedResults = enhancedResults.sorted {
                    guard let index1 = originalIndexMap[$0.id],
                            let index2 = originalIndexMap[$1.id] else {
                        return false
                    }
                    return index1 < index2
                }
                
                searchResults = sortedResults
                isSearchLoading = false
                
            }
        }
    }
    
    func submitSuggestion(imdbId: String) async throws {
        guard
            let clubId = data.currentClub?.id,
            let username = data.currentUser?.name,
            let userId = data.currentUser?.id
        else {
            throw SuggestionError.userDataMissing
        }
        
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
            
            // Dismiss on main actor
            await MainActor.run {
                dismiss()
            }
        } catch {
            // Reset submitting state on main actor
            await MainActor.run {
                isSubmitting = false
            }
            throw error
        }
    }
}

// MARK: - Custom Errors
extension CreateSuggestionView {
    enum SuggestionError: LocalizedError {
        case userDataMissing
        case submissionFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .userDataMissing:
                return "Unable to create suggestion: You need to be logged in and part of a club"
            case .submissionFailed(let error):
                return "Failed to submit suggestion: \(error.localizedDescription)"
            }
        }
    }
}
