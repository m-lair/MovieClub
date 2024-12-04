//
//  ClubManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseFunctions

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
    
    func createMovieClub(movieClub: MovieClub) async throws {
        let createClub: Callable<MovieClub, String> = functions.httpsCallable("movieClubs-createMovieClub")
        do {
            _ = try await createClub(movieClub)
        } catch {
            print("unable to create movie club: \(movieClub.name)")
            throw error
        }
    }
    
    // MARK: - Update Movie Club
    
    func updateMovieClub(movieClub: MovieClub) async throws {
        do {
            print("updating movie club: \(movieClub.name)")
            let result = try await  functions.httpsCallable("movieClubs-updateMovieClub").call(movieClub)
            print("updated club: \(result)")
        } catch {
            throw error
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
            movieClub.id = snapshot.documentID
            
            let moviesSnapshot = try await movieClubCollection()
                .document(clubId)
                .collection("movies")
                .whereField("status", isEqualTo: "active")
                .limit(to: 1)
                .getDocuments()
            
            var needsRotation = false
            var baseMovie: Movie? = nil
            
            if let document = moviesSnapshot.documents.first {
                baseMovie = try document.data(as: Movie.self)
                baseMovie?.id = document.documentID
                // Check if the watch period has ended
                if let endDate = baseMovie?.endDate, endDate < Date() {
                    needsRotation = true
                }
            } else {
                // No active movie, check if there are suggestions to rotate
                needsRotation = true
            }
            
            // If rotation is needed, call the rotateMovie Cloud Function
            if needsRotation {
                let rotationResult = try await rotateMovie(clubId: clubId)
                if !rotationResult {
                   // Do nothing
                } else {
                    // After rotation, fetch the new active movie
                    let newMoviesSnapshot = try await movieClubCollection()
                        .document(clubId)
                        .collection("movies")
                        .whereField("status", isEqualTo: "active")
                        .limit(to: 1)
                        .getDocuments()
                    if let newDocument = newMoviesSnapshot.documents.first {
                        baseMovie = try newDocument.data(as: Movie.self)
                        baseMovie?.id = newDocument.documentID
                    }
                }
            }
            
            // If we have a base movie, fetch API data
            if var baseMovie = baseMovie {
                // Fetch API data for the movie
                if let apiMovie = try await fetchMovieDetails(for: baseMovie) {
                    baseMovie.apiData = MovieAPIData(from: apiMovie)
                }
                movieClub.movieEndDate = baseMovie.endDate
                movieClub.movies = [baseMovie]
                movieClub.bannerUrl = baseMovie.poster
            }
            
            return movieClub
        } catch {
            print("Error fetching movie club: \(error)")
            return nil
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
}
