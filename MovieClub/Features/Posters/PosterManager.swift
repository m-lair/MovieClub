//
//  PosterManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 1/22/25.
//

import Foundation
import FirebaseFunctions
import FirebaseFirestore

extension DataManager {
    
    func fetchCollectionItems(for userId: String) async throws -> [CollectionItem] {
        let snapshot = try await usersCollection().document(userId).collection("posters").getDocuments()
        
        let collectionItems = try snapshot.documents.map { document -> CollectionItem in
            return try document.data(as: CollectionItem.self)
        }
        
        let items = try await withThrowingTaskGroup(of: CollectionItem?.self) { group in
            for item in collectionItems {
                group.addTask { [self] in
                    // Create tasks for both Firebase and poster URL fetching
                    async let movieDataTask: (likes: Int, dislikes: Int, revealDate: Date)? = {
                        do {
                            let movieDoc = try await db
                                .collection("movieclubs")
                                .document(item.clubId)
                                .collection("movies")
                                .document(item.movieId ?? "")
                                .getDocument()
                            
                            guard let movieData = movieDoc.data() else { return nil }
                            
                            guard let likes = movieData["likes"] as? Int,
                                  let dislikes = movieData["dislikes"] as? Int else {
                                return nil
                            }
                            
                            // Try to get endDate, handling both Date and Timestamp types
                            let revealDate: Date
                            if let endDate = movieData["endDate"] as? Date {
                                revealDate = endDate
                            } else if let endDateTimestamp = movieData["endDate"] as? Timestamp {
                                revealDate = endDateTimestamp.dateValue()
                            } else if let endDateValue = movieData["endDate"],
                                      String(describing: type(of: endDateValue)).contains("FIRTimestamp") {
                                // Fallback for FIRTimestamp
                                if let seconds = (endDateValue as AnyObject).value(forKey: "seconds") as? Int64,
                                   let nanoseconds = (endDateValue as AnyObject).value(forKey: "nanoseconds") as? Int32 {
                                    let timeInterval = TimeInterval(seconds) + TimeInterval(nanoseconds) / 1_000_000_000
                                    revealDate = Date(timeIntervalSince1970: timeInterval)
                                } else {
                                    revealDate = Date() // Fallback
                                }
                            } else {
                                revealDate = Date()
                            }
                            
                            return (likes: likes, dislikes: dislikes, revealDate: revealDate)
                        } catch {
                            return nil
                        }
                    }()
                    
                    async let posterUrlTask: String? = {
                        do {
                            return try await tmdb.fetchPosterUrl(imdbId: item.imdbId)
                        } catch {
                            return nil
                        }
                    }()
                    
                    // Wait for movie data first
                    guard let movieData = await movieDataTask else {
                        return nil
                    }
                    
                    // Calculate color based on movie data
                    let color: String
                    if movieData.dislikes == 0 && movieData.likes == 0 {
                        color = "black"
                    } else {
                        let ratio = Double(movieData.likes) / Double(movieData.dislikes)
                        color = determineColor(fromRatio: ratio)
                    }
                    
                    // Now that we have valid movie data, we can await the poster URL
                    let posterUrl = await posterUrlTask ?? item.posterUrl // Fallback to existing URL if fetch fails
                    
                    // Create new item with updated color, poster URL, and reveal date
                    var updatedItem = item
                    updatedItem.colorStr = color
                    updatedItem.posterUrl = posterUrl
                    
                    // Set the revealDate if it's not already set
                    if updatedItem.revealDate == nil {
                        updatedItem.revealDate = movieData.revealDate
                    }
                    
                    return updatedItem
                }
            }
            
            // Collect results
            var updatedItems: [CollectionItem] = []
            for try await item in group {
                if let item {
                    updatedItems.append(item)
                }
            }
            return updatedItems
        }
        return items
    }

    private func determineColor(fromRatio ratio: Double) -> String {
        // More nuanced color system based on like/dislike ratio
        switch ratio {
        case 0:
            return "neutral" // No likes or dislikes yet
        case ..<0.5:
            return "negative" // Significantly more dislikes than likes
        case 0.5..<0.8:
            return "mixed" // More dislikes than likes, but closer
        case 0.8..<1.2:
            return "balanced" // Roughly equal likes and dislikes
        case 1.2..<2.0:
            return "positive" // More likes than dislikes
        case 2.0..<4.0:
            return "verygood" // Significantly more likes than dislikes
        default:
            return "excellent" // Overwhelmingly more likes than dislikes
        }
    }

    func collectPoster(collectionItem: CollectionItem) async throws {
        let collectPoster: Callable<CollectionItem, String?> = functions.httpsCallable("posters-collectPoster")
        
        do {
            let result = try await collectPoster(collectionItem)
            if result != nil {
                print("poster collected successfully: \(result)")
            }
        } catch {
            throw error
        }
    }
}
