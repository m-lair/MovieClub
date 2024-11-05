//
//  RosterView.swift
//  MovieClub
//
//  Created by Marcus Lair on 7/20/24.
//

import SwiftUI
import FirebaseFirestore

struct ComingSoonView: View {
    @Environment(DataManager.self) var data: DataManager
    
    @State private var screenWidth = UIScreen.main.bounds.size.width
    @State private var creatingSuggestion = false
    @State private var isLoading = false
    @State private var error: Error?
    
    let startDate: Date?
    let timeInterval: Int
    var clubId: String { data.clubId }
    var suggestions: [Suggestion] { data.suggestions }
    
    var body: some View {
        VStack {
            Group {
                if suggestions.isEmpty {
                    VStack {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("No Suggestions Yet")
                            newSuggestionButton
                        }
                    }
                } else {
                    suggestionsList
                }
            }
        }
        .refreshable {
            await refreshSuggestions()
        }
        .sheet(isPresented: $creatingSuggestion) {
            CreateSuggestionView()
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") {
                error = nil
            }
            Button("Retry") {
                Task {
                    await refreshSuggestions()
                }
            }
        } message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        }
        .task {
            setupSuggestionsListener()
        }
        .onDisappear {
            data.suggestionsListener?.remove()
            data.suggestionsListener = nil
        }
    }
    
    private var suggestionsList: some View {
        ScrollView {
            VStack {
                ForEach(Array(suggestions.enumerated()), id: \.1.id) { index, suggestion in
                    HStack {
                        ComingSoonRowView(suggestion: suggestion)
                        Spacer()
                        if let dateString = computedDateString(for: index) {
                            Text(dateString)
                        } else {
                            Text("No Date")
                        }
                    }
                }
                .padding([.top, .leading])
                newSuggestionButton
            }
            
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
        let weeksToAdd = timeInterval * (index + 1)
        return Calendar.current.date(byAdding: .weekOfYear, value: weeksToAdd, to: startDate)?
            .formatted(date: .abbreviated, time: .omitted)
    }
    
    private func setupSuggestionsListener()  {
        data.listenToSuggestions(clubId: clubId)
    }
    
    private func refreshSuggestions() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let clubId = data.currentClub?.id else { return }
            _ = try await data.fetchSuggestions(clubId: clubId)
            error = nil
        } catch {
            self.error = error
            print("Error refreshing suggestions: \(error)")
        }
    }
}
