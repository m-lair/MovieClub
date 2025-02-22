//
//  PosterManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 1/22/25.
//

import Foundation
import FirebaseFunctions

extension DataManager {
    
    func fetchCollectionItems(for userId: String) async throws -> [CollectionItem] {
        print("begin fetching collection items")
        let snapshot = try await usersCollection().document(userId).collection("posters").getDocuments()
        let collectionItems = try snapshot.documents.map { document -> CollectionItem in
            print("decoding document data")
            return try document.data(as: CollectionItem.self)
        }
        print("getting additional movie data")
        let items = try await withThrowingTaskGroup(of: CollectionItem?.self) { group in
            for item in collectionItems {
                group.addTask { [self] in
                    // Create tasks for both Firebase and poster URL fetching
                    async let movieDataTask: (likes: Int, dislikes: Int)? = {
                        do {
                            let movieDoc = try await db
                                .collection("movieclubs")
                                .document(item.clubId)
                                .collection("movies")
                                .document(item.movieId ?? "")
                                .getDocument()
                            
                            guard let movieData = movieDoc.data(),
                                  let likes = movieData["likes"] as? Int,
                                  let dislikes = movieData["dislikes"] as? Int
                            else { return nil }
                            
                            return (likes: likes, dislikes: dislikes)
                        } catch {
                            print("Error fetching movie data: \(error)")
                            return nil
                        }
                    }()
                    
                    async let posterUrlTask: String? = {
                        do {
                            return try await tmdb.fetchPosterUrl(imdbId: item.imdbId)
                        } catch {
                            print("Error fetching poster URL: \(error)")
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
                        print("color \(color)")
                    }
                    
                    // Now that we have valid movie data, we can await the poster URL
                    let posterUrl = await posterUrlTask ?? item.posterUrl // Fallback to existing URL if fetch fails
                    
                    // Create new item with updated color and poster URL
                    var updatedItem = item
                    updatedItem.colorStr = color
                    updatedItem.posterUrl = posterUrl
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
        switch ratio {
        case ..<0.5:
            return "red"
        case 0.5..<1.0:
            return "yellow"
        case 1.0..<2.0:
            return "blue"
        default:
            return "green"
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
