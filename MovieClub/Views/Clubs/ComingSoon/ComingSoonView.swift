//
//  RosterView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/20/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ComingSoonView: View {
    @Environment(DataManager.self) var data: DataManager

    @State private var creatingSuggestion = false
    @State private var isLoading = false
    @State private var error: Error?
    @State private var movieDetails: [String: MovieAPIData] = [:]
    @State private var deletingIds: Set<String> = []

    let startDate: Date?
    let timeInterval: Int
    var clubId: String { data.clubId }
    var canSuggest: Bool { !suggestions.contains(where: { $0.userId == currentUserId }) }
    var suggestions: [Suggestion] { data.suggestions }
    var currentUserId: String { Auth.auth().currentUser?.uid ?? "" }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .padding()
                Text("Loading suggestions...")
                    .foregroundStyle(.secondary)
            } else if suggestions.isEmpty {
                VStack {
                    Text("No Suggestions Yet")
                        .font(.title2)
                        .padding()
                    
                    Text("Be the first to suggest a movie for your club!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom)
                    
                    newSuggestionButton
                }
            } else {
                suggestionsList
            }
        }
        .refreshable {
            await refreshSuggestions()
        }
        .sheet(isPresented: $creatingSuggestion) {
            CreateSuggestionView()
                .onDisappear {
                    // Refresh movie details when returning from suggestion creation
                    Task {
                        await refreshSuggestions()
                    }
                }
        }
        .alert("Error", isPresented: .constant(error != nil), actions: {
            Button("OK") {
                error = nil
            }
            Button("Retry") {
                Task {
                    await refreshSuggestions()
                }
            }
        }, message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        })
        .task {
            setupSuggestionsListener()
            await refreshSuggestions()
        }
        .onDisappear {
            data.suggestions = []
            data.suggestionsListener?.remove()
            data.suggestionsListener = nil
        }
    }

    private var suggestionsList: some View {
        VStack {
            HStack {
                Text("Suggestions")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("Begins")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding([.horizontal, .top])

            List {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    SuggestionRow(
                        suggestion: suggestion,
                        movieDetails: movieDetails[suggestion.imdbId],
                        isCurrentUser: suggestion.userId == currentUserId,
                        startDate: computedDateString(for: index),
                        isDeleting: deletingIds.contains(suggestion.id ?? ""),
                        onDelete: {
                            Task {
                                await deleteSuggestion(for: suggestion)
                            }
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            if canSuggest {
                newSuggestionButton
                    .padding(.bottom)
            }
        }
    }

    private var newSuggestionButton: some View {
        Button {
            creatingSuggestion = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Create Suggestion")
            }
            .font(.headline)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.8))
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(!canSuggest)
    }

    private func computedDateString(for index: Int) -> String? {
        guard let startDate = startDate else { return nil }
        let weeksToAdd = timeInterval * index
        
        // Add one day and the specified number of weeks in a single operation
        let components = DateComponents(day: 1, weekOfYear: weeksToAdd)
        return Calendar.current.date(byAdding: components, to: startDate)?
            .formatted(date: .abbreviated, time: .omitted)
    }

    private func deleteSuggestion(for suggestion: Suggestion) async {
        guard let id = suggestion.id else { return }
        
        // Add to deleting set to show loading indicator
        deletingIds.insert(id)
        
        do {
            try await data.deleteSuggestion(suggestion: suggestion)
            if let index = data.suggestions.firstIndex(where: { $0.userId == suggestion.userId }) {
                data.suggestions.remove(at: index)
            }
        } catch {
            self.error = error
            print("Error deleting suggestion: \(error)")
        }
        
        // Remove from deleting set
        deletingIds.remove(id)
    }

    private func setupSuggestionsListener() {
        data.listenToSuggestions(clubId: clubId)
    }

    private func refreshSuggestions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let clubId = data.currentClub?.id else { return }
            _ = try await data.fetchSuggestions(clubId: clubId)
            
            // Clear movie details cache and reload
            movieDetails = [:]
            await loadMovieDetails()
        } catch {
            self.error = error
            print("Error refreshing suggestions: \(error)")
        }
    }
    
    private func loadMovieDetails() async {
        for suggestion in suggestions {
            // Only load movie details for the current user's suggestions
            if suggestion.userId == currentUserId && movieDetails[suggestion.imdbId] == nil {
                do {
                    if let details = try await data.tmdb.fetchMovieDetails(suggestion.imdbId) {
                        // Update on the main thread to ensure UI updates properly
                        await MainActor.run {
                            movieDetails[suggestion.imdbId] = details
                        }
                    }
                } catch {
                    print("Error loading movie details for \(suggestion.imdbId): \(error)")
                }
            }
        }
    }
}

// MARK: - SuggestionRow
struct SuggestionRow: View {
    @Environment(DataManager.self) var data
    let suggestion: Suggestion
    let movieDetails: MovieAPIData?
    let isCurrentUser: Bool
    let startDate: String?
    let isDeleting: Bool
    let onDelete: () -> Void
    @State private var userImage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // User info and date
            HStack {
                if let imageUrl = userImage, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding(.horizontal, 3)
                }
                
                Text(suggestion.userName)
                    .font(.headline)
                    .foregroundStyle(isCurrentUser ? .primary : .secondary)
                
                Spacer()
                
                if let startDate = startDate {
                    Text(startDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if isCurrentUser {
                    if isDeleting {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.leading, 8)
                    } else {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                                .padding(.leading, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Movie details section
            if isCurrentUser {
                if let movie = movieDetails {
                    // Current user can see their own suggestion details
                    HStack(alignment: .top, spacing: 12) {
                        // Movie poster
                        AsyncImage(url: URL(string: movie.poster)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 70, height: 105)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(radius: 2)
                            case .failure:
                                Image(systemName: "film")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding()
                                    .frame(width: 70, height: 105)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .empty:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 70, height: 105)
                                    .overlay {
                                        ProgressView()
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        // Movie info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(movie.title)
                                .font(.headline)
                                .lineLimit(1)
                            
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
                                    .lineLimit(1)
                            }
                            
                            if !movie.plot.isEmpty {
                                Text(movie.plot)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .padding(.top, 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                } else {
                    // Loading state when movie details aren't available yet
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        
                        Text("Loading movie details...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
            } else {
                // Mystery view for other users' suggestions
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mystery Movie")
                            .font(.headline)
                        
                        Text("This suggestion will be revealed when it's time to watch!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
        .task {
            do {
                userImage = try await data.getProfileImage(userId: suggestion.userId)
            } catch {
                print("Error loading user image: \(error)")
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(radius: 2)
        )
    }
}
