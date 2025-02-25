//
//  Bulletin.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/29/24.
//

import SwiftUI
import FirebaseFirestore

struct ClubAboutView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var members: [Member] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var club: MovieClub? {
        dataManager.currentClub
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let club = club {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to \(club.name)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Current Watch Period: **\(club.timeInterval) weeks**")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
                
                Label("Members", systemImage: "person.3.fill")
                    .font(.title2)
                    .padding(.vertical, 8)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(members, id: \.id) { member in
                                HStack {
                                    Label(member.userName, systemImage: "person.fill")
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                Text("No club available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .task {
            await loadMembers()
        }
    }
    
    private func loadMembers() async {
        guard let clubId = dataManager.currentClub?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let moviesSnapshot = try await dataManager.movieClubCollection()
                .document(clubId)
                .collection("members")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            var loadedMembers: [Member] = []
            for document in moviesSnapshot.documents {
                do {
                    var member = try document.data(as: Member.self)
                    member.id = document.documentID
                    loadedMembers.append(member)
                } catch {
                    print("Error decoding member: \(error)")
                }
            }
            members = loadedMembers
        } catch {
            errorMessage = "Failed to load members: \(error.localizedDescription)"
            print("Error fetching members: \(error)")
        }
    }
}
