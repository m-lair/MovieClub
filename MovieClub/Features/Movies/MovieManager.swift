//
//  MovieManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

import Foundation
import FirebaseFunctions


extension DataManager {
    enum MovieError: Error {
        case noMovieFound
        case cantRotate
        case custom(message: String)
    }
    
    struct MovieFunctionsResponse: Codable {
        let success: Bool
        let message: String?
    }
    
    // MARK: - Fetch Movies for Club
    func fetchFirestoreMovies(clubId: String) async throws {
        // Fetch movies from Firestore
        let moviesSnapshot = try await movieClubCollection()
            .document(clubId)
            .collection("movies")
            .order(by: "endDate", descending: false)
            .getDocuments()
        
        for document in moviesSnapshot.documents {
            let baseMovie = try document.data(as: Movie.self)
            baseMovie.id = document.documentID
            
            // Fetch and attach API data to the movie
            if let apiMovieData = try await fetchMovieAPIData(for: baseMovie.imdbId) {
                baseMovie.apiData = apiMovieData
            }
            
            currentClub?.movies.append(baseMovie)
        }
    }
    
    // MARK: - Fetch Movie Details
    func fetchMovieAPIData(for imdbId: String) async throws -> MovieAPIData? {
        guard !imdbId.isEmpty else { throw MovieError.noMovieFound }
        
        // Use the APIController to fetch movie details
        do {
            let apiResponse = try await tmdb.fetchMovieDetails(imdbId)
            return apiResponse
        } catch {
            throw MovieError.custom(message: "Failed to fetch movie details: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Query for Movies
    func fetchTMDBMovies(query: String) async throws -> [MovieAPIData] {
        guard !query.isEmpty else { return [] }
        
        do {
            let tmdbResults = try await tmdb.fetchMovies(query: query)
            return tmdbResults
        } catch {
            throw MovieError.custom(message: "Failed to fetch movies: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Rotate Movie (Firebase Function)
    func rotateMovie(clubId: String) async throws -> Bool {
        // Additional safety check - verify if the current active movie is actually due for rotation
        do {
            let moviesSnapshot = try await movieClubCollection()
                .document(clubId)
                .collection("movies")
                .whereField("status", isEqualTo: "active")
                .limit(to: 1)
                .getDocuments()
            
            if let document = moviesSnapshot.documents.first,
               let movie = try? document.data(as: Movie.self) {
                
                let now = Date()
                
                // Create a calendar instance for working with dates
                let calendar = Calendar.current
                
                // Check if we're on the day after the end date - this is when we want to rotate
                // Get end date components
                let endDateDay = calendar.component(.day, from: movie.endDate)
                let endDateMonth = calendar.component(.month, from: movie.endDate)
                let endDateYear = calendar.component(.year, from: movie.endDate)
                
                // Get today's components
                let todayDay = calendar.component(.day, from: now)
                let todayMonth = calendar.component(.month, from: now)
                let todayYear = calendar.component(.year, from: now)
                
                // If today is exactly the end date, don't rotate yet (wait until tomorrow)
                if endDateDay == todayDay && endDateMonth == todayMonth && endDateYear == todayYear {
                    return false
                }
                
                // Only rotate if today is after the end date
                if let dayAfterEndDate = calendar.date(byAdding: .day, value: 1, to: movie.endDate.midnight),
                   now.midnight >= dayAfterEndDate.midnight {
                    // We're past the end date, proceed with rotation
                } else {
                    return false
                }
            }
            
            // If we get here, proceed with the rotation
            let rotateMovie: Callable<[String: String], MovieFunctionsResponse> = functions.httpsCallable("movies-rotateMovie")
            let result = try await rotateMovie.call(["clubId": clubId])
            return result.success
        } catch {
            throw MovieError.custom(message: error.localizedDescription)
        }
    }
    
    
    // MARK: - Fetch Trending Clubs
    func fetchTrendingClubs() async throws -> [MovieClub] {
        // 1. Fetch all clubs from Firestore.
        let snapshot = try await db.collection("movieclubs").getDocuments()
        
        // 2. For each club, concurrently get the count of documents in the "members" subcollection.
        var clubsWithCount: [(MovieClub, Int)] = []
        try await withThrowingTaskGroup(of: (MovieClub, Int).self) { group in
            for document in snapshot.documents {
                group.addTask { [weak self] in
                    guard let self = self else {
                        throw MovieError.custom(message: "Self is nil")
                    }
                    // Decode the club and set its id.
                    var club = try document.data(as: MovieClub.self)
                    club.id = document.documentID
                    
                    // Get the count of members from the "members" subcollection.
                    let membersCollection = self.db
                        .collection("movieclubs")
                        .document(document.documentID)
                        .collection("members")
                    let countSnapshot = try await membersCollection.count.getAggregation(source: .server)
                    let memberCount = Int(truncating: countSnapshot.count)
                    
                    return (club, memberCount)
                }
            }
            // Collect all club/memberCount pairs.
            for try await result in group {
                clubsWithCount.append(result)
            }
        }
        
        // 3. Sort clubs by member count (descending) and pick the top 10.
        let trendingClubs = clubsWithCount
            .sorted { $0.1 > $1.1 }
            .prefix(10)
            .map { $0.0 }
        
        // 4. Using a task group, fetch the complete API data for each trending club concurrently.
        let clubIds = trendingClubs.map { $0.id }
        let clubs = try await withThrowingTaskGroup(of: MovieClub?.self) { group in
            for clubId in clubIds {
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    return await self.fetchMovieClub(clubId: clubId ?? "")
                }
            }
            
            var clubList: [MovieClub] = []
            for try await club in group {
                if let club = club {
                    clubList.append(club)
                }
            }
            print("clubList: \(clubList)")
            return clubList
        }
        
        return clubs
    }


    
    // MARK: - Fetch Trending Movies
    func fetchTrendingMovies() async throws -> [MovieAPIData] {
        // Example: If you have a "fetchTrendingMovies()" in your TMDB wrapper
        do {
            let trending = try await tmdb.fetchTrendingMovies()
            // 'trending' is presumably an array of MovieAPIData or something similar
            return trending
        } catch {
            throw MovieError.custom(message: "Failed to fetch trending movies: \(error.localizedDescription)")
        }
    }
    
    func fetchNewsItems() async throws -> [NewsItem] {
        // Firestore or API call to get "news"
        // Return an array of NewsItem objects
        return []
    }
}
