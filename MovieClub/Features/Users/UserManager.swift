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
