//
//  RosterView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/20/24.
//

import SwiftUI
import FirebaseFirestore

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ComingSoonView: View {
    @Environment(DataManager.self) var data: DataManager

    @State private var creatingSuggestion = false
    @State private var isLoading = false
    @State private var error: Error?

    let startDate: Date?
    let timeInterval: Int
    var clubId: String { data.clubId }
    var canSuggest: Bool { !suggestions.contains(where: { $0.userId == data.currentUser?.id ?? ""}) }
    var suggestions: [Suggestion] { data.suggestions }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else if suggestions.isEmpty {
                VStack {
                    Text("No Suggestions Yet")
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
                    .font(.headline)
                Spacer()
                Text("Begins")
                    .font(.headline)
            }
            .padding([.horizontal, .top])

            List {
                ForEach(Array(suggestions.enumerated()), id: \.element.userId) { index, suggestion in
                    HStack {
                        Text(suggestion.userName)
                        Spacer()
                        Text(computedDateString(for: index) ?? "No Date")
                        if suggestion.userId == Auth.auth().currentUser?.uid {
                            Button(action: {
                                Task {
                                    await deleteSuggestion(for: suggestion)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.plain)

            newSuggestionButton
                .disabled(!canSuggest)
            Spacer()
        }
    }

    private var newSuggestionButton: some View {
        Button("Create Suggestion") {
            creatingSuggestion = true
        }
        .foregroundStyle(.black)
        .buttonStyle(.borderedProminent)
    }

    private func computedDateString(for index: Int) -> String? {
        guard let startDate = startDate else { return nil }
        let weeksToAdd = timeInterval * index
        return Calendar.current.date(byAdding: .weekOfYear, value: weeksToAdd, to: startDate)?
            .formatted(date: .abbreviated, time: .omitted)
    }

    private func deleteSuggestion(for suggestion: Suggestion) async {
        do {
            try await data.deleteSuggestion(suggestion: suggestion)
            if let index = data.suggestions.firstIndex(where: { $0.userId == suggestion.userId }) {
                data.suggestions.remove(at: index)
            }
        } catch {
            self.error = error
            print("Error deleting suggestion: \(error)")
        }
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
        } catch {
            self.error = error
            print("Error refreshing suggestions: \(error)")
        }
    }
}
