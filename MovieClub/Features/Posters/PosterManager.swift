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
                    async let movieDataTask: (likes: Int, dislikes: Int, revealDate: Date, collections: Int, totalMembers: Int)? = {
                        do {
                            let movieDoc = try await db
                                .collection("movieclubs")
                                .document(item.clubId)
                                .collection("movies")
                                .document(item.movieId ?? "")
                                .getDocument()
                            
                            guard let movieData = movieDoc.data() else { return nil }
                            
                            guard let likes = movieData["likes"] as? Int,
                                  let dislikes = movieData["dislikes"] as? Int,
                                  let collections = movieData["numCollected"] as? Int
                                else {
                                return nil
                            }
                            
                            // Fetch total members for the club to calculate engagement rates
                            let clubDoc = try await db
                                .collection("movieclubs")
                                .document(item.clubId)
                                .getDocument()
                            
                            let totalMembers = (clubDoc.data()?["memberCount"] as? Int) ?? 10 // Default to 10 if not found
                            
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
                            
                            return (likes: likes, dislikes: dislikes, revealDate: revealDate, collections: collections, totalMembers: totalMembers)
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
                    
                    // Calculate color based on composite score of movie data
                    let color = determineColorComposite(
                        likes: movieData.likes,
                        dislikes: movieData.dislikes,
                        collections: movieData.collections,
                        totalMembers: movieData.totalMembers
                    )
                    
                    // Now that we have valid movie data, we can await the poster URL
                    let posterUrl = await posterUrlTask ?? item.posterUrl // Fallback to existing URL if fetch fails
                    
                    // Create new item with updated color, poster URL, and reveal date
                    var updatedItem = item
                    updatedItem.colorStr = color
                    updatedItem.posterUrl = posterUrl
                    updatedItem.collections = movieData.collections
                    updatedItem.likes = movieData.likes
                    updatedItem.dislikes = movieData.dislikes
                    
                    
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

    // New method that uses the composite scoring system for color determination
    private func determineColorComposite(likes: Int, dislikes: Int, collections: Int, totalMembers: Int) -> String {
        // If there are no reactions at all, return neutral
        if likes == 0 && dislikes == 0 {
            return "neutral"
        }
        
        // 1. Calculate Approval Ratio (0-1 scale)
        let totalReactions = likes + dislikes
        let approvalRatio = totalReactions > 0 ? Double(likes) / Double(totalReactions) : 0.5
        
        // 2. Calculate Collection Rate (what % of members collected)
        let collectionRate = Double(collections) / Double(max(1, totalMembers))
        
        // 3. Calculate Engagement Rate (what % of members reacted)
        let engagementRate = Double(totalReactions) / Double(max(1, totalMembers))
        
        // 4. Calculate Composite Score with weights
        // 60% approval ratio, 30% collection rate, 10% engagement
        let compositeScore = (approvalRatio * 0.6) + (collectionRate * 0.3) + (engagementRate * 0.1)
        
        // 5. Determine color based on composite score
        switch compositeScore {
        case 0.00..<0.21:
            return "negative"    // Deep red - Poorly received
        case 0.21..<0.36:
            return "mixed"       // Orange - Mixed reception but controversial 
        case 0.36..<0.51:
            return "balanced"    // Yellow - Truly mixed reception
        case 0.51..<0.66:
            return "positive"    // Light green - Moderately positive
        case 0.66..<0.81:
            return "verygood"    // Green - Clearly positive reception
        case 0.81..<0.91:
            return "excellent"   // Blue - Very well received
        default:
            return "excellent"   // Purple - Exceptional reception
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
