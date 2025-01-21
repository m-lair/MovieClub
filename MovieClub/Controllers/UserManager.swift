//
//  UserManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

import Foundation
import FirebaseAuth
import FirebaseFunctions
import FirebaseStorage
import Promises

extension DataManager {
    
    // MARK: - Enums
    
    enum UserServiceError: Error {
        case userNotFound
        case unauthorized
        case invalidData
        case networkError(Error)
        case unknownError
    }
    
    // MARK: - Fetch User
    
    func fetchUser() async throws {
        guard let user = Auth.auth().currentUser else {
            print("User not logged in")
            return
        }
        
        print("user logged in: \(user)")
        guard
            let snapshot = try? await usersCollection().document(user.uid).getDocument()
        else {
            print("error getting user document")
            return
        }
        do {
            currentUser = try snapshot.data(as: User.self)
        } catch {
            print("error parsing user document")
            signOut()
            throw error
        }
        await fetchUserClubs()
    }
    
    // MARK: - Fetch User Clubs
    
    func fetchUserClubs() async {
        do {
            guard let user = currentUser else {
                print("no user")
                authCurrentUser = nil
                return
            }
            let snapshot = try await usersCollection().document(user.id ?? "")
                .collection("memberships")
                .getDocuments()
            
            let clubIds = snapshot.documents.compactMap { $0.documentID }
            let clubs = try await withThrowingTaskGroup(of: MovieClub?.self) { group in
                for clubId in clubIds {
                    group.addTask { [weak self] in
                        guard let self = self else { return nil }
                        return await self.fetchMovieClub(clubId: clubId)
                    }
                }
                
                var clubList: [MovieClub] = []
                for try await club in group {
                    if let club {
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
    
    // MARK: - Update Profile Picture
    
    func updateProfilePicture(imageData: Data) async throws {
        let path = "Users/profile_images/\(self.currentUser?.id ?? "")"
        let storageRef = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        do {
            try await storageRef.putDataAsync(imageData, metadata: metadata)
            let url = try await storageRef.downloadURL()
            try await usersCollection().document(currentUser?.id ?? "").updateData(["image": url.absoluteString])
        } catch {
            throw error
        }
    }
    
    // MARK: - Update User Details
    
    func updateUserDetails(user: User) async throws {
        do {
            print("username: \(user.name)")
            let updateUser: Callable<User, Bool?> = functions.httpsCallable("users-updateUser")
            _ = try await updateUser(user)
        } catch {
            throw error
        }
    }
    
    // MARK: - Get Profile Image by User ID
    
    func getProfileImage(userId: String) async throws -> String? {
        do {
            let document = try await usersCollection().document(userId).getDocument()
            guard let url = document.get("image") as? String else {
                print("No image field in user document")
                return nil
            }
            return url
        } catch {
            print("Error fetching profile image URL: \(error)")
            throw error
        }
    }
    
    func deleteUserAccount(userId: String) async throws {
        let parameters: [String: Any] = [
            "userId": userId
        ]
        
        do {
            _ = try await functions.httpsCallable("users-deleteUser").call(parameters)
        } catch {
            throw error
        }
    }
    
    func fetchCurrentCollection() async {
        do {
            let items = try await fetchCollectionItems()
            self.currentCollection = items
        } catch {
            print("Error fetching collection items: \(error)")
        }
    }
    
    func fetchCollectionItems() async throws -> [CollectionItem] {
        guard let user = currentUser,
              let userId = user.id
        else { return [] }
        
        let snapshot = try await usersCollection().document(userId).collection("posters").getDocuments()
        let collectionItems = try snapshot.documents.map { document -> CollectionItem in
            try document.data(as: CollectionItem.self)
        }
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
                            return try await fetchPosterUrl(imdbId: item.imdbId)
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
                    print("movie likes \(movieData.likes)")
                    print("movie dislikes \(movieData.dislikes)")
                    
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
                    let updatedItem = item
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
    
    func fetchPosterUrl(imdbId: String) async throws -> String {
        let urlString = "https://www.omdbapi.com/?i=\(imdbId)&apikey=\(omdbKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct APIResponse: Decodable {
            let Poster: String?
        }
        
        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        return apiResponse.Poster ?? ""
    }
    
    func collectPoster(collectionItem: CollectionItem) async throws {
        let collectPoster: Callable<CollectionItem, CollectionResponse> = functions.httpsCallable("posters-collectPoster")
        
        do {
            let result = try await collectPoster(collectionItem)
            if result.success {
                print("poster collected successfully")
            } else {
                print("poster collect failed: \(result.message ?? "Unknown error")")
                throw SuggestionError.custom(message: result.message ?? "Unknown error")
            }
        } catch {
            throw error
        }
    }
    
    func handleMovieReaction(isLike: Bool) async throws {
        if movieId.isEmpty || clubId.isEmpty { return }
        
        let parameters: [String: Any] = [
            "movieId": movieId,
            "clubId": clubId,
            "isLike": isLike
        ]
        
        do {
            print("calling \(isLike ? "like" : "dislike") movie")
            _ = try await functions.httpsCallable("movies-handleMovieReaction").call(parameters)
        } catch {
            print("Failed to \(isLike ? "like" : "dislike") movie: \(error)")
            throw error
        }
    }
}
