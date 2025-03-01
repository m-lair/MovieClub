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
                                    NavigationLink(destination: ProfileDisplayView(userId: member.id)) {
                                        
                                        if let imageUrl = member.image, let url = URL(string: imageUrl) {
                                            CachedAsyncImage(url: url) {
                                                Circle()
                                                    .fill(Color.gray.opacity(0.3))
                                            }
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 30, height: 30)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                        
                                        } else {
                                            Image(systemName: "person.fill")
                                                .resizable()
                                                .frame(width: 20, height: 20)
                                                .padding(.horizontal, 3)
                                        }
                                    }
                                    
                                    Text(member.userName)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                       
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
                Text("No details available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            Spacer()
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
            let clubsSnapshot = try await dataManager.movieClubCollection()
                .document(clubId)
                .collection("members")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            var loadedMembers: [Member] = []
            for document in clubsSnapshot.documents {
                do {
                    var member = try document.data(as: Member.self)
                    member.id = document.documentID
                    
                    // Fetch profile image for the member
                    if let userId = member.id {
                        member.image = try await dataManager.getProfileImage(userId: userId)
                    }
                    
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
