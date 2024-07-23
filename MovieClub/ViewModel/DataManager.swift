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

@MainActor
@Observable class DataManager: Identifiable{
    
    var movies: [Movie] = []
    var userSession: FirebaseAuth.User?
    var currentUser: User?
    var userMovieClubs: [MovieClub] = []
    var comments: [Comment] = []
    var currentClub: MovieClub?
    var roster: [(Date)] = []
    var db: Firestore!
    
    init(){
        Task {
            self.userSession = Auth.auth().currentUser
            db = Firestore.firestore()
            //await fetchUser()
        }
    }
    
    
    func createUser(user: User) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: user.email, password: user.password)
            self.userSession = result.user
            let user = User(id: result.user.uid, email: user.email, bio: user.bio, name: user.name, image: user.image, password: user.password)
            let encodeUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id ?? "").setData(encodeUser)
            await fetchUser()
        } catch {
            print(error)
        }
        
    }
    
    func signIn(email: String, password: String) async throws {
        print("in sign in")
        do{
            
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func uploadProfileImage(image: UIImage, userId: String) async throws {
        let storageRef = Storage.storage().reference().child("profileImages/\(userId).jpg")
        if let imageData = image.jpegData(compressionQuality: 0.75) {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            do {
                _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
                let url = try await storageRef.downloadURL()
                // Update user's profile image URL
                if var currentUser = currentUser {
                    currentUser.image = url.absoluteString
                    try await Firestore.firestore().collection("users").document(userId).updateData(["image": url.absoluteString])
                    self.currentUser = currentUser
                }
            } catch {
                print("Error uploading image: \(error.localizedDescription)")
            }
        }
    }
    
    func uploadClubImage(image: UIImage, clubId: String) async -> String{
        let storageRef = Storage.storage().reference().child("Clubs/\(clubId)/banner.jpg")
        if let imageData = image.jpegData(compressionQuality: 0.25) {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            do {
                _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
                let url = try await storageRef.downloadURL()
                // Update clubss profile image URL
                return url.absoluteString
                
            } catch {
                print("Error uploading image: \(error.localizedDescription)")
            }
        }
        return ""
    }

    func getProfileImage(id: String, path: String) async -> String  {
        //   print("in getter")
        let storageRef = Storage.storage().reference().child("\(path).jpeg") //Storage.storage().reference().child("Users/profile_images/\(id).jpeg")
        do {
            let url = try await storageRef.downloadURL()
            if var currentUser {
                self.currentUser?.image = url.absoluteString
            }
            return url.absoluteString
        } catch {
            print(error)
        }
        return ""
    }
    
    func postComment(comment: Comment, movieClubID: String, movieID: String) async{
        do {
            let encodeComment = try Firestore.Encoder().encode(comment)
            try await db.collection("movieclubs").document(movieClubID)
                .collection("movies").document(movieID)
                .collection("comments").document().setData(encodeComment)
            
            print("Comment added successfully")
        } catch {
            print("Error adding comment: \(error.localizedDescription)")
        }
    }
    
    func fetchComments(movieClubId: String, movieId: String) async -> [Comment]{
        print("in fetch comments")
        do {
            let querySnapshot = try await db.collection("movieclubs")
                .document(movieClubId)
                .collection("movies")
                .document(movieId)
                .collection("comments")
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
            //  print("self.comments in method: \(self.comments)")
        } catch {
            print("Error fetching comments: \(error.localizedDescription)")
        }
        return []
    }
    
    func fetchMovieClubsForUser() async {
        // print("in fetchMovieClubsForUsers")
        self.userMovieClubs = []
        do{
            guard let user = self.currentUser else {
                print("User not found")
                return
            }
            
            let snapshot = try await db.collection("users").document(user.id ?? "").collection("memberships").getDocuments()
            
            let documents = snapshot.documents
            
            let clubIDs = documents.compactMap { document in
                print("document loop \(document.description)")
                return document.data()["clubID"] as? String ?? "error"
                
            }
            
            for clubID in clubIDs {
                print(clubID)
                await self.fetchMovieClub(clubID: clubID)
            }
        }catch{
            print(error.localizedDescription)
        }
        
    }
    
    func createMovieClub(movieClub: MovieClub){
        Task{
            let encodeClub = try Firestore.Encoder().encode(movieClub)
            if let id = movieClub.id{
                try await  Firestore.firestore().collection("movieclubs").document(id).setData(encodeClub)
                await addClubRelationship(movieClub: movieClub)
                self.userMovieClubs.append(movieClub)
            }
            await fetchUser()
        }
    }
    
    func addClubRelationship(movieClub: MovieClub) async {
        Task{
            let snapshot = try await db.collection("users").document(currentUser?.id ?? "").getDocument()
            if let id = movieClub.id, id != ""{
                // cant figure out a better way to do this but we know the val wont be null
                let membership = Membership(clubID: movieClub.id ?? "", selector: false, queue: [], rosterDate: nil)
                let encodeMembership = try Firestore.Encoder().encode(membership)
                try await db.collection("users").document(currentUser?.id ?? "").collection("memberships").document(id).setData(encodeMembership)
            } else {
                print("error occurred adding club for \(currentUser?.id ?? "")")
            }
            
        }
    }
    
    func fetchMovieClub(clubID: String) async {
       // print("in fetchMovieClub")
        guard let snapshot = try? await db.collection("movieclubs").document(clubID).getDocument() else {return}
        do {
            let movieClub = try snapshot.data(as: MovieClub.self)
            self.userMovieClubs.append(movieClub)
        } catch {
            print("Error decoding movie club: \(error)")
        }
        
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
    
    func fetchFirestoreMovies(clubId: String) async -> [FirestoreMovie]{
        do {
            let moviesRef = try await db.collection("movieclubs").document(clubId).collection("movies").getDocuments()
            print(moviesRef.documents)
            
            let firestoreMovies = moviesRef.documents.compactMap { document in
                try? document.data(as: FirestoreMovie.self)
            }
            //print("fireStoreMovies: \(firestoreMovies)")
            return firestoreMovies
        } catch {
            print("Error fetching Firestore movies: \(error)")
        }
        return []
    }
    
    func fetchAndMergeMovies(clubId: String) async -> [Movie] {
        var movies: [Movie] = []
        do {
            
            let firestoreMovies = await fetchFirestoreMovies(clubId: clubId)
            
            for firestoreMovie in firestoreMovies {
                
                let apiMovie = try await fetchAPIMovie(title: firestoreMovie.title)
                
                let combinedMovie = Movie(
                    id: firestoreMovie.id ?? UUID().uuidString,
                    title: firestoreMovie.title,
                    startDate: firestoreMovie.startDate,
                    poster: apiMovie.poster,
                    endDate: firestoreMovie.endDate,
                    author: firestoreMovie.author,
                    comments: firestoreMovie.comments, plot: apiMovie.plot, director: apiMovie.director
                    
                )
                //print(combinedMovie)
                movies.append(combinedMovie)
                
            }
            //self.currentClub?.movies = movies
            //print("##### \(currentClub?.movies)")
            return movies
            
            
            
        }catch {
            print("Failed to fetch or merge movie data: \(error)")
        }
        return []
    }
    
    func formatMovieForAPI(title: String) -> String {
            return title.replacingOccurrences(of: " ", with: "+")
        }
    func fetchMember() async {
        //TODO
    }
    
    func fetchUser() async {
        
      //  print("in fetch user")
        
      
      //  print("1")
        guard let uid = Auth.auth().currentUser?.uid else {return}
       // print("2")
     
        guard let snapshot = try? await db.collection("users").document(uid).getDocument() else {return}
            //print("Document data: \(snapshot.data())")
        
            do{
                self.currentUser = try snapshot.data(as: User.self)
            }catch{
                print(error)
            }
        
        let path = ("Users/profile_images/\(self.currentUser?.id ?? "")")
        await self.currentUser!.image = getProfileImage(id: currentUser!.id!, path: path)
        await fetchMovieClubsForUser()
        
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

extension MovieClub {
    static var TestData: [MovieClub] = [MovieClub(name: "Test Title 1",
                                                  created: Date(),
                                                  numMembers: 2,
                                                  description: "description",
                                                  ownerName: "Duhmarcus",
                                                  ownerID: "000123",
                                                  isPublic: true,
                                                  movies: [Movie(id: "001",
                                                                 title: "The Matrix",
                                                                 startDate: Date(),
                                                                 poster: "test",
                                                                 endDate: Date(),
                                                                 
                                                                 author: "duhmarcus")]),
                                        MovieClub(name: "Test Title 2",
                                                  created: Date(),
                                                  numMembers: 1,
                                                  description: "description",
                                                  ownerName: "darius garius",
                                                  ownerID: "1345",
                                                  isPublic: true)]
}

