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
    
    @State private var movieTitle: String = ""
    @State private var suggestions: [Suggestion] = []
    @State private var isShowingSuggestions = false
    @FocusState private var isTextFieldFocused: Bool
    
    
    @State var errorMessage: String = ""
    @State var errorShowing: Bool = false
    
    var body: some View {
        VStack {
            Text("Create Suggestion")
                .font(.title)
                .padding()
                .navigationBarTitle("Create Suggestion")
            
            TextField("Enter movie title", text: $movieTitle)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isTextFieldFocused)
            
            Spacer()
            
            Button("Submit"){
                Task {
                    try await submitSuggestion()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(errorMessage, isPresented: $errorShowing) {
            Button("OK", role: .cancel) { }
        }
        
    
        /*.onAppear {
            Task {
                guard let clubId = data.currentClub?.id else { return }
                try data.listenToSuggestions(clubId: clubId)
            }
        }*/
    }

    func submitSuggestion() async throws {
        guard
            let clubId = data.currentClub?.id,
            let username = data.currentUser?.name
        else {
            print("username \(data.currentUser?.name), clubId \(data.currentClub?.id)")
            errorMessage = "invalid user data"
            errorShowing = true
            return
        }
        let newSuggestion = Suggestion(title: movieTitle, userImage: "image", username: username, clubId: clubId)
        
        let _ = try await data.createSuggestion(suggestion: newSuggestion)
        dismiss()
    }
}
