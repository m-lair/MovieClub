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
        case custom(message: String)
        
    }
    
    struct MovieClubResponse: Codable {
             let success: Bool
             let message: String?
         }
    
    // MARK: - Create Movie Club
    
    func createMovieClub(movieClub: MovieClub) async throws {
        let createClub: Callable<MovieClub, String> = functions.httpsCallable("movieClubs-createMovieClub")
        do {
            let clubId = try await createClub(movieClub)
            movieClub.id = clubId
            userClubs.append(movieClub)
        } catch {
            print("unable to create movie club: \(movieClub.name)")
            throw error
        }
    }
    
    // MARK: - Update Movie Club
    
    func updateMovieClub(movieClub: MovieClub) async throws {
        let updateClub: Callable<MovieClub, MovieClubResponse> = functions.httpsCallable("movieClubs-updateMovieClub")
        do {
            let result = try await updateClub(movieClub)
            if result.success {
                //Do nothing
            } else {
                throw ClubError.custom(message: result.message ?? "Unknown error")
            }
        } catch {
            throw ClubError.networkError(error)
        }
    }
    
    // MARK: - Fetch Movie Club
    
    func fetchMovieClub(clubId: String) async -> MovieClub? {
        guard let snapshot = try? await movieClubCollection().document(clubId).getDocument() else {
            print("Can't find movie club: \(clubId)")
            return nil
        }
        
        do {
            var movieClub = try snapshot.data(as: MovieClub.self)
            movieClub.id = snapshot.documentID

            // 1) Get total number of movies for this club
            let allMoviesSnapshot = try await movieClubCollection()
                .document(clubId)
                .collection("movies")
                .getDocuments()
            movieClub.numMovies = allMoviesSnapshot.documents.count

            // 2) Get total number of members for this club
            let membersSnapshot = try await movieClubCollection()
                .document(clubId)
                .collection("members")
                .getDocuments()
            movieClub.numMembers = membersSnapshot.documents.count

            // 3) Fetch the most recent "active" movie
            let moviesSnapshot = try await movieClubCollection()
                .document(clubId)
                .collection("movies")
                .whereField("status", isEqualTo: "active")
                .order(by: "createdAt", descending: true)
                .limit(to: 1)
                .getDocuments()

            var needsRotation = false
            var baseMovie: Movie? = nil

            if let document = moviesSnapshot.documents.first {
                baseMovie = try document.data(as: Movie.self)
                baseMovie?.id = document.documentID
                
                // Check if the watch period has ended (using dates standardized to midnight)
                if let endDate = baseMovie?.endDate,
                   endDate.midnight < Date().midnight {
                    needsRotation = true
                }
            } else if self.suggestions.count > 0 {
                // No active movie, check if there are suggestions to rotate
                needsRotation = true
            }

            // 4) If rotation is needed, rotate the movie
            if needsRotation {
                let rotationResult = try await rotateMovie(clubId: clubId)
                if rotationResult {
                    // After rotation, fetch the new active movie
                    let newMoviesSnapshot = try await movieClubCollection()
                        .document(clubId)
                        .collection("movies")
                        .whereField("status", isEqualTo: "active")
                        .order(by: "createdAt", descending: true)
                        .limit(to: 1)
                        .getDocuments()
                    
                    if let newDocument = newMoviesSnapshot.documents.first {
                        baseMovie = try newDocument.data(as: Movie.self)
                        baseMovie?.id = newDocument.documentID
                    }
                }
            }

            // 5) If we have a base movie, fetch the API data
            if let baseMovie = baseMovie {
                // Fetch TMDB data for the movie
                if let apiMovie = try await tmdb.fetchMovieDetails(baseMovie.imdbId) {
                    baseMovie.apiData = apiMovie
                }
                
                // Assign to your club model
                movieClub.movieEndDate = baseMovie.endDate
                movieClub.movies = [baseMovie]
                movieClub.suggestions = try await fetchSuggestions(clubId: snapshot.documentID)
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
    
    func fetchAllPublicClubs() async throws -> [String] {
        let snapshot = try await movieClubCollection()
            .whereField("isPublic", isEqualTo: "true")
            .getDocuments()

        let clubs: [String] = snapshot.documents.compactMap { doc in
            // For this to work, MovieClub should conform to Decodable
            // and match your Firestore fields
            return doc.documentID
        }
        return clubs
    }

}

extension Date {
    /// Returns the date set to midnight (00:00) for the current day.
    var midnight: Date {
        return Calendar.current.startOfDay(for: self)
    }
}
