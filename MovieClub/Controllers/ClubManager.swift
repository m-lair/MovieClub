//
//  ClubManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

extension DataManager {
    
    // MARK: - Enums
    
    enum ClubError: Error {
        case clubAlreadyExists
        case unauthorized
        case invalidData
        case networkError(Error)
        case unknownError
        
    }
    
    // MARK: - Create Movie Club
    
    func createMovieClub(movieClub: MovieClub, movie: Movie?) async {
        // Placeholder for future implementation
        /*
        if let movie {
            await addFirstMovie(club: movieClub, movie: movie)
        }
        await addClubRelationship(club: movieClub)
        await addClubMember(clubId: id, user: self.currentUser!, date: timeIntervalFromToday)
        self.userMovieClubs.append(movieClub)
        */
    }
    
    // MARK: - Fetch User Clubs
    
    func fetchUserClubs() async {
        do {
            guard let user = self.currentUser else {
                print("No user logged in")
                return
            }
            let snapshot = try await usersCollection().document(user.id ?? "")
                .collection("memberships")
                .getDocuments()
            let clubIds = snapshot.documents.compactMap { $0.data()["clubId"] as? String }
            let clubs = try await withThrowingTaskGroup(of: MovieClub?.self) { group in
                for clubId in clubIds {
                    group.addTask { [weak self] in
                        guard let self = self else { return nil }
                        return await self.fetchMovieClub(clubId: clubId)
                    }
                }
                var clubList: [MovieClub] = []
                for try await club in group {
                    if let club = club {
                        clubList.append(club)
                    }
                }
                return clubList
            }
            self.userClubs = clubs
        } catch {
            print("Error fetching user clubs: \(error)")
        }
    }
    
    // MARK: - Fetch Movie Club
    
    func fetchMovieClub(clubId: String) async -> MovieClub? {
        guard let snapshot = try? await movieClubCollection().document(clubId).getDocument() else {
            print("Can't find movie club: \(clubId)")
            return nil
        }
        do {
            let movieClub = try snapshot.data(as: MovieClub.self)
            let moviesSnapshot = try await movieClubCollection()
                .document(clubId)
                .collection("movies")
                .order(by: "endDate", descending: false)
                .limit(to: 1)
                .getDocuments()
            for document in moviesSnapshot.documents {
                //print("Current movie in method \(document.data())")
                movieClub.movies = [try document.data(as: Movie.self)]
            }
            return movieClub
        } catch {
            print("Error decoding movie: \(error)")
            return nil
        }
    }
    
    // MARK: - Fetch Club Details
    
    func fetchClubDetails(club: MovieClub) async throws {
        currentClub = club
        movie = club.movies.first
    }
    
    // MARK: - Join Club
    
    func joinClub(club: MovieClub) async {
        if let user = self.currentUser, let clubId = club.id {
            await addClubMember(clubId: clubId, user: user, date: Date())
        }
    }
    
    // MARK: - Add Club Member
    
    func addClubMember(clubId: String, user: User, date: Date) async {
        do {
            if let id = user.id {
                let member = Member(userId: id, userName: user.name, userAvi: user.image ?? "", selector: false, dateAdded: date)
                let encodedMember = try Firestore.Encoder().encode(member)
                try await movieClubCollection().document(clubId).collection("members").document(id).setData(encodedMember)
            }
        } catch {
            print("Couldn't add member")
        }
    }
    
    // MARK: - Remove Club Relationship
    
    func removeClubRelationship(clubId: String, userId: String) async {
        do {
            try await usersCollection().document(userId).collection("memberships").document(clubId).delete()
        } catch {
            print("Could not delete club membership: \(error)")
        }
    }
    
    // MARK: - Upload Club Image
    
    func uploadClubImage(image: UIImage, clubId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.25) else {
            return ""
        }
        let storageRef = Storage.storage().reference().child("Clubs/\(clubId)/banner.jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        //print("Club image URL: \(url)")
        return url.absoluteString
    }
    
    // MARK: - Add to Coming Soon
    
    func addToComingSoon(clubId: String, userId: String, date: Date) async {
        do {
            try await movieClubCollection().document(clubId).collection("members").document(userId).updateData([
                "selector": true,
                "comingSoonDate": date
            ])
            // Additional logic can be added here
        } catch {
            print(error)
        }
    }
}
