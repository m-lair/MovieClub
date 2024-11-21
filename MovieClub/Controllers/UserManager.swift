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
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }
        
        guard
            let snapshot = try? await usersCollection().document(uid).getDocument()
        else {
            print("error getting user document")
            return
        }
        do {
            currentUser = try snapshot.data(as: User.self)
        } catch {
            print("error parsing user document")
            throw error
        }
        await fetchUserClubs()
    }
    
    // MARK: - Fetch User Clubs
    
    func fetchUserClubs() async {
        do {
            guard let user = currentUser else {
                print("No user logged in")
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
                print("clubList: \(clubList.map(\.id))")
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
            let result = try await updateUser(user)
            try await fetchUser()
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
        var items: [CollectionItem] = []
        
        for document in snapshot.documents {
            var item = try document.data(as: CollectionItem.self)
            // Fetch posterUrl if needed
            if item.posterUrl.isEmpty {
                if let posterUrl = try? await fetchPosterUrl(imdbId: item.imdbId) {
                    item.posterUrl = posterUrl
                    // Optionally update Firestore with the new posterUrl
                    // try await updatePosterUrlInFirestore(for: item)
                }
            }
            items.append(item)
        }
        return items
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
    
    struct CollectionResponse: Codable {
        let success: Bool
        let message: String?
    }
}
