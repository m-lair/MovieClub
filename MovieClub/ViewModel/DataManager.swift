//
//  DataManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 5/12/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestoreSwift
import AuthenticationServices
import FirebaseFirestore
import UIKit
import FirebaseStorage
import Observation
import SwiftUI
import FirebaseMessaging
import FirebaseFunctions


@MainActor
@Observable 
class DataManager: Identifiable {
    
    var movies: [Movie] = []
    var poster: String {
        movies.first?.poster ?? ""
    }
    var userSession: FirebaseAuth.User?
    var currentUser: User?
    var userMovieClubs: [MovieClub] = []
    var comments: [Comment] = []
    var currentClub: MovieClub?
    var clubId: String {
        currentClub?.id ?? ""
    }
    var queue: Membership?
    var db: Firestore!
    
    init(){
        Task {
            print("launching datamanager")
            self.userSession = Auth.auth().currentUser
            db = Firestore.firestore()
            try await fetchUser()
        }
    }
    
    func addToComingSoon(clubId: String, userId: String, date: Date) async {
        //add member object
        do {
            try await movieClubCollection().document(clubId).collection("members").document(userId).updateData(["seletor" : true, "comingSoonDate" : date])
            
            //add date from greatest current roster date, could be movieclub.movies to get this easier
            //allow user to select queue of movies now
            //display roster by sorting on date
        } catch {
            print(error)
        }
    }
    
    func movieClubCollection() -> CollectionReference {
        return db.collection("movieclubs")
    }
    
    func usersCollection() -> CollectionReference {
        return db.collection("users")
    }
    
    func createUser(email: String, password: String, displayName: String) async throws -> String {
        do {
            let functions = Functions.functions()
            let result = try await functions.httpsCallable("createUser").call([
                "email": email,
                "password": password,
                "displayName": displayName
            ])
            guard let data = result.data as? [String: Any],
                  let uid = data["uid"] as? String else {
                throw NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
            }
            return uid
        } catch {
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("in sign in")
        do{
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            print("signed in user \(result.user)")
            try await fetchUser()
            
        } catch {
            throw error
        }
    }
    
    enum UploadError: Error {
        case invalidImageData
    }

    func uploadClubImage(image: UIImage, clubId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.25) else {
            throw UploadError.invalidImageData
        }

        let storageRef = Storage.storage().reference().child("Clubs/\(clubId)/banner.jpg")
        var metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        print("URL: \(url)")
        return url.absoluteString
    }
    
    func joinClub(club: MovieClub) async {
        if let user = self.currentUser, let clubId = club.id {
            await addClubMember(clubId: clubId, user: user, date: Date())
        }
    }
    
    func addClubMember(clubId: String, user: User, date: Date) async {
        do{
            if let id = user.id {
                let member = Member(userId: id, userName: user.name, userAvi: user.image ?? "" , selector: false, dateAdded: date)
                let encodedMember = try Firestore.Encoder().encode(member)
                try await movieClubCollection().document(clubId).collection("members").document(id).setData(encodedMember)
            }
        } catch {
            print("couldnt add member")
        }
    }
    
    func removeClubRelationship(clubId: String, userId: String) async {
        // cant figure out a better way to do this but we know the val wont be null
        do{
            try await usersCollection().document(userId).collection("memberships").document(clubId).delete()
        } catch {
            print("could not delete club membership: \(error)")
        }
    }
    
    func getProfileImage(path: String) async -> String {
        //   print("in getter")
        let storageRef = Storage.storage().reference().child(path) //Storage.storage().reference().child("Users/profile_images/\(id)")
        do {
            let url = try await storageRef.downloadURL()
            self.currentUser?.image = url.absoluteString
            print("url.absoluteString \(url.absoluteString)")
            //return url to image in the cloud as a String
            return url.absoluteString
        } catch {
            print(error)
        }
        return ""
    }
    
    func getProfileImage(userId: String) async -> String {
        do {
            // Fetch the document
            let document = try await usersCollection().document(userId).getDocument()
            // Retrieve the `profileImageURL` field
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
    
    func fetchComments(movieClubId: String, movieId: String) async -> [Comment]{
        do {
            let querySnapshot = try await movieClubCollection().document(movieClubId).collection("movies").document(movieId).collection("comments")
                .order(by: "date", descending: true)
                .getDocuments()
            let comments = querySnapshot.documents.compactMap { document in
                do {
                    return try document.data(as: Comment.self)
                } catch {
                    print("Error decoding document \(document.documentID): \(error)")
                    return nil
                }
            }
            self.comments = comments
            return comments
        } catch {
            print("Error fetching comments: \(error)")
        }
        return []
    }
    
    func fetchUserClubs() async {
        do {
            guard let user = self.currentUser else {
                print("No user logged in")
                return
            }

            let snapshot = try await usersCollection().document(user.id ?? "")
                .collection("memberships")
                .getDocuments()

            let clubIds = snapshot.documents.compactMap { $0.data()["clubId"] as? String }

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

            self.userMovieClubs = clubs
        } catch {
            print("Error fetching user clubs: \(error)")
        }
    }


    
    func fetchMovieClub(clubId: String) async -> MovieClub? {
        guard
            let snapshot = try? await movieClubCollection().document(clubId).getDocument()
        else {
            print("Can't find movie club: \(clubId)")
            return nil
        }
        do {
            let movieClub = try snapshot.data(as: MovieClub.self)
            let moviesSnapshot = try await movieClubCollection()
                .document(clubId)
                .collection("movies")
                .order(by: "endDate" , descending: false)
                .limit(to: 1)
                .getDocuments()
            for document in moviesSnapshot.documents {
                print("current movie in method \(document.data())")
                movieClub.movies = [try document.data(as: Movie.self)]
            }
            return movieClub
        } catch {
            print("Error decoding movie: \(error)")
        }
        return nil
    }
    
    func addMovie(movie: Movie) {
        self.movies.append(movie)
        print("current movie in method \(movie)")
    }
    
    func createMovieClub(movieClub: MovieClub, movie: Movie?) async {
        
        
        //save for cloud function refactor
        /*
        if let movie {
            await addFirstMovie(club: movieClub, movie: movie)
        }
        // dont need to change anything here
        await addClubRelationship(club: movieClub)
        //make sure owner date is being set
        await addClubMember(clubId: id, user: self.currentUser!, date: timeIntervalFromToday)
        self.userMovieClubs.append(movieClub)*/
        
    }
    
    func fetchAPIMovie(title: String) async throws -> APIMovie {
        let formattedTitle = title.replacingOccurrences(of: " ", with: "+")
        let urlString = "https://omdbapi.com/?t=\(formattedTitle)&apikey=ab92d369"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Bad server response: \(response)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(APIMovie.self, from: data)
        } catch {
            print("Failed to decode API response: \(error)")
            throw URLError(.cannotParseResponse)
        }
    }

    func fetchUser() async throws {
        print("fetching user \(Auth.auth().currentUser?.uid ?? "")")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        guard let snapshot = try? await usersCollection().document(uid).getDocument() else {return}
        do{
            self.currentUser = try snapshot.data(as: User.self)
            print("current userId: \(self.currentUser?.id ?? "")")
            await fetchUserClubs()
        } catch {
            print("error decoding ")
        }
    }
    
    func updateProfilePicture(imageData: Data) async throws {
        let path = ("Users/profile_images/\(self.currentUser?.id ?? "")")
        let storageRef = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        do {
            try await storageRef.putDataAsync(imageData, metadata: metadata)
            let url = try await storageRef.downloadURL()
            try await usersCollection().document(currentUser?.id ?? "").updateData(["image" : url.absoluteString])
        }catch{
            throw error
        }
    }
    
    func updateUserDetails(changes: [String: Any]) async throws{
        do{
            print("in update")
           try await usersCollection().document(currentUser?.id ??
                                            "").updateData(changes)
            
            let commentsQuery = db.collectionGroup("comments").whereField("userId", isEqualTo: currentUser?.id ?? "")
            do {
                    let commentsSnapshot = try await commentsQuery.getDocuments()
                    let batch = db.batch()

                    for document in commentsSnapshot.documents {
                        // Update each comment document with the new username and profile image URL
                        batch.updateData([
                            "username": changes["name"],
                        ], forDocument: document.reference)
                    }
                    // Commit the batch write
                    try await batch.commit()
                    print("Successfully updated all relevant comments.")
                } catch {
                    print("Error updating comments: \(error)")
                }
            
            let moviesQuery = db.collectionGroup("movies").whereField("authorId", isEqualTo: currentUser?.id ?? "")
            do {
                let movieSnapshot = try await moviesQuery.getDocuments()
                let batch = db.batch()
                
                for document in movieSnapshot.documents {
                    batch.updateData([
                        "author": changes["name"] as Any,
                    ], forDocument: document.reference)
                }
                try await batch.commit()
                print("successfully updated all relevant movies")
            } catch {
                print(error)
            }
            
            let membersQuery = db.collectionGroup("members").whereField("userId", isEqualTo: currentUser?.id ?? "")
            do {
                let membersSnapshot = try await membersQuery.getDocuments()
                let batch = db.batch()
                
                for document in membersSnapshot.documents {
                    batch.updateData([
                        "userName": changes["name"] as Any,
                    ], forDocument: document.reference)
                }
                try await batch.commit()
                print("successfully updated all relevant members")
            } catch {
                print(error)
            }
            print("fetching user")
            try await fetchUser()
            
        }catch{
            throw error
        }
    }
    
    
    func signOut(){
        do{
            try Auth.auth().signOut() //sign out user on firebase
            self.userSession = nil //remove user session and go back to login
            self.currentUser = nil
            
        } catch {
            print(error.localizedDescription)
        }
        
    }
}
