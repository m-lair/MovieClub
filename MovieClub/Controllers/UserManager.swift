//
//  UserManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 9/24/24.
//

import Foundation
import FirebaseAuth
import FirebaseStorage

extension DataManager {
    
    // MARK: - Fetch User
    
    func fetchUser() async throws {
        //print("Fetching user \(Auth.auth().currentUser?.uid ?? "")")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let snapshot = try? await usersCollection().document(uid).getDocument() else { return }
        do {
            self.currentUser = try snapshot.data(as: User.self)
            //print("Current userId: \(self.currentUser?.id ?? "")")
            await fetchUserClubs()
        } catch {
            print("Error decoding user")
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
    
    func updateUserDetails(changes: [String: Any]) async throws {
        do {
            //print("Updating user details")
            try await usersCollection().document(currentUser?.id ?? "").updateData(changes)
            
            // Update related data in comments, movies, and members
            await updateRelatedUserData(changes: changes)
            
            //print("Fetching updated user")
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
    
    func getProfileImage(userId: String) async -> String {
        do {
            let document = try await usersCollection().document(userId).getDocument()
            guard let url = document.get("image") as? String else {
                print("No image field in user document")
                return ""
            }
            return url
        } catch {
            print("Error fetching profile image URL: \(error)")
            return ""
        }
    }
}
