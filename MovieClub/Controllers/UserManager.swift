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
        guard let uid = auth.currentUser?.uid else {
            print("User not logged in")
            return
        }
        
        guard let snapshot = try? await usersCollection().document(uid).getDocument() else {
            print("error getting user document")
            currentUser = nil
            userSession = nil
            return
        }
        
        do {
            currentUser = try snapshot.data(as: User.self)
            await fetchUserClubs()
        } catch {
            throw error
        }
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
    
    // MARK: - Update Related User Data
    
    private func updateRelatedUserData(changes: [String: Any]) async {
        await updateComments(changes: changes)
        await updateMovies(changes: changes)
        await updateMembers(changes: changes)
    }
    
    private func updateComments(changes: [String: Any]) async {
        let commentsQuery = db.collectionGroup("comments").whereField("userId", isEqualTo: currentUser?.id ?? "")
        do {
            let commentsSnapshot = try await commentsQuery.getDocuments()
            let batch = db.batch()
            for document in commentsSnapshot.documents {
                batch.updateData([
                    "username": changes["name"] ?? currentUser?.name ?? ""
                ], forDocument: document.reference)
            }
            try await batch.commit()
            //print("Successfully updated comments.")
        } catch {
            print("Error updating comments: \(error)")
        }
    }
    
    private func updateMovies(changes: [String: Any]) async {
        let moviesQuery = db.collectionGroup("movies").whereField("authorId", isEqualTo: currentUser?.id ?? "")
        do {
            let movieSnapshot = try await moviesQuery.getDocuments()
            let batch = db.batch()
            for document in movieSnapshot.documents {
                batch.updateData([
                    "author": changes["name"] ?? currentUser?.name ?? ""
                ], forDocument: document.reference)
            }
            try await batch.commit()
            //print("Successfully updated movies.")
        } catch {
            print("Error updating movies: \(error)")
        }
    }
    
    private func updateMembers(changes: [String: Any]) async {
        let membersQuery = db.collectionGroup("members").whereField("userId", isEqualTo: currentUser?.id ?? "")
        do {
            let membersSnapshot = try await membersQuery.getDocuments()
            let batch = db.batch()
            for document in membersSnapshot.documents {
                batch.updateData([
                    "userName": changes["name"] ?? currentUser?.name ?? ""
                ], forDocument: document.reference)
            }
            try await batch.commit()
            //print("Successfully updated members.")
        } catch {
            print("Error updating members: \(error)")
        }
    }
    
    // MARK: - Get Profile Image by Path
    
    func getProfileImage(path: String) async -> String {
        let storageRef = Storage.storage().reference().child(path)
        do {
            let url = try await storageRef.downloadURL()
            self.currentUser?.image = url.absoluteString
            //print("Profile image URL: \(url.absoluteString)")
            return url.absoluteString
        } catch {
            print(error)
            return ""
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
    
    // MARK: - Join Club
    
    func joinClub(club: MovieClub) async throws {
        guard
            let user = currentUser,
            let clubId = club.id,
            let userId = user.id
        else {
            throw AuthError.invalidUser
        }
        
        let joinClub: Callable<[String: String], MovieClub> = functions.httpsCallable("users-joinMovieClub")
        let requestData: [String: String] = ["userId": userId,
                                             "movieClubId": clubId,
                                             "username": user.name,
                                             "movieClubName": club.name,
                                             "image": "image"]
        do {
            let result = try await joinClub(requestData)
            userClubs.append(result)
        } catch {
            print("Error joining club: \(error)")
        }
        
    }
}
