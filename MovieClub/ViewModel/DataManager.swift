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

@MainActor
@Observable class DataManager: Identifiable{
    
    var movies: [Movie] = []
    var userSession: FirebaseAuth.User?
    var currentUser: User?
    var userMovieClubs: [MovieClub] = []
    var comments: [Comment] = []
    
    init(){
        Task {
            self.userSession = Auth.auth().currentUser
            //await fetchUser()
        }
    }
    
    
    func createUser(user: User) async throws {
        /* let db =  Firestore.firestore()
         let ref = db.collection("users").document(user.name)
         ref.setData(["id": UUID(), "name": user.name, "password": user.password]) { error in
         if let error = error {
         print(error.localizedDescription)
         }
         
         }*/
        do {
            let result = try await Auth.auth().createUser(withEmail: user.email, password: user.password)
            self.userSession = result.user
            let user = User(id: result.user.uid, email: user.email, name: user.name, image: user.image, password: user.password)
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
    
    func getProfileImage(id: String) async -> String  {
        print("in getter")
        let storageRef = Storage.storage().reference().child("Users/profile_images/\(id).jpeg")
        do {
            let url = try await storageRef.downloadURL()
            if var currentUser = currentUser {
                self.currentUser?.image = url.absoluteString
            }
            return url.absoluteString
        } catch {
            print(error)
        }
        return ""
        }
    
    func postComment(comment: Comment, movieClub: MovieClub) async{
        do{
            guard let movieClubId = movieClub.id else {
                   print("Invalid movie club ID")
                   return
               }
               
               guard let firstMovie = movieClub.movies?.first, let movieId = firstMovie.id else {
                   print("No movies found or invalid movie ID")
                   return
               }
               
               let db = Firestore.firestore()
               
               do {
                   let encodeComment = try Firestore.Encoder().encode(comment)
                   try await db.collection("movieclubs").document(movieClubId)
                       .collection("movies").document(movieId)
                       .collection("comments").document().setData(encodeComment)
                   self.comments.append(comment)
                   print("Comment added successfully")
               } catch {
                   print("Error adding comment: \(error.localizedDescription)")
               }
           }
    }
    
    func fetchComments(movieClubId: String, movieId: String) async {
        print("in fetch comments")
        let db = Firestore.firestore()
        
        do {
            let querySnapshot = try await db.collection("movieclubs")
                .document(movieClubId)
                .collection("movies")
                .document(movieId)
                .collection("comments")
                .getDocuments()
            print(querySnapshot.documents.first?.data())
            self.comments = querySnapshot.documents.compactMap { document in
                            do {
                                return try document.data(as: Comment.self)
                            } catch {
                                print("Error decoding document \(document.documentID): \(error)")
                                return nil
                            }
                        }
            print("self.comments in method: \(self.comments)")
        } catch {
            print("Error fetching comments: \(error.localizedDescription)")
        }
    }
    
    func fetchMovieClubsForUser() async {
        print("in fetchMovieClubsForUsers")
        self.userMovieClubs = []
        do{
            let db = Firestore.firestore()
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
            //let movieClub = MovieClub(name: movieClub.name, ownerName: movieClub.ownerName, ownerID: movieClub.ownerID, isPublic: movieClub.isPublic)
            let encodeClub = try Firestore.Encoder().encode(movieClub)
            try await Firestore.firestore().collection("movieclubs").document().setData(encodeClub)
            
            await fetchUser()
        }
    }
    
    func addClubRelationship(movieClub: MovieClub) async {
        Task{
            let db = Firestore.firestore()
            let snapshot = try await db.collection("users").document(currentUser?.id ?? "").getDocument()
            if movieClub.id != "" {
                // cant figure out a better way to do this but we know the val wont be null
                let membership = Membership(clubID: movieClub.id ?? "")
                let encodeMembership = try Firestore.Encoder().encode(membership)
                try await db.collection("users").document(currentUser?.id ?? "").collection("memberships").document(currentUser?.id ?? "").setData(encodeMembership)
            } else {
                print("error occurred adding club for \(currentUser?.id ?? "")")
            }
            
        }
    }
    
    
    func fetchMovieClub(clubID: String) async {
        print("in fetchMovieClub")
        
        let db = Firestore.firestore()
        guard let snapshot = try? await db.collection("movieclubs").document(clubID).getDocument() else {return}
        do {
            let movieClub = try snapshot.data(as: MovieClub.self)
            self.userMovieClubs.append(movieClub)
        } catch {
            print("Error decoding movie club: \(error)")
        }
        
    }
    
    func fetchMovies(for movieClubId: String) async -> [Movie]{
            print("Fetching movies for movie club ID: \(movieClubId)")
            
            let db = Firestore.firestore()
            
            do {
                let querySnapshot = try await db.collection("movieclubs").document(movieClubId).collection("movies").getDocuments()
                print(querySnapshot.documents)
                let movies = querySnapshot.documents.compactMap { try? $0.data(as: Movie.self) }
                return movies
                // Find the movie club by ID and update its movies
                if let index = userMovieClubs.firstIndex(where: { $0.id == movieClubId }) {
                    userMovieClubs[index].movies = movies
                        
                    
                }
            } catch {
                print("Error fetching movies: \(error.localizedDescription)")
            }
        return []
        }
    
    func fetchPoster(completion: @escaping (Result<Data, Error>) -> Void){
        let urlString = "http://img.omdbapi.com/?i=tt3896198&h=600&apikey=ab92d369"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 1, userInfo: nil)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 2, userInfo: nil)))
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
    }
    
    
    func fetchComments(for movie: inout Movie, in movieClubId: String) async {
            print("Fetching comments for movie: \(movie.title)")
            
            let db = Firestore.firestore()
            
            do {
                let querySnapshot = try await db.collection("movieclubs").document(movieClubId).collection("movies").document(movie.id ?? "").collection("comments").getDocuments()
                movie.comments = querySnapshot.documents.compactMap { try? $0.data(as: Comment.self) }
            } catch {
                print("Error fetching comments: \(error.localizedDescription)")
            }
        }
    
    
    
    
    func fetchUser() async {
        
        print("in fetch user")
        
        let db = Firestore.firestore()
        print("1")
        guard let uid = Auth.auth().currentUser?.uid else {return}
        print("2")
        print("uid\(uid)")
        guard let snapshot = try? await db.collection("users").document(uid).getDocument() else {return}
        print("Document data: \(snapshot.data())")
        self.currentUser = try? snapshot.data(as: User.self)
        await self.currentUser!.image = getProfileImage(id: currentUser!.id!)
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
                                                                 description: "description",
                                                                 startDate: Date(),
                                                                 endDate: Date(),
                                                                 avgRating: 5.0,
                                                                 author: "duhmarcus")]),
                                        MovieClub(name: "Test Title 2",
                                                  created: Date(),
                                                  numMembers: 1,
                                                  description: "description",
                                                  ownerName: "darius garius",
                                                  ownerID: "1345",
                                                  isPublic: true)]
}

